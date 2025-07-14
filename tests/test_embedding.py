from models.embedding_model import get_text_embedding

vec = get_text_embedding("A woman standing in front of a shop")
print(vec[:5])  # First 5 dimensions
