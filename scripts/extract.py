import pdfplumber

def extract_text(pdf_path):
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages):
            text = page.extract_text()
            images = page.images
            
            if images:
                text += "\n[IMAGE_HERE]\n"
            
            print(f"=== ページ {i+1} ===")
            print(text)

# PDFのパスを指定
extract_text("test.pdf")
