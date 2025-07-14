# For Streamlit
import streamlit as st
from PIL import Image
import os
from datetime import datetime
import uuid
import sqlite3
from dotenv import load_dotenv

from models.vision_model import get_caption
from models.embedding_model import get_text_embedding
from models.whisper_model import transcribe_audio
from app.memory_manager import add_memory, initialize_memory, SQLITE_DB_PATH
from app.langgraph_flow import build_langgraph_memory_flow

# Initialize
initialize_memory()
load_dotenv()

# Streamlit Page Setup
st.set_page_config(page_title="SiriMemory++", layout="wide")
st.sidebar.title("🧠 SiriMemory++")
section = st.sidebar.radio(
    "Navigate", ["📷 Upload Memory", "🔍 Ask Memory", "📅 Weekly Reflection"]
)

# ---------------------- Section: Upload ---------------------- #
if section == "📷 Upload Memory":
    st.header("📸 Upload a Visual or Voice Memory")
    st.markdown("Add screenshots or voice notes to your personal memory system.")

    # Image upload
    uploaded_file = st.file_uploader("🖼️ Upload Image", type=["jpg", "jpeg", "png"])
    if uploaded_file:
        image = Image.open(uploaded_file)
        st.image(image, caption="Uploaded Image", use_column_width=True)

        with st.spinner("🧠 Generating Caption..."):
            caption = get_caption(image)
            st.success(f"📝 Caption: {caption}")

            embedding = get_text_embedding(caption)
            save_path = f"data/images/{uuid.uuid4().hex}.png"
            image.save(save_path)

            add_memory(
                caption=caption,
                modality="image",
                filepath=save_path,
                embedding=embedding,
            )
            st.success("Visual memory stored successfully!")

    st.markdown("---")

    # Audio upload
    audio_file = st.file_uploader("🎤 Upload Voice Note", type=["mp3", "wav", "m4a"])
    if audio_file:
        audio_path = f"data/audio/{uuid.uuid4().hex}.mp3"
        with open(audio_path, "wb") as f:
            f.write(audio_file.read())

        with st.spinner("🧠 Transcribing..."):
            transcript = transcribe_audio(audio_path)
            st.success(f"📝 Transcript: {transcript}")

            embedding = get_text_embedding(transcript)
            add_memory(
                caption=transcript,
                modality="audio",
                filepath=audio_path,
                embedding=embedding,
            )
            st.success("✅ Voice memory stored successfully!")

# ---------------------- Section: Ask ---------------------- #
elif section == "🔍 Ask Memory":
    st.header("🔍 Ask Your Memory")
    st.markdown("Type natural language questions to recall memories.")

    query = st.text_input("e.g., What did I see related to Apple last week?")
    if query:
        with st.spinner("🔎 Searching your memory..."):
            graph = build_langgraph_memory_flow()
            result = graph.invoke({"query": query})
            results = result["formatted"]

            if not results:
                st.warning("😕 No memories found.")
            else:
                for r in results:
                    st.markdown(f"**📅 {r['timestamp']}** — *{r['caption']}*")
                    if r["modality"] == "image" and os.path.exists(r["filepath"]):
                        st.image(r["filepath"], width=400)
                    st.markdown("---")

# ---------------------- Section: Weekly Reflection ---------------------- #
elif section == "📅 Weekly Reflection":
    st.header("📅 Your Week at a Glance")
    st.markdown("Reflect on what you've seen, said, and explored.")

    db_path = os.getenv("SQLITE_DB_PATH") or SQLITE_DB_PATH
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT summary, timestamp FROM reflections ORDER BY timestamp DESC")
    rows = c.fetchall()
    conn.close()

    if not rows:
        st.info("🕰️ No reflections found yet. Try generating one through the pipeline.")
    else:
        for summary, ts in rows:
            date = ts.split("T")[0]
            st.markdown(f"### 📆 {date}")
            st.markdown(f"🧠 *{summary}*")
            st.markdown("---")
