#!/usr/bin/env bash
# wine-create-prefix.sh - Create a clean Wine prefix
# Version: 1.1 - Fixed for Intel UHD 620 / 1920x1080
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-$HOME/.wine-custom}"
PREFIX_NAME="${2:-$(basename "$WINEPREFIX")}"

# ============================================================================
# Usage
# ============================================================================
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: $0 [PREFIX_PATH] [NAME]
Create a clean Wine prefix with basic configuration.
Arguments:
  PREFIX_PATH    Path to Wine prefix (default: ~/.wine-custom)
  NAME           Friendly name (default: basename of path)
Examples:
  $0
  $0 ~/.wine-games "Gaming"
  $0 ~/.wine-photoshop "Photoshop CS6"
EOF
  exit 0
fi

echo "╔════════════════════════════════════════╗"
echo "║   Wine Prefix Creator v1.1             ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix: $WINEPREFIX"
echo "Name:   $PREFIX_NAME"
echo

# ============================================================================
# GPU Detection
# ============================================================================
detect_gpu() {
  local gpu_info
  gpu_info=$(lspci 2>/dev/null | grep -E "VGA|3D" | head -n1 || echo "")

  if   [[ "$gpu_info" =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]]; then echo "nvidia"
  elif [[ "$gpu_info" =~ [Aa][Mm][Dd]|[Rr][Aa][Dd][Ee][Oo][Nn] ]]; then echo "amd"
  elif [[ "$gpu_info" =~ [Ii][Nn][Tt][Ee][Ll] ]]; then echo "intel"
  else echo "unknown"
  fi
}

get_vulkan_icd() {
  local gpu="$1"
  # Intel UHD 620 uses the ANV (Anvil) Vulkan driver
  local candidates=()
  case "$gpu" in
    intel)
      candidates=(
        "/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
        "/usr/share/vulkan/icd.d/intel_icd.json"
      )
      ;;
    amd)
      candidates=(
        "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
        "/usr/share/vulkan/icd.d/radeon_icd.json"
      )
      ;;
    nvidia)
      candidates=(
        "/usr/share/vulkan/icd.d/nvidia_icd.json"
      )
      ;;
  esac
  for path in "${candidates[@]}"; do
    [[ -f "$path" ]] && echo "$path" && return
  done
  echo ""
}

# ============================================================================
# Check Existing Prefix
# ============================================================================
if [[ -d "$WINEPREFIX" ]]; then
  echo "⚠️  Prefix already exists: $WINEPREFIX"
  read -rp "Overwrite? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  rm -rf "$WINEPREFIX"
fi

# ============================================================================
# Create Prefix
# ============================================================================
echo "🍷 Creating Wine prefix..."
export WINEPREFIX
export WINEARCH=win64
# Disable Mono and Gecko prompts during init
export WINEDLLOVERRIDES="mscoree,mshtml="
wineboot --init >/dev/null 2>&1
echo "✅ Prefix initialized"

# ============================================================================
# Install Core Fonts
# ============================================================================
echo
echo "📝 Installing core fonts..."
winetricks -q corefonts >/dev/null 2>&1 || echo "⚠️  Font installation warning (non-critical)"
echo "✅ Fonts installed"

# ============================================================================
# Detect GPU & Create Config
# ============================================================================
GPU=$(detect_gpu)
VK_ICD=$(get_vulkan_icd "$GPU")

echo
echo "🎮 Detected GPU: $GPU"
[[ -n "$VK_ICD" ]] && echo "📦 Vulkan ICD: $VK_ICD"

# Save configuration
cat > "$WINEPREFIX/prefix-info.txt" <<EOF
Wine Prefix Configuration
=========================
Name:         $PREFIX_NAME
Path:         $WINEPREFIX
Architecture: win64
GPU:          $GPU
Vulkan ICD:   $VK_ICD
Created:      $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Wine Version: $(wine --version 2>/dev/null || echo "unknown")
EOF

# ============================================================================
# Base environment — Intel UHD 620 tweaks included here too
# ============================================================================
cat > "$WINEPREFIX/env.sh" <<EOF
#!/usr/bin/env bash
# Base Wine environment — source this before running Wine
export WINEPREFIX="$WINEPREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
export WINE_GPU="$GPU"

# Vulkan ICD
[[ -n "$VK_ICD" ]] && export VK_ICD_FILENAMES="$VK_ICD"

# ── Intel-specific fixes ───────────────────────────────────────────────────
if [[ "$GPU" == "intel" ]]; then
  # Expose full GL 4.6 / GLSL 460 so DXVK doesn't fall back to SW renderer
  export MESA_GL_VERSION_OVERRIDE=4.6
  export MESA_GLSL_VERSION_OVERRIDE=460

  # Use threaded Mesa GL (big CPU-side speed-up on integrated GPU)
  export mesa_glthread=true

  # Mailbox present mode avoids tearing without triple-buffering stalls
  export MESA_VK_WSI_PRESENT_MODE=mailbox

  # Suppress harmless fast-clear noise in logs
  export INTEL_DEBUG=nofc
fi
EOF
chmod +x "$WINEPREFIX/env.sh"

# ============================================================================
# Summary
# ============================================================================
echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Wine Prefix Created Successfully   ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix:      $WINEPREFIX"
echo "Config:      $WINEPREFIX/prefix-info.txt"
echo "Environment: $WINEPREFIX/env.sh"
echo
echo "Next steps:"
echo "  Configure for gaming:  ./gaming-setup.sh $WINEPREFIX"
echo
echo "Or use directly:"
echo "  source $WINEPREFIX/env.sh && wine program.exe"
