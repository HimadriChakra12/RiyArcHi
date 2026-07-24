#!/usr/bin/env bash
# app-setup.sh - Complete standard Windows application configuration
# Version: 2.0 - Companion to gaming-setup.sh, tuned for productivity apps
#                (office suites, PDF tools, utilities, installers) rather
#                than games. Prioritises stability + windowed behaviour
#                over fullscreen/GPU performance tuning by default, with
#                an opt-in --heavy profile for demanding, CEF/Chromium-UI
#                or GPU-composited apps (Acrobat DC, Office, CAD viewers).
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
HEAVY_MODE=0                   # extra runtimes + GPU-accelerated rendering
ENABLE_DXVK=0                  # D3D9-11 -> Vulkan translation for CEF UIs

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
  echo "======================================="
  echo "[STEP $CURRENT_STEP/$TOTAL_STEPS] ($percent%) $message"
  echo "======================================="
}

# ============================================================================
# Usage
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Standard application setup - runtimes and stability tweaks for productivity
apps, installers, and utilities. Windowed behaviour is the default; pass
--heavy for apps that are heavy on rendering/compositing (Acrobat DC,
Office, CAD/EDA viewers, Electron/CEF-based installers).

Arguments:
  PREFIX                  Wine prefix path (required)

Options:
  --no-dotnet               Skip .NET Framework installation
  --no-vcredist              Skip Visual C++ redistributables
  --no-ie                    Skip Internet Explorer / WebView components
  --no-fonts                 Skip core font installation
  --quick                    Quick mode (minimal runtimes only)
  --heavy                    Heavy profile: extra runtimes + memory/thread
                              tuning for demanding, GPU-composited apps
  --dxvk                     Install DXVK (implies --heavy rendering tweaks
                              even without the full --heavy runtime set)
  -h, --help                 Show this help

Examples:
  $0 ~/.wine-apps
  $0 ~/.wine-office --quick
  $0 ~/.wine-acrobat --heavy --dxvk
EOF
  exit 0
}

# -- Argument parsing --------------------------------------------------------
if [[ $# -lt 1 ]]; then show_usage; fi
shift   # remove PREFIX (already stored in $WINEPREFIX above)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-dotnet)           SKIP_DOTNET=1;    shift ;;
    --no-vcredist)         SKIP_VCREDIST=1;  shift ;;
    --no-ie)               SKIP_IE=1;        shift ;;
    --no-fonts)            SKIP_FONTS=1;     shift ;;
    --quick)               QUICK_MODE=1;     shift ;;
    --heavy)                HEAVY_MODE=1;     ENABLE_DXVK=1; shift ;;
    --dxvk)                 ENABLE_DXVK=1;    shift ;;
    -h|--help)             show_usage ;;
    *)                     echo "[ERROR] Unknown option: $1"; show_usage ;;
  esac
done

# Validate PREFIX
if [[ -z "$WINEPREFIX" ]]; then
  echo "[ERROR] PREFIX path required"
  show_usage
fi
if [[ ! -d "$WINEPREFIX" ]]; then
  echo "[ERROR] Prefix not found: $WINEPREFIX"
  echo "Create it first: ./wineprefix.sh $WINEPREFIX"
  exit 1
fi

# Calculate total steps
TOTAL_STEPS=6
[[ "$SKIP_VCREDIST" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 7))
[[ "$SKIP_DOTNET"   -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 5))
[[ "$SKIP_IE"       -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
[[ "$HEAVY_MODE"    -eq 1 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
[[ "$ENABLE_DXVK"   -eq 1 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))

echo "+========================================+"
echo "|   Wine App Setup v2.0                   |"
echo "|   Standard Application Edition          |"
echo "+========================================+"
echo
echo "Prefix:      $WINEPREFIX"
[[ "$QUICK_MODE" -eq 1 ]] && echo "Mode:        Quick (minimal runtimes)"
[[ "$HEAVY_MODE" -eq 1 ]] && echo "Mode:        Heavy (demanding / GPU-composited apps)"
[[ "$ENABLE_DXVK" -eq 1 ]] && echo "Rendering:   DXVK (D3D -> Vulkan)"
echo "Total steps: $TOTAL_STEPS"
echo

export WINEPREFIX

# ============================================================================
# Helper Functions
# ============================================================================
install_package() {
  local package="$1"
  local description="$2"
  echo "[PKG] Installing $description..."
  if winetricks -q "$package" 2>&1 | grep -E "(Executing|Downloading|Installing|Extracting)" \
      | while read -r line; do echo "   -> $line"; done; then
    echo "[OK] $description installed successfully"
  else
    echo "[WARN] $description: completed (check winetricks.log if issues arise)"
  fi
}

install_package_quiet() {
  local package="$1"
  local description="$2"
  echo "[PKG] Installing $description..."
  winetricks -q "$package" >/dev/null 2>&1 && echo "[OK] Done" || echo "[WARN] Warning during install"
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
  echo "[SKIP] Skipping fonts"
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
  echo "[SKIP] Skipping Visual C++ redistributables"
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
  echo "[INFO] .NET Core / .NET 5+ requires native Linux runtime:"
  echo "       sudo apt install dotnet-runtime-6.0 dotnet-runtime-7.0"
else
  echo "[SKIP] Skipping .NET Framework"
fi

# ============================================================================
# Internet Explorer / WebView (many installers & help viewers need this)
# ============================================================================
if [[ "$SKIP_IE" -eq 0 ]]; then
  show_progress "Installing IE8 / WebView components"
  install_package_quiet "ie8"       "Internet Explorer 8"
  install_package_quiet "webview2"  "WebView2 Runtime"
else
  echo "[SKIP] Skipping IE / WebView"
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
# Heavy Runtime Set - CEF/Chromium-based UIs (Acrobat DC, Office, CAD tools)
# ============================================================================
# Modern "productivity" installers are frequently not classic Win32 apps -
# Acrobat DC's UI shell is Chromium/CEF-based and composites its interface
# through Direct3D/DirectComposition rather than plain GDI. Without a D3D
# implementation and enough shader/compiler support, Wine falls back to slow
# software paths, which is what reads as "spiced up and laggy".
if [[ "$HEAVY_MODE" -eq 1 ]]; then
  show_progress "Installing heavy-app runtime set (CEF/D3D-UI support)"
  install_package_quiet "vcrun2022"     "Visual C++ 2022"
  install_package_quiet "d3dcompiler_47" "D3D Shader Compiler 47"
  install_package_quiet "d3dx9"         "D3DX9"
  install_package_quiet "d3dx11_43"     "D3DX11"
  install_package_quiet "msls31"        "Microsoft Line Services 3.1 (text layout)"
  install_package_quiet "atmlib"        "Adobe Type Manager Library"
else
  echo "[SKIP] Skipping heavy-app runtime set (use --heavy to enable)"
fi

if [[ "$ENABLE_DXVK" -eq 1 ]]; then
  show_progress "Installing DXVK (D3D9/10/11 -> Vulkan translation)"
  install_package_quiet "dxvk" "DXVK"
else
  echo "[SKIP] Skipping DXVK (use --dxvk or --heavy to enable)"
fi

# ============================================================================
# Registry Tweaks - STABILITY-FIRST, WINDOWED BY DEFAULT
# ============================================================================
show_progress "Applying registry tweaks (stability + windowed behaviour)"

REG_FILE="$(mktemp /tmp/wine-apps-XXXX.reg)"
{
cat <<'REG'
Windows Registry Editor Version 5.00

; -- Direct3D ----------------------------------------------------------------
; Most classic Win32 apps don't touch D3D directly, but CEF/Chromium-shelled
; installers and UI frameworks (WPF, Electron-wrapped installers, modern
; Adobe apps) composite their UI through it.
[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"csmt"="enabled"
"DirectDrawRenderer"="opengl"
"UseGLSL"="enabled"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="enabled"

; -- X11 Driver ----------------------------------------------------------------
; Standard apps behave better as normal managed windows: keep decorations,
; keep focus-follows-mouse working normally, no fullscreen grabbing.
[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"Decorated"="Y"
"Managed"="Y"
"UseTakeFocus"="Y"
"GrabFullscreen"="N"

; -- Desktop Integration -------------------------------------------------------
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-

; -- DPI -----------------------------------------------------------------------
; Wine otherwise reports the host monitor's real (often scaled) DPI to the
; app. DPI-aware UIs (Acrobat DC's Chromium shell included) then scale their
; fonts/controls to match, but Wine doesn't scale the window to match, so
; everything renders oversized. Pin it to the Windows standard of 96 so app
; UIs render at their intended size regardless of host display scaling.
[HKEY_CURRENT_USER\Software\Wine\Fonts]
"LogPixels"=dword:00000060
REG

if [[ "$HEAVY_MODE" -eq 1 ]]; then
cat <<'REG'

; -- Heavy profile: large/complex working sets, more DLL memory headroom ----
[HKEY_CURRENT_USER\Software\Wine]
"MaxShaderModelVS"="3"
"MaxShaderModelPS"="3"

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"="disabled"
REG
fi
} > "$REG_FILE"

wine regedit "$REG_FILE" 2>/dev/null
rm -f "$REG_FILE"
echo "[OK] Registry configured"

# ============================================================================
# App Environment Script
# ============================================================================
show_progress "Creating app environment"

cat > "$WINEPREFIX/app-env.sh" <<EOF
#!/usr/bin/env bash
# Standard-app-optimised Wine environment
# Generated by app-setup.sh v2.0 (heavy=$HEAVY_MODE, dxvk=$ENABLE_DXVK)

# Load base environment (sets WINEPREFIX, WINEARCH, basic vars)
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# -- Wine sync (helps app snappiness, cheap to enable) -----------------------
export WINEESYNC=1
export WINEFSYNC=1

# -- Reduce noisy logging for everyday use ------------------------------------
export WINEDEBUG=-all
EOF

if [[ "$HEAVY_MODE" -eq 1 || "$ENABLE_DXVK" -eq 1 ]]; then
  cat >> "$WINEPREFIX/app-env.sh" <<EOF

# -- Heavy profile: GPU-composited / CEF-based UI rendering -------------------
# DO NOT set MESA_GL_VERSION_OVERRIDE to an empty string - Mesa parses it as
# "MAJOR.MINOR" and an empty value throws:
#   "invalid value for MESA_GL_VERSION_OVERRIDE"
# Leave it unset unless an app specifically needs a forced GL version.
unset MESA_GL_VERSION_OVERRIDE
export mesa_glthread=true

# DXVK: async shader compilation avoids stutter on first paint/composite
export DXVK_ASYNC=1
export DXVK_STATE_CACHE=1
export DXVK_LOG_LEVEL=none

# More headroom for large working sets and DLL address space
export WINE_LARGE_ADDRESS_AWARE=1
export STAGING_SHARED_MEMORY=1
export STAGING_WRITECOPY=1

# Give heavier apps a bit more audio buffer slack under load
export PULSE_LATENCY_MSEC=150
EOF
else
  cat >> "$WINEPREFIX/app-env.sh" <<EOF

# -- Rendering: correctness over throughput -----------------------------------
# NOTE: MESA_GL_VERSION_OVERRIDE is intentionally left unset, not set to "".
# An empty string is an invalid value and Mesa will error on launch.
unset DXVK_ASYNC DXVK_STATE_CACHE DXVK_FRAME_RATE
export mesa_glthread=false

# -- Audio ---------------------------------------------------------------------
export PULSE_LATENCY_MSEC=100
EOF
fi

cat >> "$WINEPREFIX/app-env.sh" <<EOF

echo "[ENV] App environment loaded: $WINEPREFIX"
EOF
chmod +x "$WINEPREFIX/app-env.sh"
echo "[OK] app-env.sh created"

# ============================================================================
# App Launcher (run-app)
# ============================================================================
cat > "$WINEPREFIX/run-app" <<'LAUNCHER'
#!/usr/bin/env bash
# run-app - launch a Windows application via Wine
# Version: 2.0 - windowed, stability-first, optional heavy-app tuning
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/app-env.sh"

WINVER=""
DEBUG=0
NICE_LEVEL=""

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
  echo "[WINVER] Windows version: $version"
}

show_help() {
  cat <<HELP
run-app v2.0 - Wine application launcher
Usage:
  $0 [OPTIONS] <app.exe> [app args...]

Windows Version:
  --winxp  --winvista  --win7  --win10  --win11

Other:
  --debug                  Enable verbose logging
  --nice N                 Run under 'nice -n N' for demanding apps
  -h, --help                Show this help

Examples:
  $0 Setup.exe
  $0 --win10 MyApp.exe
  $0 --nice -5 --win10 Acrobat.exe
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
    --nice)     NICE_LEVEL="$2";   shift 2 ;;
    -h|--help)  show_help ;;
    *)          break ;;
  esac
done

if [[ -z "${1:-}" ]]; then
  echo "[ERROR] No executable specified."
  show_help
fi

[[ -n "$WINVER" ]] && set_windows_version "$WINVER"

if [[ "$DEBUG" -eq 1 ]]; then
  export WINEDEBUG=+timestamp,+loaddll
fi

echo "[LAUNCH] Launching: $*"
if [[ -n "$NICE_LEVEL" ]]; then
  exec nice -n "$NICE_LEVEL" wine "$@"
else
  exec wine "$@"
fi
LAUNCHER
chmod +x "$WINEPREFIX/run-app"
echo "[OK] run-app launcher created"

# ============================================================================
# Diagnostics
# ============================================================================
cat > "$WINEPREFIX/diagnostics" <<'DIAG'
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export WINEPREFIX="$SCRIPT_DIR"

echo "+========================================+"
echo "|   Wine App Prefix Diagnostics           |"
echo "+========================================+"
echo "Prefix: $WINEPREFIX"
echo

echo "--- Wine ---"
wine --version 2>/dev/null || echo "wine not found"
winetricks --version 2>/dev/null | head -n1 || echo "winetricks not found"
echo

echo "--- DPI ---"
DPI_VAL="$(wine reg query 'HKCU\Software\Wine\Fonts' /v LogPixels 2>/dev/null | grep -oE '0x[0-9a-fA-F]+')"
if [[ -n "$DPI_VAL" ]]; then
  echo "[OK] LogPixels set: $DPI_VAL ($((DPI_VAL)) dpi)"
else
  echo "[WARN] LogPixels not set - app UIs may render oversized on HiDPI hosts."
  echo "       Fix: wine reg add \"HKCU\\Software\\Wine\\Fonts\" /v LogPixels /t REG_DWORD /d 96 /f"
fi
echo

echo "--- Environment sanity ---"
if [[ "${MESA_GL_VERSION_OVERRIDE+set}" == "set" && -z "${MESA_GL_VERSION_OVERRIDE:-}" ]]; then
  echo "[WARN] MESA_GL_VERSION_OVERRIDE is set to an empty string - this will"
  echo "       crash GL apps. Unset it: unset MESA_GL_VERSION_OVERRIDE"
else
  echo "[OK] MESA_GL_VERSION_OVERRIDE is unset or has a valid value"
fi
echo

echo "--- Installed Runtime DLLs ---"
SYS32="$WINEPREFIX/drive_c/windows/system32"
if [[ -d "$SYS32" ]]; then
  ls -lh "$SYS32"/riched*.dll "$SYS32"/gdiplus.dll "$SYS32"/msxml6.dll "$SYS32"/d3dcompiler_47.dll 2>/dev/null || echo "None found"
else
  echo "Prefix not initialised"
fi
echo

echo "--- DXVK ---"
if [[ -f "$SYS32/d3d11.dll" ]] && strings "$SYS32/d3d11.dll" 2>/dev/null | grep -qi dxvk; then
  echo "[OK] DXVK appears to be installed"
else
  echo "[SKIP] DXVK not detected (run setup with --dxvk or --heavy to add it)"
fi
echo

echo "--- Registry: Explorer / X11 Driver ---"
wine reg query "HKCU\\Software\\Wine\\Explorer" 2>/dev/null || echo "(not set)"
wine reg query "HKCU\\Software\\Wine\\X11 Driver" 2>/dev/null || echo "(not set)"
echo

echo "[OK] Diagnostics complete"
DIAG
chmod +x "$WINEPREFIX/diagnostics"
echo "[OK] diagnostics created"

# ============================================================================
# README
# ============================================================================
cat > "$WINEPREFIX/README.md" <<README
# Wine App Prefix - Standard Application Edition

## Quick Start
\`\`\`bash
# Run an installer or app (windowed, default Wine winver)
./run-app Setup.exe

# With a Windows version hint (fixes some installers/apps)
./run-app --win7  MyApp.exe
./run-app --win10 MyApp.exe

# Heavy/CEF-based apps (Acrobat DC, Office, CAD viewers) - lower nice value
# gives it scheduling priority; DXVK handles the D3D-composited UI
./run-app --nice -5 --win10 Acrobat.exe

# Verbose logging for troubleshooting
./run-app --debug MyApp.exe
\`\`\`

## Installed Components
| Component | Version |
|-----------|---------|
| Visual C++ | 2005 - 2019/2022 |
| .NET Framework | 3.5 SP1 - 4.8 |
| IE8 / WebView2 | optional (--no-ie to skip) |
| Rich Edit / GDI+ / MSXML6 / MFC42 | yes |
| Heavy runtime set (D3D compiler, D3DX9/11, atmlib, msls31) | --heavy only |
| DXVK (D3D9/10/11 -> Vulkan) | --dxvk or --heavy only |

## Why "heavy" apps like Acrobat DC lag without this
Acrobat DC's shell isn't classic Win32/GDI - it's a Chromium/CEF UI that
composites through Direct3D/DirectComposition. Without a D3D shader
compiler and a real D3D-to-native translation path, Wine falls back to a
slow software path, which shows up as UI lag, stutter, and slow redraw.
\`--heavy\` installs the D3D compiler/runtime pieces that UI actually needs
and \`--dxvk\` gives it real GPU-accelerated D3D via Vulkan.

## Design Notes
This prefix is tuned for correctness and normal desktop behaviour rather
than throughput by default:
- Windows are decorated and managed like normal X11 windows (no fullscreen
  grabbing, unlike the gaming prefix).
- No DXVK by default - most classic productivity apps don't need a Vulkan
  translation layer, and skipping it avoids extra shader-cache overhead.
  Opt in with \`--dxvk\` or \`--heavy\` for apps that do.
- \`WINEDEBUG=-all\` by default to keep logs quiet during everyday use.
- \`MESA_GL_VERSION_OVERRIDE\` is always left **unset**, never set to an
  empty string - Mesa treats an empty value as invalid and errors on
  launch (\`invalid value for MESA_GL_VERSION_OVERRIDE\`).
- \`HKCU\\Software\\Wine\\Fonts\\LogPixels\` is pinned to 96 (standard
  Windows DPI). Without this, Wine reports the host's real/scaled monitor
  DPI to the app, and DPI-aware UIs (Acrobat DC's Chromium shell included)
  scale their fonts/controls to match while the window itself doesn't -
  resulting in an oversized GUI. If 96 still looks off on your specific
  HiDPI setup, try 120 or 144:
  \`wine reg add "HKCU\\Software\\Wine\\Fonts" /v LogPixels /t REG_DWORD /d 120 /f\`

## Utilities
| Script | Purpose |
|--------|---------|
| \`./run-app\` | Launch an app/installer |
| \`./diagnostics\` | System & prefix health check |
| \`./app-env.sh\` | Environment vars (auto-loaded) |

## Troubleshooting
\`\`\`bash
./run-app --debug App.exe      # verbose Wine logs
./diagnostics                  # system health check, catches the empty
                                # MESA_GL_VERSION_OVERRIDE bug too
cat winetricks.log              # install history
\`\`\`
README
echo "[OK] README.md created"

# ============================================================================
# Final Summary
# ============================================================================
show_progress "Setup complete!"
echo
echo "+========================================+"
echo "|  [OK] App Setup Complete!               |"
echo "+========================================+"
echo
echo "[INSTALLED]"
[[ "$SKIP_FONTS"    -eq 0 ]] && echo "  [OK] Core fonts"
[[ "$SKIP_VCREDIST" -eq 0 ]] && echo "  [OK] Visual C++ 2005-2022"
[[ "$SKIP_DOTNET"   -eq 0 ]] && echo "  [OK] .NET Framework 3.5-4.8"
[[ "$SKIP_IE"       -eq 0 ]] && echo "  [OK] IE8 / WebView2"
[[ "$HEAVY_MODE"    -eq 1 ]] && echo "  [OK] Heavy runtime set (D3D compiler, D3DX9/11, atmlib, msls31)"
[[ "$ENABLE_DXVK"   -eq 1 ]] && echo "  [OK] DXVK (D3D -> Vulkan)"
echo "  [OK] Rich Edit, GDI+, MSXML6, MFC42"
echo
echo "[LAUNCH] Run an app:"
echo "  cd $WINEPREFIX"
if [[ "$HEAVY_MODE" -eq 1 || "$ENABLE_DXVK" -eq 1 ]]; then
  echo "  ./run-app --nice -5 --win10 Setup.exe"
else
  echo "  ./run-app --win10 Setup.exe"
fi
echo
echo "[TOOLS]"
echo "  ./diagnostics                     # health check"
echo "  cat README.md                     # full docs"
