#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"

# Gérer la clé secrète
if [ -z "$WEBUI_SECRET_KEY" ]; then
  KEY_FILE=".webui_secret_key"
  if ! [ -e "$KEY_FILE" ]; then
    echo "Generating WEBUI_SECRET_KEY"
    echo $(head -c 12 /dev/random | base64) > "$KEY_FILE"
  fi
  WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
fi

# Démarrer Ollama en background si nécessaire
if [[ "${USE_OLLAMA_DOCKER,,}" == "true" ]]; then
  echo "Starting Ollama..."
  ollama serve &
fi

# Démarrer le serveur Python / Uvicorn en foreground
PYTHON_CMD=$(command -v python3 || command -v python)
echo "Starting WebUI on $HOST:$PORT..."
WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn open_webui.main:app \
    --host "$HOST" --port "$PORT" \
    --forwarded-allow-ips '*' \
    --workers "${UVICORN_WORKERS:-1}"
