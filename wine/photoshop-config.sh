#!/usr/bin/env bash
# wine-setup-photoshop.sh - Photoshop CS6 Wine Setup (VERBOSE + AUTO aria2c)
# Version: 1.2

set -euo pipefail
set -x   # FULL VERBOSITY

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
ENABLE_DXVK=0
MEMORY_SIZE="2048"

# ============================================================================
# Usage
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Options:
  --with-dxvk        Enable DXVK (experimental)
  --memory SIZE      Video memory in MB (default: 2048)
  -h, --help         Show help

Example:
  $0 ~/.wine-photoshop --memory 4096
EOF
  exit 0
}

shift || show_usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-dxvk) ENABLE_DXVK=1; shift ;;
    --memory) MEMORY_SIZE="$2"; shift 2 ;;
    -h|--help) show_usage ;;
    *) echo "Unknown option: $1"; show_usage ;;
  esac
done

[[ -z "$WINEPREFIX" ]] && { echo "❌ PREFIX required"; exit 1; }
[[ ! -d "$WINEPREFIX" ]] && { echo "❌ Prefix not found: $WINEPREFIX"; exit 1; }

export WINEPREFIX

# ============================================================================
# Automatic aria2c installation
# ============================================================================
install_aria2() {
  echo "📦 Attempting to install aria2..."

  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y aria2
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y aria2
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm aria2
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y aria2
  else
    echo "❌ Unsupported package manager. Install aria2 manually."
    return 1
  fi
}

echo "🔍 Checking for aria2c..."
if ! command -v aria2c >/dev/null 2>&1; then
  echo "⚠️  aria2c not found"
  install_aria2 || echo "⚠️ aria2 installation failed"
fi

if command -v aria2c >/dev/null 2>&1; then
  echo "✅ aria2c enabled (16 connections)"
  export WINETRICKS_DOWNLOADER=aria2c
  export ARIA2C_OPTS="-x 16 -s 16 -k 1M \
    --file-allocation=trunc \
    --continue=true \
    --retry-wait=5 \
    --max-tries=0 \
    --summary-interval=5"
else
  echo "⚠️ Proceeding without aria2c (downloads may be slow)"
fi

export WINETRICKS_VERBOSE=1
export WINEDEBUG=err+all,warn+all

# ============================================================================
# Photoshop detection
# ============================================================================
PS_PATHS=(
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6 (64 Bit)/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/PhotoshopPortable/PhotoshopCS6Portable.exe"
)

FOUND_PS=""
for p in "${PS_PATHS[@]}"; do
  [[ -f "$p" ]] && FOUND_PS="$p" && break
done

# ============================================================================
# Winetricks installs (VERBOSE)
# ============================================================================
echo "📝 Installing core fonts..."
winetricks corefonts || true

echo "📦 Installing Visual C++ runtimes..."
winetricks vcrun2008 vcrun2010 vcrun2012 vcrun2013 || true

echo "📦 Installing graphics libraries..."
winetricks msxml3 msxml6 gdiplus atmlib || true

echo "📦 Installing DirectX..."
winetricks d3dx9 d3dcompiler_43 d3dcompiler_47 || true

if [[ "$ENABLE_DXVK" -eq 1 ]]; then
  echo "🎮 Installing DXVK..."
  winetricks dxvk || true
fi

# ============================================================================
# Registry Tweaks
# ============================================================================
cat > /tmp/wine-photoshop.reg <<REG
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"DirectDrawRenderer"="opengl"
"MaxVersionGL"=dword:00040006
"UseGLSL"="enabled"
"VideoMemorySize"="$MEMORY_SIZE"
"OffscreenRenderingMode"="fbo"
"Multisampling"="disabled"
"AlwaysOffscreen"="enabled"

[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
"winemenubuilder.exe"=""
REG

wine regedit /tmp/wine-photoshop.reg
rm -f /tmp/wine-photoshop.reg

# ============================================================================
# Environment
# ============================================================================
cat > "$WINEPREFIX/photoshop-env.sh" <<EOF
#!/usr/bin/env bash
export STAGING_SHARED_MEMORY=1
export WINE_HEAP_DELAY_FREE=1
export WINE_CPU_TOPOLOGY=4:0
EOF
chmod +x "$WINEPREFIX/photoshop-env.sh"

# ============================================================================
# Launcher
# ============================================================================
cat > "$WINEPREFIX/run-photoshop" <<'EOF'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/photoshop-env.sh"

PS_PATHS=(
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6 (64 Bit)/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/PhotoshopPortable/PhotoshopCS6Portable.exe"
)

[[ -f "$DIR/photoshop-path.txt" ]] && PS_PATHS=("$(cat "$DIR/photoshop-path.txt")" "${PS_PATHS[@]}")

for p in "${PS_PATHS[@]}"; do
  [[ -f "$p" ]] && exec wine "$p" "$@"
done

echo "❌ Photoshop not found"
exit 1
EOF

chmod +x "$WINEPREFIX/run-photoshop"

[[ -n "$FOUND_PS" ]] && echo "$FOUND_PS" > "$WINEPREFIX/photoshop-path.txt"

# ============================================================================
# Summary
# ============================================================================
echo
echo "════════════════════════════════════════"
echo "✅ Photoshop CS6 Wine setup COMPLETE"
echo "════════════════════════════════════════"
echo
echo "Launch Photoshop with:"
echo "  $WINEPREFIX/run-photoshop"
echo
echo "ℹ️ Safe to re-run this script at any time."
echo "ℹ️ aria2c will resume interrupted downloads."
