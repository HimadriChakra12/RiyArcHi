#!/usr/bin/env bash
# gaming-setup.sh - Complete gaming configuration
# Version: 2.1 - Fixed for Intel UHD 620 / 1920x1080 fullscreen
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
RESOLUTION="1920x1080"        # Default to your built-in display
VIRTUAL_DESKTOP=""
SKIP_DXVK=0
SKIP_ASYNC=0
SKIP_DOTNET=0
SKIP_VCREDIST=0
QUICK_MODE=0

# ============================================================================
# Progress Tracking
# ============================================================================
TOTAL_STEPS=0
CURRENT_STEP=0
show_progress() {
  local message="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "[$CURRENT_STEP/$TOTAL_STEPS] ($percent%) $message"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# Usage
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Complete gaming setup with all runtimes, DXVK, and performance optimizations.
Tuned for Intel UHD 620 @ 1920x1080 60 Hz by default.

Arguments:
  PREFIX                  Wine prefix path (required)

Options:
  --resolution WxH        Set default resolution (default: 1920x1080)
  --virtual WxH           Enable virtual desktop at given size
  --no-dxvk               Skip DXVK installation
  --no-async              Disable DXVK async shaders
  --no-dotnet             Skip .NET Framework installation
  --no-vcredist           Skip Visual C++ redistributables
  --quick                 Quick mode (minimal runtimes only)
  -h, --help              Show this help

Examples:
  $0 ~/.wine-games
  $0 ~/.wine-games --resolution 1920x1080
  $0 ~/.wine-games --virtual 1920x1080 --quick
  $0 ~/.wine-fps  --resolution 1280x720
EOF
  exit 0
}

# ── Argument parsing ────────────────────────────────────────────────────────
# Capture PREFIX then shift once before the while-loop so $# is correct
if [[ $# -lt 1 ]]; then show_usage; fi
shift   # remove PREFIX (already stored in $WINEPREFIX above)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resolution)         RESOLUTION="$2";       shift 2 ;;
    --virtual|--virtual-desktop) VIRTUAL_DESKTOP="$2"; shift 2 ;;
    --no-dxvk)            SKIP_DXVK=1;           shift   ;;
    --no-async)           SKIP_ASYNC=1;           shift   ;;
    --no-dotnet)          SKIP_DOTNET=1;          shift   ;;
    --no-vcredist)        SKIP_VCREDIST=1;        shift   ;;
    --quick)              QUICK_MODE=1;           shift   ;;
    -h|--help)            show_usage ;;
    *)                    echo "Unknown option: $1"; show_usage ;;
  esac
done

# Validate PREFIX
if [[ -z "$WINEPREFIX" ]]; then
  echo "❌ Error: PREFIX path required"
  show_usage
fi
if [[ ! -d "$WINEPREFIX" ]]; then
  echo "❌ Error: Prefix not found: $WINEPREFIX"
  echo "Create it first: ./wineprefix.sh $WINEPREFIX"
  exit 1
fi

# Validate resolution/virtual-desktop format
if [[ -n "$RESOLUTION" ]] && [[ ! "$RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
  echo "⚠️  Invalid --resolution format (expected WxH, e.g. 1920x1080). Using 1920x1080."
  RESOLUTION="1920x1080"
fi
if [[ -n "$VIRTUAL_DESKTOP" ]] && [[ ! "$VIRTUAL_DESKTOP" =~ ^[0-9]+x[0-9]+$ ]]; then
  echo "⚠️  Invalid --virtual format (expected WxH). Ignoring."
  VIRTUAL_DESKTOP=""
fi

# Calculate total steps
TOTAL_STEPS=10
[[ "$SKIP_DXVK"     -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 2))
[[ "$SKIP_DOTNET"   -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 5))
[[ "$SKIP_VCREDIST" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 7))

echo "╔════════════════════════════════════════╗"
echo "║   Wine Gaming Setup v2.1               ║"
echo "║   Intel UHD 620 Edition                ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix:     $WINEPREFIX"
echo "Resolution: ${VIRTUAL_DESKTOP:-${RESOLUTION:-1920x1080}}"
[[ -n "$VIRTUAL_DESKTOP" ]] && echo "Mode:       Virtual Desktop"
[[ "$QUICK_MODE" -eq 1 ]]   && echo "Mode:       Quick (minimal runtimes)"
echo "Total steps: $TOTAL_STEPS"
echo

export WINEPREFIX

# ============================================================================
# Helper Functions
# ============================================================================
install_package() {
  local package="$1"
  local description="$2"
  echo "📥 Installing $description..."
  if winetricks -q "$package" 2>&1 | grep -E "(Executing|Downloading|Installing|Extracting)" \
      | while read -r line; do echo "   → $line"; done; then
    echo "✅ $description installed successfully"
  else
    echo "⚠️  $description: completed (check winetricks.log if issues arise)"
  fi
}

install_package_quiet() {
  local package="$1"
  local description="$2"
  echo "📥 Installing $description..."
  winetricks -q "$package" >/dev/null 2>&1 && echo "✅ Done" || echo "⚠️  Warning during install"
}

# ============================================================================
# Core Fonts
# ============================================================================
show_progress "Installing core fonts & dependencies"
install_package_quiet "corefonts"  "Core Fonts"
install_package_quiet "tahoma"     "Tahoma Font"
install_package_quiet "liberation" "Liberation Fonts"

# ============================================================================
# Visual C++ Redistributables
# ============================================================================
if [[ "$SKIP_VCREDIST" -eq 0 ]]; then
  show_progress "Installing Visual C++ 2005"; install_package "vcrun2005" "Visual C++ 2005"
  show_progress "Installing Visual C++ 2008"; install_package "vcrun2008" "Visual C++ 2008"
  show_progress "Installing Visual C++ 2010"; install_package "vcrun2010" "Visual C++ 2010"
  show_progress "Installing Visual C++ 2012"; install_package "vcrun2012" "Visual C++ 2012"
  show_progress "Installing Visual C++ 2013"; install_package "vcrun2013" "Visual C++ 2013"
  show_progress "Installing Visual C++ 2015"; install_package "vcrun2015" "Visual C++ 2015"
  show_progress "Installing Visual C++ 2019"; install_package "vcrun2019" "Visual C++ 2019-2022"
else
  echo "⏭️  Skipping Visual C++ redistributables"
fi

# ============================================================================
# .NET Framework
# ============================================================================
if [[ "$SKIP_DOTNET" -eq 0 ]]; then
  if [[ "$QUICK_MODE" -eq 0 ]]; then
    show_progress "Installing .NET 3.5 SP1"; install_package "dotnet35sp1" ".NET 3.5 SP1"
    show_progress "Installing .NET 4.0";     install_package "dotnet40"    ".NET 4.0"
    show_progress "Installing .NET 4.5.2";   install_package "dotnet452"   ".NET 4.5.2"
  fi
  show_progress "Installing .NET 4.6.2"; install_package "dotnet462" ".NET 4.6.2"
  show_progress "Installing .NET 4.8";   install_package "dotnet48"  ".NET 4.8"
  echo "ℹ️  .NET Core / .NET 5+ requires native Linux runtime:"
  echo "   sudo apt install dotnet-runtime-6.0 dotnet-runtime-7.0"
else
  echo "⏭️  Skipping .NET Framework"
fi

# ============================================================================
# DirectX Components
# ============================================================================
show_progress "Installing DirectX components"
install_package       "d3dx9"         "DirectX 9 (d3dx9)"
install_package_quiet "d3dx9_43"      "DirectX 9 Update"
install_package_quiet "d3dx10"        "DirectX 10"
install_package_quiet "d3dx11_43"     "DirectX 11"
install_package_quiet "d3dcompiler_43" "D3D Compiler 43"
install_package_quiet "d3dcompiler_47" "D3D Compiler 47"

# ============================================================================
# Additional Gaming Libraries
# ============================================================================
show_progress "Installing additional gaming libraries"
install_package_quiet "xact"    "XACT (Xbox Audio)"
install_package_quiet "xinput"  "XInput (controller support)"
install_package_quiet "physx"   "PhysX"
install_package_quiet "vcrun6"  "Visual C++ 6.0 (legacy)"

# ============================================================================
# DXVK & VKD3D
# ============================================================================
if [[ "$SKIP_DXVK" -eq 0 ]]; then
  show_progress "Installing DXVK (DX9/10/11 → Vulkan)"
  install_package "dxvk"  "DXVK"

  show_progress "Installing VKD3D-Proton (DX12 → Vulkan)"
  install_package "vkd3d" "VKD3D-Proton"
else
  echo "⏭️  Skipping DXVK / VKD3D"
fi

# ============================================================================
# Registry Tweaks  ← KEY FIXES FOR INTEL UHD 620 FULLSCREEN
# ============================================================================
show_progress "Applying registry tweaks (Intel UHD 620 + 1920x1080)"

# ── Build the .reg file ──────────────────────────────────────────────────────
REG_FILE="$(mktemp /tmp/wine-gaming-XXXX.reg)"
cat > "$REG_FILE" <<'REG'
Windows Registry Editor Version 5.00

; ── Direct3D ────────────────────────────────────────────────────────────────
[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"csmt"="enabled"
"DirectDrawRenderer"="opengl"
; Advertise OpenGL 4.6 (matches MESA_GL_VERSION_OVERRIDE in env)
"MaxVersionGL"=dword:00040006
"UseGLSL"="enabled"
; Lie slightly higher than real VRAM so games don't fall back to lowest preset
"VideoMemorySize"="2048"
"OffscreenRenderingMode"="fbo"
; Strict draw ordering hurts integrated GPU badly — keep disabled
"StrictDrawOrdering"="disabled"
"Multisampling"="enabled"
"SampleCount"=dword:00000004

; ── DirectInput ─────────────────────────────────────────────────────────────
[HKEY_CURRENT_USER\Software\Wine\DirectInput]
"MouseWarpOverride"="force"

; ── X11 Driver ──────────────────────────────────────────────────────────────
[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"UseTakeFocus"="N"
; GrabFullscreen=Y is the key fix: forces Wine to take over the full display
; so the game actually fills 1920×1080 without a desktop border
"GrabFullscreen"="Y"
"ScreenDepth"="32"
REG

# ── Resolution / virtual-desktop block ──────────────────────────────────────
#
# FIX: The original script wrote an "Explorer\Desktops" key even when
#      --virtual was NOT set, and it used the wrong key name ("Default")
#      so Wine Explorer kept wrapping every game in a tiny window.
#      Now we only write virtual-desktop keys when explicitly requested.
#
if [[ -n "$VIRTUAL_DESKTOP" ]]; then
  cat >> "$REG_FILE" <<REG

; Virtual desktop mode (requested via --virtual)
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="shell"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"shell"="$VIRTUAL_DESKTOP"
REG
else
  # TRUE FULLSCREEN: remove any lingering virtual-desktop registry entry
  # so Wine lets the game own the display at native resolution.
  cat >> "$REG_FILE" <<'REG'

; Remove virtual desktop — let games run in real fullscreen
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
REG
fi

wine regedit "$REG_FILE" 2>/dev/null
rm -f "$REG_FILE"
echo "✅ Registry configured"

# ============================================================================
# GPU Detection
# ============================================================================
detect_gpu() {
  if [[ -f "$WINEPREFIX/prefix-info.txt" ]]; then
    grep "^GPU:" "$WINEPREFIX/prefix-info.txt" | cut -d: -f2 | tr -d ' '
  elif command -v lspci >/dev/null 2>&1; then
    if   lspci | grep -qi "vga.*nvidia";           then echo "nvidia"
    elif lspci | grep -qi "vga.*amd\|vga.*radeon"; then echo "amd"
    elif lspci | grep -qi "vga.*intel";            then echo "intel"
    else echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

GPU=$(detect_gpu)
echo "🎮 Detected GPU: $GPU"

# ============================================================================
# Gaming Environment Script
# ============================================================================
show_progress "Creating gaming environment"

cat > "$WINEPREFIX/gaming-env.sh" <<EOF
#!/usr/bin/env bash
# Gaming-optimised Wine environment
# Generated by gaming-setup.sh v2.1

# Load base environment (sets WINEPREFIX, WINEARCH, basic Intel vars)
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# ── Wine sync & staging ───────────────────────────────────────────────────
export WINEESYNC=1
export WINEFSYNC=1
export STAGING_SHARED_MEMORY=1
export STAGING_WRITECOPY=1

# ── DXVK ─────────────────────────────────────────────────────────────────
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="\$WINEPREFIX/dxvk_cache"
export DXVK_LOG_LEVEL=none
export DXVK_LOG_PATH=none
export DXVK_CONFIG_FILE="\$WINEPREFIX/dxvk.conf"
# Tell DXVK to use the Intel GPU (avoids it picking a software fallback)
export DXVK_FILTER_DEVICE_NAME="Intel"
EOF

if [[ "$SKIP_ASYNC" -eq 0 ]]; then
  echo 'export DXVK_ASYNC=1' >> "$WINEPREFIX/gaming-env.sh"
fi

cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'

# ── VKD3D-Proton ─────────────────────────────────────────────────────────
export VKD3D_CONFIG=dxr
export VKD3D_SHADER_CACHE_PATH="$WINEPREFIX/vkd3d_cache"
export VKD3D_FEATURE_LEVEL=12_1

# ── Vulkan ────────────────────────────────────────────────────────────────
# Intel ANV (Anvil) ICD — all three paths tried for distro compatibility
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/intel_icd.json

# ── Intel UHD 620 specific ────────────────────────────────────────────────
# Expose full Mesa GL 4.6 so DXVK doesn't think the GPU is too old
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460

# Threaded GL — significant CPU-side win on integrated graphics
export mesa_glthread=true

# Mailbox present avoids tearing without the frame-drop of FIFO
export MESA_VK_WSI_PRESENT_MODE=mailbox

# Suppress harmless fast-clear logs
export INTEL_DEBUG=nofc

# ── Audio ─────────────────────────────────────────────────────────────────
export PULSE_LATENCY_MSEC=60
export WINE_AUDIO_FREQ=48000

# ── Memory / CPU ─────────────────────────────────────────────────────────
export MALLOC_PERTURB_=0

# ── Steam compatibility stubs ─────────────────────────────────────────────
export SteamGameId=0
export SteamAppId=0

echo "🎮 Gaming environment loaded: $WINEPREFIX"
EOF
chmod +x "$WINEPREFIX/gaming-env.sh"
echo "✅ gaming-env.sh created"

# ── DXVK config tuned for integrated GPU ─────────────────────────────────────
cat > "$WINEPREFIX/dxvk.conf" <<'EOF'
# DXVK Configuration — Intel UHD 620 tuned
# Docs: https://github.com/doitsujin/dxvk

# Minimise frame latency (helps integrated GPU keep up)
d3d9.maxFrameLatency  = 1
d3d9.numBackBuffers   = 2
dxgi.maxFrameLatency  = 1
dxgi.numBackBuffers   = 2
dxgi.syncInterval     = 0

# Async shader compilation — CRITICAL for Intel: avoids stutter on first draw
dxvk.enableAsync      = true
dxvk.gplAsyncCache    = true
EOF

# ============================================================================
# Game Launcher  (run-game)
# ============================================================================
cat > "$WINEPREFIX/run-game" <<'LAUNCHER'
#!/usr/bin/env bash
# run-game — launch a Windows game via Wine with all optimisations
# Version: 2.2 — Intel UHD 620 / 1920x1080 fullscreen fix
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

# ── Defaults ─────────────────────────────────────────────────────────────────
RESOLUTION=""
VIRTUAL_DESKTOP=""
FULLSCREEN=0
FPS_LIMIT=""
VSYNC=0
WINVER=""

# ── Helpers ──────────────────────────────────────────────────────────────────
set_windows_version() {
  local version="$1"
  local tmp
  tmp="$(mktemp /tmp/winver-XXXX.reg)"
  cat > "$tmp" <<REG
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\\Software\\Wine]
"Version"="$version"
REG
  wine regedit "$tmp" >/dev/null 2>&1
  rm -f "$tmp"
  echo "🪟 Windows version: $version"
}

apply_fullscreen_registry() {
  # Remove virtual-desktop key so Wine doesn't box the game
  local tmp
  tmp="$(mktemp /tmp/fullscreen-XXXX.reg)"
  cat > "$tmp" <<'REG'
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
REG
  wine regedit "$tmp" >/dev/null 2>&1
  rm -f "$tmp"
}

apply_virtual_desktop() {
  local res="$1"
  local tmp
  tmp="$(mktemp /tmp/vdesk-XXXX.reg)"
  cat > "$tmp" <<REG
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\\Software\\Wine\\Explorer]
"Desktop"="shell"
[HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]
"shell"="$res"
REG
  wine regedit "$tmp" >/dev/null 2>&1
  rm -f "$tmp"
}

show_help() {
  cat <<HELP
run-game v2.2 — Wine game launcher
Usage:
  $0 [OPTIONS] <game.exe> [game args...]

Resolution:
  -r, --resolution WxH   Set game resolution
  -v, --virtual WxH      Run in virtual desktop window
  -f, --fullscreen        Force fullscreen (default behaviour)

Performance:
  --fps-limit N           Cap frame rate
  --vsync                 Enable VSync
  --no-async              Disable DXVK async shaders
  --dxvk-hud <preset>     Show DXVK HUD (e.g. fps,memory)
  --debug                 Enable verbose logging

Windows Version:
  --winxp  --winvista  --win7  --win10  --win11

Examples:
  $0 Punisher.exe
  $0 --win10 --fps-limit 60 game.exe
  $0 --virtual 1920x1080 game.exe
HELP
  exit 0
}

# ── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--resolution)          RESOLUTION="$2";          shift 2 ;;
    -v|--virtual|--virtual-desktop) VIRTUAL_DESKTOP="$2"; shift 2 ;;
    -f|--fullscreen)          FULLSCREEN=1;              shift   ;;
    --fps-limit)              FPS_LIMIT="$2";            shift 2 ;;
    --vsync)                  VSYNC=1;                   shift   ;;
    --no-async)               export DXVK_ASYNC=0;       shift   ;;
    --dxvk-hud)               export DXVK_HUD="$2";      shift 2 ;;
    --debug)
      export WINEDEBUG=+timestamp,+fps
      export DXVK_LOG_LEVEL=info
      shift ;;
    --winxp)    WINVER="winxp";    shift ;;
    --winvista) WINVER="winvista"; shift ;;
    --win7)     WINVER="win7";     shift ;;
    --win10)    WINVER="win10";    shift ;;
    --win11)    WINVER="win11";    shift ;;
    -h|--help)  show_help ;;
    *)          break ;;
  esac
done

if [[ -z "${1:-}" ]]; then
  echo "❌ No executable specified."
  show_help
fi

# ── Apply Settings ────────────────────────────────────────────────────────────
[[ -n "$WINVER" ]] && set_windows_version "$WINVER"

if [[ -n "$FPS_LIMIT" ]]; then
  export DXVK_FRAME_RATE="$FPS_LIMIT"
  echo "🎯 FPS limit: $FPS_LIMIT"
fi

[[ "$VSYNC" -eq 1 ]] && { export __GL_SYNC_TO_VBLANK=1; echo "🔄 VSync enabled"; }

# Resolution/fullscreen logic — fixed: default is TRUE fullscreen
if [[ -n "$VIRTUAL_DESKTOP" ]]; then
  apply_virtual_desktop "$VIRTUAL_DESKTOP"
  echo "🖥️  Virtual desktop: $VIRTUAL_DESKTOP"
elif [[ "$FULLSCREEN" -eq 1 ]] || [[ -z "$RESOLUTION" ]]; then
  # Default path: real fullscreen, let the game handle resolution itself
  apply_fullscreen_registry
  echo "🖼️  Fullscreen mode (1920x1080 native)"
fi

# ── Launch ────────────────────────────────────────────────────────────────────
# DXVK needs dxgi to use its own version, not Wine's
export WINEDLLOVERRIDES="dxgi=n,b;d3d9=n,b;d3d10core=n,b;d3d11=n,b"

echo "🚀 Launching: $*"
if command -v gamemoderun >/dev/null 2>&1; then
  echo "   (GameMode active)"
  if command -v mangohud >/dev/null 2>&1; then
    exec gamemoderun mangohud wine "$@"
  else
    exec gamemoderun wine "$@"
  fi
else
  exec wine "$@"
fi
LAUNCHER
chmod +x "$WINEPREFIX/run-game"
echo "✅ run-game launcher created"

# ============================================================================
# Resolution Manager
# ============================================================================
cat > "$WINEPREFIX/set-resolution" <<'RESMGR'
#!/usr/bin/env bash
# set-resolution — manage Wine display resolution
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

_write_reg() { wine regedit "$1" 2>/dev/null; rm -f "$1"; }

case "${1:-help}" in
  set)
    RES="${2:?Usage: $0 set WxH}"
    TMP="$(mktemp /tmp/res-XXXX.reg)"
    cat > "$TMP" <<REG
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="$RES"
REG
    _write_reg "$TMP"
    echo "✅ Virtual desktop set to $RES"
    ;;
  virtual)
    RES="${2:?Usage: $0 virtual WxH}"
    TMP="$(mktemp /tmp/res-XXXX.reg)"
    cat > "$TMP" <<REG
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="shell"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"shell"="$RES"
REG
    _write_reg "$TMP"
    echo "✅ Virtual desktop enabled at $RES"
    ;;
  fullscreen)
    TMP="$(mktemp /tmp/res-XXXX.reg)"
    cat > "$TMP" <<'REG'
Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
REG
    _write_reg "$TMP"
    echo "✅ Real fullscreen restored"
    ;;
  auto)
    if command -v xrandr >/dev/null 2>&1; then
      RES=$(xrandr | awk '/ connected/{p=1} p && /\*/{print $1; exit}')
      echo "🔍 Detected: $RES"
      "$0" set "$RES"
    else
      echo "❌ xrandr not found"; exit 1
    fi
    ;;
  current)
    echo "Settings for: $WINEPREFIX"
    wine reg query "HKCU\\Software\\Wine\\Explorer" 2>/dev/null || true
    wine reg query "HKCU\\Software\\Wine\\Explorer\\Desktops" 2>/dev/null || true
    ;;
  list)
    cat <<LIST
Common Resolutions:
  1920x1080  Full HD (your built-in display)
  1280x720   HD (better performance on integrated GPU)
  1600x900   HD+
  1366x768   HD+ (laptop native)
  2560x1440  2K (external display)
LIST
    ;;
  *)
    echo "Usage: $0 {set WxH | virtual WxH | fullscreen | auto | current | list}"
    ;;
esac
RESMGR
chmod +x "$WINEPREFIX/set-resolution"
echo "✅ set-resolution created"

# ============================================================================
# Diagnostics
# ============================================================================
cat > "$WINEPREFIX/diagnostics" <<'DIAG'
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export WINEPREFIX="$SCRIPT_DIR"

echo "╔════════════════════════════════════════╗"
echo "║   Wine Gaming Prefix Diagnostics       ║"
echo "╚════════════════════════════════════════╝"
echo "Prefix: $WINEPREFIX"
echo

echo "━━━ Wine ━━━"
wine --version 2>/dev/null || echo "wine not found"
winetricks --version 2>/dev/null | head -n1 || echo "winetricks not found"
echo

echo "━━━ GPU / Vulkan ━━━"
command -v lspci    >/dev/null && lspci | grep -iE "VGA|3D" || echo "lspci not found"
command -v vulkaninfo >/dev/null \
  && vulkaninfo --summary 2>/dev/null | head -n 20 \
  || echo "vulkaninfo not installed (sudo apt install vulkan-tools)"
echo

echo "━━━ Mesa / Intel ━━━"
command -v glxinfo >/dev/null \
  && glxinfo 2>/dev/null | grep -E "OpenGL renderer|OpenGL version|direct rendering" \
  || echo "glxinfo not installed (sudo apt install mesa-utils)"
echo

echo "━━━ DXVK DLLs ━━━"
SYS32="$WINEPREFIX/drive_c/windows/system32"
if [[ -d "$SYS32" ]]; then
  ls -lh "$SYS32"/d3d*.dll "$SYS32"/dxgi.dll 2>/dev/null || echo "None found"
else
  echo "Prefix not initialised"
fi
echo

echo "━━━ Registry: Explorer (virtual desktop) ━━━"
wine reg query "HKCU\\Software\\Wine\\Explorer" 2>/dev/null || echo "(not set — fullscreen mode)"
echo

echo "━━━ Cache Sizes ━━━"
du -sh "$WINEPREFIX"/*_cache 2>/dev/null || echo "(no caches yet)"
echo

echo "━━━ File Descriptor Limit ━━━"
ulimit -Hn
echo "(recommended: ≥ 524288)"
echo

echo "✅ Diagnostics complete"
DIAG
chmod +x "$WINEPREFIX/diagnostics"
echo "✅ diagnostics created"

# ============================================================================
# README
# ============================================================================
cat > "$WINEPREFIX/README.md" <<'README'
# Wine Gaming Prefix — Intel UHD 620 Edition

## Quick Start
```bash
# Fullscreen (default — uses your 1920×1080 display)
./run-game Punisher.exe

# With Windows version hint (fixes many old games)
./run-game --win7  Punisher.exe
./run-game --win10 Punisher.exe

# Cap FPS to prevent thermal throttling on integrated GPU
./run-game --fps-limit 60 game.exe

# Virtual desktop (game runs inside a window)
./run-game --virtual 1920x1080 game.exe
```

## Fullscreen Troubleshooting
If a game refuses to go fullscreen or shows a black border:
```bash
# Make sure virtual-desktop is off
./set-resolution fullscreen

# Then launch with GrabFullscreen forced (already set by default)
./run-game --win7 game.exe
```

## Installed Components
| Component | Version |
|-----------|---------|
| Visual C++ | 2005 – 2019/2022 |
| .NET Framework | 3.5 SP1 – 4.8 |
| DirectX | D3D9/10/11 |
| DXVK | DX9/10/11 → Vulkan |
| VKD3D-Proton | DX12 → Vulkan |
| XInput / XACT / PhysX | ✅ |

## Utilities
| Script | Purpose |
|--------|---------|
| `./run-game` | Launch game with all optimisations |
| `./set-resolution` | Switch between fullscreen / virtual desktop |
| `./diagnostics` | System & prefix health check |
| `./gaming-env.sh` | Environment vars (auto-loaded) |

## Performance Tips for Intel UHD 620
- First launch compiles shaders → expect one-time stutter
- Keep `--fps-limit 60` to avoid thermal throttle
- `dxvk.conf` is pre-tuned for integrated VRAM budget
- Install `gamemode`: `sudo apt install gamemode`
- Install `mangohud` for FPS overlay: `sudo apt install mangohud`

## Logs & Debugging
```bash
./run-game --debug game.exe    # verbose Wine + DXVK logs
./diagnostics                  # system health check
cat winetricks.log             # install history
wine dxdiag                    # DirectX diagnostics
```

## Clear Shader Cache (if graphical glitches appear)
```bash
rm -rf dxvk_cache/ vkd3d_cache/ gl_cache/
```
README
echo "✅ README.md created"

# ============================================================================
# System Checks
# ============================================================================
show_progress "Checking system configuration"
echo "🔍 System checks..."

FD_LIMIT=$(ulimit -Hn)
if [[ "$FD_LIMIT" -lt 524288 ]]; then
  echo "⚠️  File descriptor limit low: $FD_LIMIT (recommended: 524288)"
  echo "   Fix: echo '* hard nofile 524288' | sudo tee -a /etc/security/limits.conf"
else
  echo "✅ File descriptor limit: $FD_LIMIT"
fi

command -v vulkaninfo >/dev/null && echo "✅ vulkan-tools installed" \
  || echo "⚠️  vulkan-tools not found: sudo apt install vulkan-tools"

command -v gamemoderun >/dev/null && echo "✅ GameMode available" \
  || echo "💡 Tip: sudo apt install gamemode"

command -v mangohud >/dev/null && echo "✅ MangoHud available" \
  || echo "💡 Tip: sudo apt install mangohud"

command -v glxinfo >/dev/null \
  && glxinfo 2>/dev/null | grep -q "direct rendering: Yes" \
  && echo "✅ Direct rendering active" \
  || echo "⚠️  Direct rendering may be inactive (check glxinfo)"

# ============================================================================
# Final Summary
# ============================================================================
show_progress "Setup complete!"
echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Gaming Setup Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo
echo "📦 Installed:"
[[ "$SKIP_VCREDIST" -eq 0 ]] && echo "  ✅ Visual C++ 2005-2022"
[[ "$SKIP_DOTNET"   -eq 0 ]] && echo "  ✅ .NET Framework 3.5-4.8"
[[ "$SKIP_DXVK"     -eq 0 ]] && echo "  ✅ DXVK (DX9/10/11 → Vulkan)"
[[ "$SKIP_DXVK"     -eq 0 ]] && echo "  ✅ VKD3D-Proton (DX12 → Vulkan)"
echo "  ✅ DirectX, XInput, XACT, PhysX"
[[ "$SKIP_ASYNC"    -eq 0 ]] && echo "  ✅ DXVK async shaders"
echo
echo "🎮 Launch The Punisher:"
echo "  cd $WINEPREFIX"
echo "  ./run-game --win7 Punisher.exe"
echo "  ./run-game --win10 Punisher.exe   # if win7 doesn't work"
echo
echo "🔧 Utilities:"
echo "  ./set-resolution fullscreen       # ensure fullscreen is active"
echo "  ./set-resolution auto             # set to detected resolution"
echo "  ./diagnostics                     # health check"
echo "  cat README.md                     # full docs"
echo
echo "📊 GPU: Intel UHD 620 | Display: 1920x1080 @ 60 Hz"
echo "   DXVK async: $([[ "$SKIP_ASYNC" -eq 0 ]] && echo "Enabled" || echo "Disabled")"
