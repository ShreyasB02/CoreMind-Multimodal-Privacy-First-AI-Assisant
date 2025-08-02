ADVANCED_SIRI
---
> A privacy-first, multimodal memory assistant inspired by Apple Intelligence.
> Built to run locally, summarize your life, and reflect — just like the next-gen Siri.

![Advanced_Siri demo screenshot](demo/screenshot.png)
---

## ✨ Features

| Capability                       | Description                                                                                             |
| -------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 📸 **Image & Screenshot Memory** | Uploads screenshots or images and auto-generates visual captions using BLIP                             |
| 🎤 **Voice Memory**              | Transcribes user voice notes with Whisper and stores them as memories                                   |
| 🧠 **Multimodal Embedding**      | All memories are embedded using SBERT and indexed via FAISS                                             |
| 🔍 **Ask Your Memory**           | Natural language search over your stored experiences using LangGraph                                    |
| 📅 **Weekly Reflections**        | Automatically clusters and summarizes your memories using local LLMs (Ollama or Apple Foundation Model) |
| 🛡️ **Privacy-First**            | Entire pipeline runs locally (no cloud dependencies), with optional CoreML / Foundation Model support   |

---

## Architecture Overview

```
          📷 / 🎤 User Inputs
                ↓
       ┌────────────────────┐
       │  Caption / Transcribe (BLIP, Whisper) │
       └────────────────────┘
                ↓
       ┌────────────────────┐
       │ Embedding (BERT)  │
       └────────────────────┘
                ↓
     FAISS + SQLite Storage (Memory)
                ↓
     LangGraph Query + Reflection Agent
                ↓
       🔍 Ask | 📅 Summarize | 🧠 Reflect
```

---

## 📦 Tech Stack

* **Frontend**: Streamlit
* **Multimodal AI**: BLIP, Whisper (via Faster-Whisper), Sentence Transformers
* **Retrieval**: FAISS, SQLite
* **Reasoning**: LangGraph
* **Summarization**: Ollama (`mistral`, `llama3`) or Apple Foundation Model (Swift)
* **Tags & Reflection**: KMeans + LLM
* **Future Ready**: SwiftUI port planned with CoreML + Apple Foundation API

---

## 🚀 Demo

[https://user-images.githubusercontent.com/.../sirimemory-demo.mp4](https://user-images.githubusercontent.com/.../sirimemory-demo.mp4)
*(Upload an image or voice note → Ask Advanced_Siri → See weekly reflections)*

---

## 💻 Run Locally

### 1. Clone the repo

```bash
git clone https://github.com/shreyasbattula/sirimemory.git
cd sirimemory
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Pull Ollama model

```bash
ollama pull mistral  # or llama3
```

### 4. Run the app

```bash
bash run_app.sh
```

---

## 🔐 `.env` Example

```env
SQLITE_DB_PATH=data/memory_meta.sqlite
```

---

## 🔧 Folder Structure

```
Advanced_Siri
├── app/
│   ├── main.py              # Streamlit UI
│   ├── memory_manager.py    # Store/retrieve memory
│   ├── langgraph_flow.py    # LangGraph memory reasoning
│   ├── reflection.py        # Weekly reflection summarizer
├── models/
│   ├── vision_model.py      # BLIP caption generator
│   ├── embedding_model.py   # Sentence transformer
│   ├── whisper_model.py     # Faster Whisper wrapper
├── data/
│   ├── images/
│   ├── audio/
│   ├── memory_meta.sqlite
│   ├── memory_index.faiss
├── .env
├── requirements.txt
├── run_app.sh
├── README.md
```

---

## 🧩 Roadmap

* [x] Multimodal input (image + audio)
* [x] Local embedding & indexing
* [x] LangGraph query flow
* [x] Ollama-based summarization
* [x] Weekly memory reflection storage
* [ ] SwiftUI version using Apple Foundation Model API
* [ ] Convert BLIP & Whisper to CoreML
* [ ] Publish as Siri Shortcut or iOS widget

---

## 💡 Inspiration

Advanced_Siri is inspired by:

* Apple Intelligence (WWDC 2025)
* Humane AI Pin
* Personal memory agents from Rewind.ai & Mem.ai
* LangGraph and Self-Reflective RAG

---

## 👨‍💻 Author

**Shreyas Battula**
🎓 GenAI Intern @ Nokia | MS CS @ UC Riverside
🔗 [LinkedIn](https://www.linkedin.com/in/shreyas-battula--688360196) | 🧠 [GitHub](https://github.com/ShreyasB02) | ✉️ [shreyasb2002@gmail.com](mailto:shreyasb2002@gmail.com)

---

