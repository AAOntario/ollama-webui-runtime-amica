#!/bin/bash
set -e

echo "Starting NGINX..."
nginx -g 'daemon off;' &

echo "Starting Open WebUI..."
cd /opt/open-webui/backend
python3 app.py &

echo "Starting Ollama Runner..."
MODEL_DIR="/workspace/models/blobs"
SELECTED_MODEL="${OLLAMA_MODEL_BLOB:+$MODEL_DIR/$OLLAMA_MODEL_BLOB}"

if [ -z "$SELECTED_MODEL" ] || [ ! -f "$SELECTED_MODEL" ]; then
    SELECTED_MODEL=$(find "$MODEL_DIR" -type f | head -n 1)
fi

if [ -z "$SELECTED_MODEL" ]; then
    echo "Error: No models found in $MODEL_DIR"
    exit 1
fi

echo "Using model: $SELECTED_MODEL"
/usr/local/bin/ollama runner --ollama-engine --model "$SELECTED_MODEL" --ctx-size 8192 --batch-size 512 --n-gpu-layers 49 --threads 112 --parallel 2 --port 11434 &

echo "All services launched. Container is alive."
tail -f /dev/null
