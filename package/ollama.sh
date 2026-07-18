#!/bin/bash
set -e

# Install ollama
yay -S --noconfirm --needed ollama

# Enable + start service
sudo systemctl enable --now ollama

# Performance defaults (CPU laptop friendly)
# Adjust threads if needed (T480s usually 4 physical cores)
cat <<EOF | sudo tee /etc/profile.d/ollama.sh
export OLLAMA_NUM_THREADS=4
export OLLAMA_KEEP_ALIVE=15m
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_FLASH_ATTENTION=1
EOF

source /etc/profile.d/ollama.sh

MODELS=(
    "llama3.1:8b"
    "mistral"
    "phi3"
)

echo "📦 Pulling models..."
for model in "${MODELS[@]}"; do
    ollama pull "$model"
done

echo "✅ Ollama setup complete"
