import faiss
import numpy as np
import sqlite3
import os
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

SQL_DB= os.getenv("SQL_DB_PATH")
FAISS_DB=os.getenv("FAISS_DB_PATH")
embedding_dim=384 

def initialize_memory():
    if not os.exists('data'):
        os.makedirs('data')
    if not os.path.exists(SQL_DB):
        conn=sqlite3.connect(SQL_DB)
        c=conn.cursor()
        c.execute(
            """
            CREATE TABLE memories (
                id INTEGER PRIMARY KEY,
                caption TEXT,
                modality TEXT,
                timestamp TEXT,
                filepath TEXT
            )
        """
        )
        conn.commit()
        conn.close()
    
    if not os.path.exists(FAISS_DB):
        index=faiss.IndexFlatL2(embedding_dim)
        faiss.write_index(index,FAISS_DB)

def add_memory(caption,modality,filepath,embedding):
    timestamp=datetime.now().isoformat()
    conn=sqlite3.connect(SQL_DB)
    c=conn.cursor()
    c.execute('''
                INSERT INTO memories (caption, modality, timestamp, filepath)
        VALUES (?, ?, ?, ?)
    ''', (caption, modality, timestamp, filepath))
    conn.commit()
    conn.close()

    # Store in FAISS
    index = faiss.read_index(FAISS_DB)
    vec = np.array([embedding]).astype('float32')
    index.add(vec)
    faiss.write_index(index, FAISS_DB)


def search_memory(query_embedding, k=5):
    index=faiss.read_index(FAISS_DB)
    vector=np.array([query_embedding]).astype('float32')
    D,I=index.search(vector,k) #Distance, Index
    
    conn = sqlite3.connect(SQL_DB)
    c = conn.cursor()
    c.execute("SELECT * FROM memories")
    rows = c.fetchall()
    conn.close()

    results = []
    for idx in I[0]:
        if idx < len(rows):
            results.append(rows[idx])

    return results
