import sqlite3
import faiss
from dotenv import load_dotenv
from datetime import datetime
import numpy as np
from sklearn.cluster import KMeans
import os 
import ollama
from memory_manager import save_reflection

load_dotenv()

SQL_DB=os.getenv('SQL_DB_PATH')
FAISS_DB=os.getenv("FAISS_DB_PATH")

def load_memory_embeddings(n=100):

    index = faiss.read_index(FAISS_DB)
    vectors = index.reconstruct_n(0, min(n, index.ntotal))

    conn=sqlite3.connect(SQL_DB)
    c=conn.cursor()
    c.execute(
        "SELECT * from memories ORDER BY timestamp DESC LIMIT ?", (n,)              
    
    )

    rows=c.fetchall()
    conn.close()
    return vectors, rows

def cluster_memories(n_cluster=3):
    vectors,rows=load_memory_embeddings()
    if len(vectors)<n_cluster:
        return []

    km=KMeans(n_init=10,n_clusters=n_cluster)
    labels=km.fit_predict(vectors)

    clusters = {}
    for label, row in zip(labels, rows):
        if label not in clusters:
            clusters[label] = []
        clusters[label].append(row)  # memory record

    return clusters

def summarize_cluster(memories, model_name='llama3:8b'):
    captions=[m[1] for m in memories]
    joined = "\n".join(f"- {c}" for c in captions)

    prompt = f"""
            You are a super smart and helpful assistant. Summarize the following memory entries into a short paragraph capturing the main themes, in 2-3 sentences max. {joined}
            """

    response=ollama.chat(
        model=model_name,
        messages=[{'role':'user','content':prompt}]
    )
    return response['message']['content'].strip()

from app.memory_manager import save_reflection


def generate_and_store_reflections(n_clusters=3):
    clusters = cluster_memories(n_clusters)
    for label, group in clusters.items():
        summary = summarize_cluster(group)
        print(f"Cluster {label} Summary:\n{summary}\n")
        save_reflection(summary, tags="")
