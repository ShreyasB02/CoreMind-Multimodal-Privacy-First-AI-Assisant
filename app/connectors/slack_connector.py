# app/connectors/slack_connector.py

import os
import requests
from datetime import datetime, timedelta

SLACK_TOKEN = os.getenv("SLACK_BOT_TOKEN")

def fetch_recent_slack_messages(channel_id: str, hours: int = 24):
    """Fetches recent Slack messages from a channel in the last `hours`."""
    url = "https://slack.com/api/conversations.history"
    headers = {"Authorization": f"Bearer {SLACK_TOKEN}"}
    params = {
        "channel": channel_id,
        "oldest": (datetime.now() - timedelta(hours=hours)).timestamp()
    }

    response = requests.get(url, headers=headers, params=params)
    messages = response.json().get("messages", [])
    return [m["text"] for m in messages if "text" in m]
