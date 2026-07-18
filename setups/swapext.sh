#!/bin/bash
set -e

SWAPSIZE=16G
SWAPFILE=/home/swapfile

echo "== Checking /home mount =="
HOME_DEV=$(df /home | tail -1 | awk '{print $1}')
ROOT_DEV=$(df / | tail -1 | awk '{print $1}')

if [ "$HOME_DEV" = "$ROOT_DEV" ]; then
    echo "ERROR: /home is NOT a separate partition."
    echo "Swapfile here would still eat root space."
    echo "Aborting safely."
    exit 1
fi

echo "== Disabling all swap =="
sudo swapoff -a

echo "== Removing old root swapfile if present =="
if [ -f /swapfile ]; then
    sudo rm -f /swapfile
    sudo sed -i '\|/swapfile none swap|d' /etc/fstab
fi

echo "== Removing old home swapfile if present =="
if [ -f "$SWAPFILE" ]; then
    sudo rm -f "$SWAPFILE"
    sudo sed -i "\|$SWAPFILE none swap|d" /etc/fstab
fi

echo "== Creating $SWAPSIZE swapfile in /home =="
sudo fallocate -l $SWAPSIZE $SWAPFILE ||
    sudo dd if=/dev/zero of=$SWAPFILE bs=1G count=16 status=progress

sudo chmod 600 $SWAPFILE
sudo mkswap $SWAPFILE
sudo swapon $SWAPFILE

echo "== Backing up fstab =="
sudo cp /etc/fstab /etc/fstab.bak

echo "== Persisting swap in fstab =="
echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null

echo
echo "== Swap active =="
swapon --show
free -h

echo
echo "✔ Swap setup complete (root space restored)"
