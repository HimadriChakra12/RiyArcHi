#!/usr/bin/env bash
set -e

echo "🖱️  Setting up libinput gestures (i3-friendly, dotfile-safe)"

# -----------------------------
# Detect distro
# -----------------------------
if command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
elif command -v apt >/dev/null 2>&1; then
    DISTRO="debian"
else
    echo "❌ Unsupported distro (need pacman or apt)"
    exit 1
fi

# -----------------------------
# Install packages
# -----------------------------
echo "📦 Installing required packages..."

if [ "$DISTRO" = "arch" ]; then
    sudo pacman -Sy --noconfirm libinput xdotool

    if ! pacman -Qi libinput-gestures >/dev/null 2>&1; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --noconfirm libinput-gestures
        elif command -v paru >/dev/null 2>&1; then
            paru -S --noconfirm libinput-gestures
        else
            echo "❌ libinput-gestures is in the AUR."
            echo "➡️  Install yay or paru, then re-run."
            exit 1
        fi
    fi
fi

# -----------------------------
# Add user to input group
# -----------------------------
echo "👤 Adding $USER to input group..."
sudo gpasswd -a "$USER" input

# -----------------------------
# Enable libinput-gestures autostart
# (systemd --user, no i3 config)
# -----------------------------
echo "⚙️  Enabling libinput-gestures user service..."
libinput-gestures-setup autostart || true

# -----------------------------
# System-wide touchpad tuning
# -----------------------------
echo "🎯 Writing system-wide libinput config..."

sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/40-libinput-touchpad.conf >/dev/null <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"

    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "DisableWhileTyping" "true"
    Option "ClickMethod" "clickfinger"
    Option "MiddleEmulation" "true"

    # Apple-like feel
    Option "AccelSpeed" "0.4"
EndSection
EOF

# -----------------------------
# Final message
# -----------------------------
echo
echo "✅ Setup complete."
echo
echo "⚠️ IMPORTANT:"
echo "• Log out and log back in (or reboot)"
echo "• Put your gestures in ~/.config/libinput-gestures.conf via dotfiles"
echo
echo "🧪 Debug later with:"
echo "  libinput-gestures -d"
echo
echo "🧠 You're now ready for Apple-tier touchpad vibes on i3."
