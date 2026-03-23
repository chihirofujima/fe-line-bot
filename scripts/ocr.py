import re
import csv
import numpy as np
from paddleocr import PaddleOCR
from pdf2image import convert_from_path


def normalize_num(s):
    return s.translate(str.maketrans('０１２３４５６７８９', '0123456789'))


def merge_lines_by_y(ocr_result, y_threshold=10):
    if not ocr_result:
        return []

    # Y座標の中心値でソート
    boxes = []
    for item in ocr_result:
        coords, (text, conf) = item
        y_center = (coords[0][1] + coords[2][1]) / 2
        x_left   = coords[0][0]
        boxes.append((y_center, x_left, text))

    boxes.sort(key=lambda b: (b[0], b[1]))

    # Y座標が近いものを同じ行としてグループ化
    merged = []
    current_y, current_texts = boxes[0][0], [boxes[0][2]]

    for y, x, text in boxes[1:]:
        if abs(y - current_y) <= y_threshold:
            current_texts.append(text)
        else:
            merged.append("".join(current_texts))
            current_y, current_texts = y, [text]

    merged.append("".join(current_texts))
    return merged


def pdf_to_questions_csv(pdf_path: str, output_csv: str, skip_pages: int = 2):

    # ── 1. OCRでテキスト全文を取得 ──────────────────────────────────────
    ocr = PaddleOCR(lang='japan', device='cpu')
    pages = convert_from_path(pdf_path)
    lines = []

    for page_num, image in enumerate(pages):
        if page_num < skip_pages:
            continue
        result = ocr.ocr(np.array(image), cls=False)
        if not result or not result[0]:
            continue

        # Y座標で同じ行のテキストを結合
        merged = merge_lines_by_y(result[0], y_threshold=10)
        lines.extend(merged)
        lines.append("")  # ページ区切り

    full_text = "\n".join(lines)

    # ── 2. ア〜エの前に改行を補完 ────────────────────────────────────────
    full_text = re.sub(r'([^\n])([アイウエ]\s)', r'\1\n\2', full_text)

    # ── 3. 「問N」で分割 ─────────────────────────────────────────────────
    pattern = re.compile(r'問\s*[0-9０-９]+')
    matches = list(pattern.finditer(full_text))

    questions = []
    for i, m in enumerate(matches):
        num = int(re.sub(r'\D', '', normalize_num(m.group())))
        start = m.end()
        end   = matches[i + 1].start() if i + 1 < len(matches) else len(full_text)

        # 余分な空行を詰めるだけ、改行はそのまま保持
        content = full_text[start:end].strip()
        content = re.sub(r'\n{2,}', '\n', content)

        questions.append({'number': num, 'content': content})

    # ── 4. CSV出力（contentは改行をそのまま保持） ────────────────────────
    with open(output_csv, 'w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow(['number', 'content'])
        for q in questions:
            writer.writerow([q['number'], q['content']])

    print(f"{len(questions)} 問を {output_csv} に保存しました。")
    return questions


if __name__ == '__main__':
    questions = pdf_to_questions_csv(
        pdf_path   = '/home/fjmch/IPA_PDF/2019r01a_fe_am_qs.pdf',
        output_csv = 'output.csv',
        skip_pages = 2,
    )

    for q in questions[:3]:
        print(f"\n=== 問{q['number']} ===")
        print(q['content'])