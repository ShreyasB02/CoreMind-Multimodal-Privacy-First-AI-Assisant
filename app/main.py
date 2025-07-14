# For Streamlit
import streamlit as st
from PIL import Image
import os
from datetime import datetime
import uuid

from models.vision_model import get_caption
from models.embedding_model import get_text_embedding
from models.whisper_model import transcribe_audio
from app.memory_manager import add_memory, initialize_memory
from app.langgraph_flow import build_langgraph_memory_flow

# Initialize DB and index
initialize_memory()

st.set_page_config(page_title="SiriMemory++", layout="centered")
st.title("SiriMemory++")
st.caption("A Multimodal Memory Assistant — Step 1: Image Ingestion")

uploaded_file = st.file_uploader(
    "Upload a screenshot or photo", type=["jpg", "jpeg", "png"]
)

if uploaded_file:
    # Display the image
    image = Image.open(uploaded_file)
    st.image(image, caption="Uploaded Image", use_column_width=True)

    with st.spinner("Generating caption..."):
        caption = get_caption(image)
        st.success(f"Caption: {caption}")

        # Embed caption
        embedding = get_text_embedding(caption)

        # Save file
        save_path = f"data/images/{uuid.uuid4().hex}.png"
        image.save(save_path)

        # Store memory
        add_memory(
            caption=caption, modality="image", filepath=save_path, embedding=embedding
        )
        st.success("Memory stored successfully!")

st.divider()

st.subheader("Upload a Voice Note")

audio_file = st.file_uploader(
    "Upload an audio file (.mp3, .wav, .m4a)", type=["mp3", "wav", "m4a"]
)

if audio_file:
    audio_path = f"data/audio/{uuid.uuid4().hex}.mp3"
    with open(audio_path, "wb") as f:
        f.write(audio_file.read())

    with st.spinner("Transcribing..."):

        transcript = transcribe_audio(audio_path)
        st.success(f"Transcript: {transcript}")

        # Embed + Store
        embedding = get_text_embedding(transcript)
        add_memory(
            caption=transcript,
            modality="audio",
            filepath=audio_path,
            embedding=embedding,
        )
        st.success("Voice memory stored!")


st.divider()
st.subheader("Ask Your Memory")

query = st.text_input("e.g., 'What did I see related to Apple last week?'")

if query:
    with st.spinner("Running memory agent..."):
        graph = build_langgraph_memory_flow()
        result = graph.invoke({"query": query})
        results = result["formatted"]

        if not results:
            st.warning("No memories found.")
        else:
            for r in results:
                st.markdown(f"{r['timestamp']}** — *{r['caption']}")
                if r["modality"] == "image":
                    st.image(r["filepath"], width=400)
                st.markdown("---")
