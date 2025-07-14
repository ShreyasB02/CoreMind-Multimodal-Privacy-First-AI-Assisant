from app.reflection import cluster_memories, summarize_cluster

clusters = cluster_memories(n_clusters=3)
for label, group in clusters.items():
    summary = summarize_cluster(group)
    print(f"Topic {label} Summary:\n{summary}\n")
