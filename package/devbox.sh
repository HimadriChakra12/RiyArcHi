#!/bin/bash
yay -S devbox --noconfirm
sudo chown -R $(whoami):$(whoami) /nix
mkdir -p $HOME/devbox-home/
cd $HOME/devbox-home/
devbox init
devbox add cava
