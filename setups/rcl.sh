#!/bin/bash
# ---- 1. Package caches ----
echo "[1/10] Cleaning Pacman cache..."
sudo paccache -r
sudo pacman -Scc --noconfirm

echo "[1b/10] Cleaning Nix garbage..."
sudo nix-collect-garbage -d

# ---- 2. Remove orphaned packages (Pacman) ----
echo "[2/10] Removing orphaned packages..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    sudo pacman -Rns --noconfirm $orphans
else
    echo "No orphaned packages found."
fi

# ---- 3. Clean systemd logs ----
echo "[3/10] Cleaning systemd journal logs..."
sudo journalctl --vacuum-size=500M

# ---- 4. Truncate /var/log logs ----
echo "[4/10] Truncating old log files in /var/log..."
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# ---- 5. Clean temporary directories ----
echo "[5/10] Cleaning /tmp and /var/tmp..."
sudo rm -rf /tmp/* /var/tmp/*

# ---- 6. Clean Docker ----
if command -v docker &> /dev/null; then
    echo "[6/10] Pruning unused Docker objects..."
    sudo docker system prune -a --volumes -f
else
    echo "Docker not installed, skipping Docker cleanup..."
fi

# ---- 7. Clean /var caches (non-Pacman) ----
echo "[7/10] Cleaning /var caches..."
sudo rm -rf /var/cache/*

# ---- 8. Clean /root large files (manual review) ----
echo "[8/10] Listing /root files >50MB..."
sudo find /root -type f -size +50M -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'

# ---- 9. Clean /opt large directories (manual review) ----
echo "[9/10] Listing /opt directories >100MB..."
sudo du -hxd1 /opt | sort -h | awk '$1 ~ /[0-9]M|G/ {print}'

# ---- 10. Clean /nix (Nix-specific) ----
echo "[10/10] Cleaning /nix store..."
sudo nix-collect-garbage -d

echo "=== Ultra-aggressive root cleanup completed ==="
echo "Tip: Check the large files listed in /root and /opt for optional removal."

