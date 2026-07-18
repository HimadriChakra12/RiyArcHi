#!/usr/bin/env bash
# wine-install-base.sh - Complete Wine base installation
# Version: 1.0
set -euo pipefail

echo "╔════════════════════════════════════════╗"
echo "║   Wine Base Installer v1.0             ║"
echo "╚════════════════════════════════════════╝"
echo

# ============================================================================
# Package Manager Detection
# ============================================================================
detect_pkg_manager() {
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

# ============================================================================
# GPU Detection
# ============================================================================
detect_gpu() {
  local gpu_info
  gpu_info=$(lspci 2>/dev/null | grep -E "VGA|3D" | head -n1)
  
  if echo "$gpu_info" | grep -qi nvidia; then
    echo "nvidia"
  elif echo "$gpu_info" | grep -qi amd; then
    echo "amd"
  elif echo "$gpu_info" | grep -qi intel; then
    echo "intel"
  else
    echo "unknown"
  fi
}

# ============================================================================
# Installation Functions
# ============================================================================
install_arch() {
  local gpu="$1"
  echo "📦 Installing for Arch Linux..."
  
  sudo pacman -Syu --needed --noconfirm \
    wine-staging \
    winetricks \
    lib32-gnutls \
    lib32-mesa \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    gamemode \
    lib32-gamemode
  
  case "$gpu" in
    amd)
      echo "🎮 Installing AMD GPU drivers..."
      sudo pacman -S --needed --noconfirm \
        vulkan-radeon lib32-vulkan-radeon \
        lib32-mesa-vdpau
      ;;
    nvidia)
      echo "🎮 Installing NVIDIA GPU drivers..."
      sudo pacman -S --needed --noconfirm \
        nvidia-utils lib32-nvidia-utils \
        vulkan-icd-loader lib32-vulkan-icd-loader
      ;;
    intel)
      echo "🎮 Installing Intel GPU drivers..."
      sudo pacman -S --needed --noconfirm \
        vulkan-intel lib32-vulkan-intel
      ;;
  esac
}

install_debian() {
  local gpu="$1"
  echo "📦 Installing for Debian/Ubuntu..."
  
  sudo dpkg --add-architecture i386 || true
  sudo apt update
  sudo apt install -y \
    wine64 wine32 winetricks \
    libvulkan1 libvulkan1:i386 \
    mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
    gamemode
  
  if [[ "$gpu" == "nvidia" ]]; then
    sudo apt install -y nvidia-vulkan-icd nvidia-vulkan-icd:i386 || true
  fi
}

install_fedora() {
  local gpu="$1"
  echo "📦 Installing for Fedora..."
  
  sudo dnf install -y \
    wine winetricks \
    vulkan-loader vulkan-loader.i686 \
    mesa-vulkan-drivers mesa-vulkan-drivers.i686 \
    gamemode
  
  if [[ "$gpu" == "nvidia" ]]; then
    sudo dnf install -y xorg-x11-drv-nvidia-libs.i686 || true
  fi
}

install_opensuse() {
  echo "📦 Installing for openSUSE..."
  
  sudo zypper install -y \
    wine winetricks \
    libvulkan1 libvulkan1-32bit \
    gamemode
}

# ============================================================================
# Main Installation
# ============================================================================
main() {
  local pkg_mgr gpu
  
  # Detect system
  pkg_mgr=$(detect_pkg_manager)
  gpu=$(detect_gpu)
  
  echo "Detected package manager: $pkg_mgr"
  echo "Detected GPU: $gpu"
  echo
  
  # Verify sudo
  if ! sudo -v; then
    echo "❌ Error: sudo access required"
    exit 1
  fi
  
  # Install based on package manager
  case "$pkg_mgr" in
    pacman)
      install_arch "$gpu"
      ;;
    apt)
      install_debian "$gpu"
      ;;
    dnf)
      install_fedora "$gpu"
      ;;
    zypper)
      install_opensuse "$gpu"
      ;;
    *)
      echo "❌ Error: Unsupported package manager"
      echo
      echo "Please install manually:"
      echo "  - Wine (wine-staging preferred)"
      echo "  - winetricks"
      echo "  - Vulkan drivers for your GPU"
      exit 1
      ;;
  esac
  
  # Verify installation
  echo
  echo "🔍 Verifying installation..."
  
  if ! command -v wine >/dev/null; then
    echo "❌ Error: Wine installation failed"
    exit 1
  fi
  
  if ! command -v winetricks >/dev/null; then
    echo "❌ Error: winetricks installation failed"
    exit 1
  fi
  
  echo "✅ Wine version: $(wine --version)"
  echo "✅ winetricks installed"
  
  if command -v vulkaninfo >/dev/null 2>&1; then
    local vk_ver
    vk_ver=$(vulkaninfo --summary 2>/dev/null | grep -i "instance version" | head -1 || echo "installed")
    echo "✅ Vulkan: $vk_ver"
  fi
  
  # Success
  echo
  echo "╔════════════════════════════════════════╗"
  echo "║  ✅ Wine Base Installation Complete    ║"
  echo "╚════════════════════════════════════════╝"
  echo
  echo "Next steps:"
  echo "  1. For gaming: ./wine-setup-gaming.sh"
  echo "  2. For Photoshop: ./wine-setup-photoshop.sh"
}

main "$@"
