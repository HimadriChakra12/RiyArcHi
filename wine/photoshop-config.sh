#!/usr/bin/env bash
# wine-setup-photoshop.sh - Photoshop CS6 Wine Setup (Arch Linux only)
# Version: 3.0

set -euo pipefail

WINEPREFIX="${1:-}"
ENABLE_DXVK=0
MEMORY_SIZE="2048"

# ----------------------------------------------------------------------------
# Display helpers
# ----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_INFO=$'\033[36m'
  C_RESET=$'\033[0m'
else
  C_DIM=""; C_BOLD=""; C_OK=""; C_WARN=""; C_ERR=""; C_INFO=""; C_RESET=""
fi

TOTAL_STEPS=8
STEP=0

bar() {
  local pct=$1 width=30
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  printf "%s" "["
  printf "%0.s#" $(seq 1 "$filled") 2>/dev/null
  printf "%0.s." $(seq 1 "$empty") 2>/dev/null
  printf "%s" "]"
}

step() {
  STEP=$((STEP + 1))
  local pct=$(( STEP * 100 / TOTAL_STEPS ))
  printf "\n%s%s %3d%%%s  %s%d/%d%s  %s%s%s\n" \
    "$C_BOLD" "$(bar "$pct")" "$pct" "$C_RESET" \
    "$C_DIM" "$STEP" "$TOTAL_STEPS" "$C_RESET" \
    "$C_INFO" "$1" "$C_RESET"
}

ok()    { printf "  %s[OK]%s    %s\n"    "$C_OK"   "$C_RESET" "$1"; }
info()  { printf "  %s[INFO]%s  %s\n"    "$C_INFO" "$C_RESET" "$1"; }
warn()  { printf "  %s[WARN]%s  %s\n"    "$C_WARN" "$C_RESET" "$1"; }
fail()  { printf "  %s[ERROR]%s %s\n"    "$C_ERR"  "$C_RESET" "$1"; exit 1; }

# ----------------------------------------------------------------------------
# Usage
# ----------------------------------------------------------------------------
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

[[ $# -eq 0 ]] && show_usage
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-dxvk) ENABLE_DXVK=1; shift ;;
    --memory) MEMORY_SIZE="$2"; shift 2 ;;
    -h|--help) show_usage ;;
    *) fail "Unknown option: $1" ;;
  esac
done

[[ -z "$WINEPREFIX" ]] && fail "PREFIX required"
[[ ! -d "$WINEPREFIX" ]] && fail "Prefix not found: $WINEPREFIX"
command -v pacman >/dev/null 2>&1 || fail "This script targets Arch Linux (pacman) only"

export WINEPREFIX

printf "%s== Photoshop CS6 Wine Setup ==%s\n" "$C_BOLD" "$C_RESET"
printf "%sprefix:%s %s   %smemory:%s %sMB   %sdxvk:%s %s\n\n" \
  "$C_DIM" "$C_RESET" "$WINEPREFIX" "$C_DIM" "$C_RESET" "$MEMORY_SIZE" "$C_DIM" "$C_RESET" "$([[ $ENABLE_DXVK -eq 1 ]] && echo on || echo off)"

# ----------------------------------------------------------------------------
# 1. Dependency check
# ----------------------------------------------------------------------------
step "Checking dependencies"
MISSING=()
for pkg_bin in "wine:wine" "winetricks:winetricks" "aria2c:aria2"; do
  bin="${pkg_bin%%:*}"; pkg="${pkg_bin##*:}"
  command -v "$bin" >/dev/null 2>&1 || MISSING+=("$pkg")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  info "Installing missing packages: ${MISSING[*]}"
  sudo pacman -Sy --needed --noconfirm "${MISSING[@]}"
fi
ok "All dependencies present"

export WINETRICKS_DOWNLOADER=aria2c
export ARIA2C_OPTS="-x 16 -s 16 -k 1M --file-allocation=trunc --continue=true --retry-wait=5 --max-tries=0 --summary-interval=5"
export WINETRICKS_VERBOSE=1
export WINEDEBUG=err+all,warn+all
ok "aria2c enabled (16 connections)"

# ----------------------------------------------------------------------------
# 2. Photoshop detection
# ----------------------------------------------------------------------------
step "Scanning for existing Photoshop install"
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
[[ -n "$FOUND_PS" ]] && ok "Found: $FOUND_PS" || warn "Not found yet (install it into the prefix manually)"

# ----------------------------------------------------------------------------
# 3-6. Winetricks installs
# ----------------------------------------------------------------------------
step "Installing fonts"
winetricks -q corefonts >/dev/null 2>&1 || warn "corefonts step reported an issue"
ok "corefonts"

step "Installing VC++ runtimes"
winetricks -q vcrun2008 vcrun2010 vcrun2012 vcrun2013 >/dev/null 2>&1 || warn "vcrun step reported an issue"
ok "vcrun2008 vcrun2010 vcrun2012 vcrun2013"

step "Installing graphics libraries"
winetricks -q msxml3 msxml6 gdiplus atmlib >/dev/null 2>&1 || warn "graphics libs step reported an issue"
ok "msxml3 msxml6 gdiplus atmlib"

step "Installing DirectX components"
winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 >/dev/null 2>&1 || warn "DirectX step reported an issue"
ok "d3dx9 d3dcompiler_43 d3dcompiler_47"
if [[ "$ENABLE_DXVK" -eq 1 ]]; then
  info "Installing DXVK (experimental)"
  winetricks -q dxvk >/dev/null 2>&1 || warn "dxvk step reported an issue"
  ok "dxvk"
fi

# ----------------------------------------------------------------------------
# 7. Registry tweaks
# ----------------------------------------------------------------------------
step "Applying registry tweaks"
REG_FILE="$(mktemp)"
cat > "$REG_FILE" <<REG
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
wine regedit "$REG_FILE" >/dev/null 2>&1
rm -f "$REG_FILE"
ok "Direct3D + DllOverrides written"

# ----------------------------------------------------------------------------
# 8. Environment + launcher
# ----------------------------------------------------------------------------
step "Writing environment and launcher"
cat > "$WINEPREFIX/photoshop-env.sh" <<EOF
#!/usr/bin/env bash
export STAGING_SHARED_MEMORY=1
export WINE_HEAP_DELAY_FREE=1
export WINE_CPU_TOPOLOGY=4:0
EOF
chmod +x "$WINEPREFIX/photoshop-env.sh"

cat > "$WINEPREFIX/run-photoshop" <<'EOF'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="$DIR"
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

echo "[ERROR] Photoshop not found"
exit 1
EOF
chmod +x "$WINEPREFIX/run-photoshop"
[[ -n "$FOUND_PS" ]] && echo "$FOUND_PS" > "$WINEPREFIX/photoshop-path.txt"
ok "run-photoshop launcher ready"

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
printf "\n%s%s%s\n" "$C_OK" "$(bar 100) 100%  setup complete" "$C_RESET"
echo
echo "[RUN]  $WINEPREFIX/run-photoshop"
echo "[NOTE] Safe to re-run this script; aria2c resumes interrupted downloads"
