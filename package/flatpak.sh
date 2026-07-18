#!/bin/bash
sudo pacman -S --needed flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak=(
    "com.github.tchx84.Flatseal"
    "it.mijorus.gearlever"
    "com.github.wwmm.easyeffects"
)

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Flatpak Packages!${NC}"
echo -e "${GREEN}======================================${NC}"
flatpak install "${flatpak[@]}"
