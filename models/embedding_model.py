from sentence_transformers import Sentence_Transformers

model = Sentence_Transformers("all-MiniLM-L6-v2")

def generate_embeddings(text_input:str):
    embeddings=model.decode(text_input,show_progress_bar=True)
    return embeddings


