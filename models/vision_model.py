from PIL import Image
import torch
from transformers import BlipProcessor,BlipForConditionalGeneration

#Process the Uploaded image on device
processor=BlipProcessor.from_pretrained('Salesforce/blip-image-captioning-base')
model=BlipForConditionalGeneration.from_pretrained('Salesforce/blip-image-captioning-base')

device=torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

def generate_caption(image:Image.Image)->str:
    inputs=processor(image,return_tensors="pt").to(device)
    out=model.generate(inputs)
    caption=processor.decode(out[0],skip_special_tokens=True)
    return caption