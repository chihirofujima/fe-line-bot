import sys
import csv

sys.path.append('/home/fjmch/pdf-extractor-project')
from parse import extract_answers, extract_questions, merge_and_export

def export_to_csv(results, output_path):
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'number', 'content', 'correct_answer', 'image_url',
            'choice_1', 'choice_2', 'choice_3', 'choice_4','explanation_url'
        ])
        writer.writeheader()
        for r in results:
            writer.writerow({
                'number':         r['number'],
                'content':        r['content'],
                'correct_answer': r['correct_answer'],
                'image_url':      r['image_url'] or '',
                'choice_1':       'ア',
                'choice_2':       'イ',
                'choice_3':       'ウ',
                'choice_4':       'エ',
                'explanation_url': '' 
                # 手動入力 or 後日自動生成
                # TODO: explanation_urlは年度・問番号からURLを自動生成する
                # 過去問道場のURL形式: https://www.fe-siken.com/kakomon/{年度}_{季節}/q{number}.html
                # 例: https://www.fe-siken.com/kakomon/05_haru/q1.html
                # 実装時はextract_questions()の引数に年度・季節を追加して自動生成する
            })

# 実行
answers   = extract_answers('/home/fjmch/IPA_PDF/2023r05_fe_kamoku_a_ans.pdf')
questions = extract_questions('/home/fjmch/IPA_PDF/2023r05_fe_kamoku_a_qs.pdf')
results   = merge_and_export(questions, answers)

export_to_csv(results, '/home/fjmch/fe-line-bot/db/questions.csv')
print("questions.csv を生成しました！")

# 確認出力
# for r in results:
#     print(f"問{r['number']}:")
#     print(f"  content: {r['content']}") 
#     print(f"  correct_answer: {r['correct_answer']}")
#     print(f"  image_url: {r['image_url']}") 
#     print()