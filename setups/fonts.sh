#!/usr/bin/env bash

set -e

echo "▶ Installing fonts..."
sudo pacman -S --needed --noconfirm \
  ttf-jetbrains-mono \
  noto-fonts \
  noto-fonts-emoji

echo "▶ Setting up fontconfig..."
mkdir -p ~/.config/fontconfig/conf.d

cat > ~/.config/fontconfig/conf.d/99-fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

  <!-- Default UI -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans Bengali</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <!-- Serif -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Noto Serif Bengali</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <!-- Monospace -->
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Noto Sans Bengali</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

</fontconfig>
EOF

echo "▶ Rebuilding font cache..."
fc-cache -rv

echo
echo "✅ DONE."
echo "🔁 Log out and log back in (or restart i3)."
echo "🧪 Test with: বাংলা 😄 Hello"

