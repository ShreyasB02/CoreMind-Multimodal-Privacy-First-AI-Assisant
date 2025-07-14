advanced_siri
│
├── app/
│   ├── main.py               # Streamlit UI
│   ├── memory_manager.py     # Stores & retrieves multimodal events
│   ├── pipeline.py           # Ingestion → Caption/Transcript → Embedding
│   ├── langgraph_flow.py     # Query + episodic LangGraph logic
│   └── config.py             # Paths, constants, models, keys
│
├── models/
│   ├── whisper_model.py      # Whisper-tiny transcription
│   ├── vision_model.py       # BLIP captioning
│   └── embedding_model.py    # SentenceTransformer/Instructor-XL
│
├── data/
│   ├── memory_index.faiss    # Vector index
│   ├── memory_meta.sqlite    # Metadata
│   └── images/, audio/, text/  # Raw input storage
│
├── requirements.txt
├── README.md
└── run_app.sh
