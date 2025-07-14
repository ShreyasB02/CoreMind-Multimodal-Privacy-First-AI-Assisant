#!/bin/bash

# Navigate to the project root (if you're not already there)
cd "$(dirname "$0")"

# Run Streamlit app
streamlit run app/main.py
