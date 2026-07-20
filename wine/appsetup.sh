#!/usr/bin/env bash
# app-setup.sh - Complete standard Windows application configuration
# Version: 1.0 - Companion to gaming-setup.sh, tuned for productivity apps
#                (office suites, PDF tools, utilities, installers) rather
#                than games. Prioritises stability + windowed behaviour
#                over fullscreen/GPU performance tuning.
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
RESOLUTION="1920x1080"        # Only relevant if the app itself is resizable
SKIP_DOTNET=0
SKIP_VCREDIST=0
SKIP_IE=0
SKIP_FONTS=0
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

Standard application setup — runtimes and stability tweaks for productivity
apps, installers, and utilities. No DXVK/VKD3D, no gamemode, no fullscreen
grabbing. Windowed behaviour is the default.

Arguments:
  PREFIX                  Wine prefix path (required)

Options:
  --no-dotnet              Skip .NET Framework installation
  --no-vcredist            Skip Visual C++ redistributables
  --no-ie                  Skip Internet Explorer / WebView components
  --no-fonts               Skip core font installation
  --quick                  Quick mode (minimal runtimes only)
  -h, --help               Show this help

Examples:
  $0 ~/.wine-apps
  $0 ~/.wine-office --quick
  $0 ~/.wine-utils --no-ie
EOF
  exit 0
}

# ── Argument parsing ────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then show_usage; fi
shift   # remove PREFIX (already stored in $WINEPREFIX above)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-dotnet)           SKIP_DOTNET=1;    shift ;;
    --no-vcredist)         SKIP_VCREDIST=1;  shift ;;
    --no-ie)               SKIP_IE=1;        shift ;;
    --no-fonts)            SKIP_FONTS=1;     shift ;;
    --quick)               QUICK_MODE=1;     shift ;;
    -h|--help)             show_usage ;;
    *)                     echo "Unknown option: $1"; show_usage ;;
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

# Calculate total steps
TOTAL_STEPS=6
[[ "$SKIP_VCREDIST" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 7))
[[ "$SKIP_DOTNET"   -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 5))
[[ "$SKIP_IE"       -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))

echo "╔════════════════════════════════════════╗"
echo "║   Wine App Setup v1.0                  ║"
echo "║   Standard Application Edition         ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix:      $WINEPREFIX"
[[ "$QUICK_MODE" -eq 1 ]] && echo "Mode:        Quick (minimal runtimes)"
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
if [[ "$SKIP_FONTS" -eq 0 ]]; then
  show_progress "Installing core fonts"
  install_package_quiet "corefonts"  "Core Fonts"
  install_package_quiet "tahoma"     "Tahoma Font"
  install_package_quiet "liberation" "Liberation Fonts"
  install_package_quiet "cjkfonts"   "CJK Fonts (for non-Latin UI text)"
else
  echo "⏭️  Skipping fonts"
fi

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
# Internet Explorer / WebView (many installers & help viewers need this)
# ============================================================================
if [[ "$SKIP_IE" -eq 0 ]]; then
  show_progress "Installing IE8 / WebView components"
  install_package_quiet "ie8"       "Internet Explorer 8"
  install_package_quiet "webview2"  "WebView2 Runtime"
else
  echo "⏭️  Skipping IE / WebView"
fi

# ============================================================================
# Common Productivity Libraries
# ============================================================================
show_progress "Installing common productivity libraries"
install_package_quiet "riched20"  "Rich Edit Control (RTF text boxes)"
install_package_quiet "riched30"  "Rich Edit Control 3.0"
install_package_quiet "gdiplus"   "GDI+ (image rendering in many apps)"
install_package_quiet "msxml6"    "MSXML 6 (XML parsing)"
install_package_quiet "mfc42"     "MFC42 (legacy app framework)"
install_package_quiet "vcrun6"    "Visual C++ 6.0 (legacy)"

# ============================================================================
# Registry Tweaks — STABILITY-FIRST, WINDOWED BY DEFAULT
# ============================================================================
show_progress "Applying registry tweaks (stability + windowed behaviour)"

REG_FILE="$(mktemp /tmp/wine-apps-XXXX.reg)"
cat > "$REG_FILE" <<'REG'
Windows Registry Editor Version 5.00

; ── Direct3D ────────────────────────────────────────────────────────────────
; Most standard apps don't touch D3D directly, but some installers and
; UI frameworks (e.g. WPF, some Electron-wrapped installers) do.
[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"csmt"="enabled"
"DirectDrawRenderer"="opengl"
"UseGLSL"="enabled"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="enabled"

; ── X11 Driver ──────────────────────────────────────────────────────────────
; Standard apps behave better as normal managed windows: keep decorations,
; keep focus-follows-mouse working normally, no fullscreen grabbing.
[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"Decorated"="Y"
"Managed"="Y"
"UseTakeFocus"="Y"
"GrabFullscreen"="N"

; ── Desktop Integration ───────────────────────────────────────────────────
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
REG

wine regedit "$REG_FILE" 2>/dev/null
rm -f "$REG_FILE"
echo "✅ Registry configured"

# ============================================================================
# App Environment Script
# ============================================================================
show_progress "Creating app environment"

cat > "$WINEPREFIX/app-env.sh" <<EOF
#!/usr/bin/env bash
# Standard-app-optimised Wine environment
# Generated by app-setup.sh v1.0

# Load base environment (sets WINEPREFIX, WINEARCH, basic vars)
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# ── Wine sync (still helps app snappiness, cheap to enable) ───────────────
export WINEESYNC=1
export WINEFSYNC=1

# ── Rendering — correctness over throughput ────────────────────────────────
unset DXVK_ASYNC DXVK_STATE_CACHE DXVK_FRAME_RATE
export MESA_GL_VERSION_OVERRIDE=""
export mesa_glthread=false

# ── Audio ─────────────────────────────────────────────────────────────────
export PULSE_LATENCY_MSEC=100

# ── Reduce noisy logging for everyday use ──────────────────────────────────
export WINEDEBUG=-all

echo "🖥️  App environment loaded: $WINEPREFIX"
EOF
chmod +x "$WINEPREFIX/app-env.sh"
echo "✅ app-env.sh created"

# ============================================================================
# App Launcher (run-app)
# ============================================================================
cat > "$WINEPREFIX/run-app" <<'LAUNCHER'
#!/usr/bin/env bash
# run-app — launch a Windows application via Wine
# Version: 1.0 — windowed, stability-first
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/app-env.sh"

WINVER=""
DEBUG=0

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

show_help() {
  cat <<HELP
run-app v1.0 — Wine application launcher
Usage:
  $0 [OPTIONS] <app.exe> [app args...]

Windows Version:
  --winxp  --winvista  --win7  --win10  --win11

Other:
  --debug                 Enable verbose logging
  -h, --help               Show this help

Examples:
  $0 Setup.exe
  $0 --win10 MyApp.exe
  $0 --debug Installer.exe
HELP
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --winxp)    WINVER="winxp";    shift ;;
    --winvista) WINVER="winvista"; shift ;;
    --win7)     WINVER="win7";     shift ;;
    --win10)    WINVER="win10";    shift ;;
    --win11)    WINVER="win11";    shift ;;
    --debug)    DEBUG=1;           shift ;;
    -h|--help)  show_help ;;
    *)          break ;;
  esac
done

if [[ -z "${1:-}" ]]; then
  echo "❌ No executable specified."
  show_help
fi

[[ -n "$WINVER" ]] && set_windows_version "$WINVER"

if [[ "$DEBUG" -eq 1 ]]; then
  export WINEDEBUG=+timestamp,+loaddll
fi

echo "🚀 Launching: $*"
exec wine "$@"
LAUNCHER
chmod +x "$WINEPREFIX/run-app"
echo "✅ run-app launcher created"

# ============================================================================
# Diagnostics
# ============================================================================
cat > "$WINEPREFIX/diagnostics" <<'DIAG'
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export WINEPREFIX="$SCRIPT_DIR"

echo "╔════════════════════════════════════════╗"
echo "║   Wine App Prefix Diagnostics          ║"
echo "╚════════════════════════════════════════╝"
echo "Prefix: $WINEPREFIX"
echo

echo "━━━ Wine ━━━"
wine --version 2>/dev/null || echo "wine not found"
winetricks --version 2>/dev/null | head -n1 || echo "winetricks not found"
echo

echo "━━━ Installed Runtime DLLs ━━━"
SYS32="$WINEPREFIX/drive_c/windows/system32"
if [[ -d "$SYS32" ]]; then
  ls -lh "$SYS32"/riched*.dll "$SYS32"/gdiplus.dll "$SYS32"/msxml6.dll 2>/dev/null || echo "None found"
else
  echo "Prefix not initialised"
fi
echo

echo "━━━ Registry: Explorer / X11 Driver ━━━"
wine reg query "HKCU\\Software\\Wine\\Explorer" 2>/dev/null || echo "(not set)"
wine reg query "HKCU\\Software\\Wine\\X11 Driver" 2>/dev/null || echo "(not set)"
echo

echo "✅ Diagnostics complete"
DIAG
chmod +x "$WINEPREFIX/diagnostics"
echo "✅ diagnostics created"

# ============================================================================
# README
# ============================================================================
cat > "$WINEPREFIX/README.md" <<'README'
# Wine App Prefix — Standard Application Edition

## Quick Start
```bash
# Run an installer or app (windowed, default Wine winver)
./run-app Setup.exe

# With a Windows version hint (fixes some installers/apps)
./run-app --win7  MyApp.exe
./run-app --win10 MyApp.exe

# Verbose logging for troubleshooting
./run-app --debug MyApp.exe
```

## Installed Components
| Component | Version |
|-----------|---------|
| Visual C++ | 2005 – 2019/2022 |
| .NET Framework | 3.5 SP1 – 4.8 |
| IE8 / WebView2 | optional (--no-ie to skip) |
| Rich Edit / GDI+ / MSXML6 / MFC42 | ✅ |

## Design Notes
This prefix is tuned for correctness and normal desktop behaviour rather
than throughput:
- Windows are decorated and managed like normal X11 windows (no fullscreen
  grabbing, unlike the gaming prefix).
- No DXVK/VKD3D — most productivity apps don't need a Vulkan translation
  layer, and skipping it avoids extra shader-cache overhead.
- `WINEDEBUG=-all` by default to keep logs quiet during everyday use.

## Utilities
| Script | Purpose |
|--------|---------|
| `./run-app` | Launch an app/installer |
| `./diagnostics` | System & prefix health check |
| `./app-env.sh` | Environment vars (auto-loaded) |

## Troubleshooting
```bash
./run-app --debug App.exe      # verbose Wine logs
./diagnostics                  # system health check
cat winetricks.log             # install history
```
README
echo "✅ README.md created"

# ============================================================================
# Final Summary
# ============================================================================
show_progress "Setup complete!"
echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ App Setup Complete!                ║"
echo "╚════════════════════════════════════════╝"
echo
echo "📦 Installed:"
[[ "$SKIP_FONTS"    -eq 0 ]] && echo "  ✅ Core fonts"
[[ "$SKIP_VCREDIST" -eq 0 ]] && echo "  ✅ Visual C++ 2005-2022"
[[ "$SKIP_DOTNET"   -eq 0 ]] && echo "  ✅ .NET Framework 3.5-4.8"
[[ "$SKIP_IE"       -eq 0 ]] && echo "  ✅ IE8 / WebView2"
echo "  ✅ Rich Edit, GDI+, MSXML6, MFC42"
echo
echo "🖥️  Run an app:"
echo "  cd $WINEPREFIX"
echo "  ./run-app --win10 Setup.exe"
echo
echo "🔧 Utilities:"
echo "  ./diagnostics                     # health check"
echo "  cat README.md                     # full docs"
