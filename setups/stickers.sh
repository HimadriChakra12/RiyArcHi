#!/bin/bash
set -e

scripts=(
    "master:$HOME/stickers"
    "Him-Specific:$HOME/stickers-hspe"
)

echo "📦 Running Scripts..."

for entry in "${scripts[@]}"; do
    name="${entry%%:*}"
    path="${entry##*:}"

    echo "🔹 Installing and setting up $name at $path"

    if [[ -d "$path" ]]; then
        echo "⚠️ Directory already exists: $path, skipping clone"
        continue
    fi

    git clone --single-branch --branch "$name" \
        https://github.com/HimadriChakra12/stickers.git "$path" &&
        echo "✅ Cloned $name successfully"
done

echo "🎉 All scripts processed!"
