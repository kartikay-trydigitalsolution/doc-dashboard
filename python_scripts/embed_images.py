import sys
import json
import openpyxl
from openpyxl.drawing.image import Image as XLImage
import requests
from io import BytesIO
from PIL import Image as PILImage

if len(sys.argv) != 3:
    print("Usage: embed_images.py <excel_path> <img_map_json_path>")
    sys.exit(1)

excel_path = sys.argv[1]
img_map_path = sys.argv[2]

with open(img_map_path, 'r') as f:
    sheet_img_map = json.load(f)

wb = openpyxl.load_workbook(excel_path)

for sheet_name, img_url in sheet_img_map.items():
    if not img_url:
        continue
    if sheet_name in wb.sheetnames:
        ws = wb[sheet_name]
        try:
            response = requests.get(img_url)
            response.raise_for_status()
            img_data = BytesIO(response.content)
            pil_img = PILImage.open(img_data)
            # Scale to 50%
            new_size = (int(pil_img.width * 0.5), int(pil_img.height * 0.5))
            pil_img = pil_img.resize(new_size, PILImage.LANCZOS)
            out_img_data = BytesIO()
            pil_img.save(out_img_data, format=pil_img.format or 'PNG')
            out_img_data.seek(0)
            img = XLImage(out_img_data)
            ws.add_image(img, "D2")
        except Exception as e:
            print(f"Failed to add image for {sheet_name}: {e}")

wb.save(excel_path) 