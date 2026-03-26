import pdfplumber
import re

def extract_answers(pdf_path):
    answers = {}
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                matches = re.findall(r'問(\d+)\s+([アイウエ])', text)
                for num, answer in matches:
                    answers[int(num)] = answer
    return answers

def extract_questions(pdf_path):
    questions = []
    with pdfplumber.open(pdf_path) as pdf:
        full_text = ""
        has_image_pages = set()

        for i, page in enumerate(pdf.pages):
            if i == 0:  # 1ページ目をスキップ（表紙のため不要）
                continue
            text = page.extract_text()
            if text:
                full_text += text + "\n"
            if page.images:
                has_image_pages.add(i)

    # 問題ブロックに分割
    blocks = re.split(r'(?=問\d+\s)', full_text)

    for block in blocks:
        block = block.strip() + '\n'

        if not re.match(r'問\d+', block):
            continue

        # 問題番号を取得
        num_match = re.match(r'問(\d+)\s+', block)
        if not num_match:
            continue
        num = int(num_match.group(1))

        # ① ページ番号を除去
        block = re.sub(r'－\s*\d+\s*－', '', block)

        # ② ふりがなを除去
        RUBY_WORDS = ['ぜい']
        pattern = '|'.join(RUBY_WORDS)
        block = re.sub(pattern, '', block)

        # ③ 選択肢ア〜エの行頭をマーキング
        block = re.sub(r'\n([アイウエ])\s', r'\n【\1】', block)
        # ④ 全改行を除去
        text = re.sub(r'\n', '', block)
        # ⑤ マーキングを改行付き選択肢に戻す
        text = re.sub(r'【([アイウエ])】', r'\n\1 ', text)
        # 横並び選択肢も改行（マーキング後に対応）
        text = re.sub(r'\s([イウエ])\s', r'\n\1 ', text)
        # ⑥ 「問X 」を除去
        content = re.sub(r'^問\d+\s+', '', text).strip()
        # ★テスト用（20問PDFの場合）
        # 2019年以前（80問）の場合はここを80にすること！
        if num == 20:
            content = re.sub(r'(\nエ [^〔©]+).*$', r'\1', content, flags=re.DOTALL).strip()
        # 図・表・画像の目印を追加
        if '図' in content or '表' in content or has_image_pages:
            content += '\n[IMAGE_HERE]'

        questions.append({
            'number': num,
            'content': content,
        })

    return questions

def merge_and_export(questions, answers):
    results = []
    for q in questions:
        num = q['number']
        content = q['content']
        has_image = '[IMAGE_HERE]' in content  # ① 先に判定
        content = content.replace('\n[IMAGE_HERE]', '')  # ② 除去

        results.append({
            'number':         num,
            'content':        content,
            'correct_answer': answers.get(num, '不明'),
            'image_url':      '[IMAGE_HERE]' if has_image else None
        })
    return results
# 実行
# answers   = extract_answers('answer.pdf')
# questions = extract_questions('2018h30a_fe_am_qs.pdf')
# results   = merge_and_export(questions, answers)

# 確認出力
# for r in results:
# print(f"問{r['number']}:")
# print(f"  content: {r['content']}") 
# print(f"  correct_answer: {r['correct_answer']}")
# print(f"  image_url: {r['image_url']}") 
# print()
