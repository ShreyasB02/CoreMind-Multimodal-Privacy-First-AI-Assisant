from PIL import Image
from models.vision_model import generate_caption

img_path = "resources/test_image"
img = Image.open(img_path)

print(generate_caption(img))


