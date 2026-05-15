#!/usr/bin/env bash
# =============================================================================
#  GraveGain Mod - One-Click macOS / Linux Installer
#  Double-click install_gravegain.command on macOS, or run:
#    bash install_gravegain.command
#  Optional env vars:
#    L4D2_PATH  - path to your Left 4 Dead 2 folder (parent of left4dead2/)
#    MOD_PATH   - path to the GraveGain mod folder (defaults to script dir)
# =============================================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  Colour helpers
# ─────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[1;35m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}==> $*${RESET}"; }
ok()    { echo -e "${GREEN}  [OK] $*${RESET}"; }
warn()  { echo -e "${YELLOW}  [!!] $*${RESET}"; }
fail()  { echo -e "${RED}  [ERROR] $*${RESET}"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
#  Banner
# ─────────────────────────────────────────────────────────────────────────────
clear
echo -e "${MAGENTA}${BOLD}"
echo " _____ _____ _____ __ __ _____  _____ _____ _____ _____"
echo "|   __|  _  |  _  |  |  |   __|/ __  |  _  |     |   | |"
echo "|  |  |     |     |  |  |   __|    __|     |-   -|    |  |"
echo "|_____|__|__|__|__|\\___/|_____|\\_____|_|___|_____|__|____|"
echo ""
echo "        GraveGain Melee Overhaul - macOS/Linux Installer"
echo "        https://mattyjacks.com"
echo -e "${RESET}"

# ─────────────────────────────────────────────────────────────────────────────
#  Script directory (works when double-clicked on macOS too)
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOD_PATH="${MOD_PATH:-$SCRIPT_DIR}"
PLATFORM="$(uname -s)"

# ─────────────────────────────────────────────────────────────────────────────
#  Find L4D2
# ─────────────────────────────────────────────────────────────────────────────
info "Locating Left 4 Dead 2..."

if [[ -z "${L4D2_PATH:-}" ]]; then
    # Common Steam library paths - declare first to avoid set -u error on empty array
    CANDIDATES=('')
    CANDIDATES=()

    if [[ "$PLATFORM" == "Darwin" ]]; then
        CANDIDATES+=(
            "$HOME/Library/Application Support/Steam/steamapps/common/Left 4 Dead 2"
            "/Applications/Steam/steamapps/common/Left 4 Dead 2"
        )
        # Also check libraryfolders.vdf for extra libraries
        VDF="$HOME/Library/Application Support/Steam/steamapps/libraryfolders.vdf"
    else
        # Linux
        CANDIDATES+=(
            "$HOME/.steam/steam/steamapps/common/Left 4 Dead 2"
            "$HOME/.local/share/Steam/steamapps/common/Left 4 Dead 2"
        )
        VDF="$HOME/.steam/steam/steamapps/libraryfolders.vdf"
    fi

    # Parse extra library paths from libraryfolders.vdf
    if [[ -f "$VDF" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \"path\"[[:space:]]*\"([^\"]+)\" ]]; then
                extra="${BASH_REMATCH[1]}/steamapps/common/Left 4 Dead 2"
                CANDIDATES+=("$extra")
            fi
        done < "$VDF"
    fi

    for c in "${CANDIDATES[@]}"; do
        if [[ -d "$c/left4dead2" ]]; then
            L4D2_PATH="$c"
            break
        fi
    done
fi

if [[ -z "${L4D2_PATH:-}" ]] || [[ ! -d "$L4D2_PATH/left4dead2" ]]; then
    warn "Could not auto-detect L4D2."
    echo -n "Enter the full path to your Left 4 Dead 2 folder (contains left4dead2/): "
    read -r L4D2_PATH
    L4D2_PATH="${L4D2_PATH%/}"  # strip trailing slash
fi

L4D2_GAME="$L4D2_PATH/left4dead2"
if [[ ! -d "$L4D2_GAME" ]]; then
    fail "Could not find 'left4dead2/' inside: $L4D2_PATH"
fi

ok "Found: $L4D2_PATH"

# ─────────────────────────────────────────────────────────────────────────────
#  Verify mod files
# ─────────────────────────────────────────────────────────────────────────────
info "Verifying mod files in: $MOD_PATH"

SMX_FILE="$MOD_PATH/sourcemod/scripting/gravegain_melee_pro.smx"
SCRIPTS_DIR="$MOD_PATH/scripts"

[[ -f "$SMX_FILE"      ]] || fail "Missing compiled plugin: $SMX_FILE"
[[ -d "$SCRIPTS_DIR"   ]] || fail "Missing scripts folder: $SCRIPTS_DIR"

ok "Mod files present."

# ─────────────────────────────────────────────────────────────────────────────
#  Check dependencies (curl + tar)
# ─────────────────────────────────────────────────────────────────────────────
for cmd in curl unzip; do
    command -v "$cmd" &>/dev/null || fail "'$cmd' is required but not installed. Install it with your package manager."
done

# ─────────────────────────────────────────────────────────────────────────────
#  Download Metamod + SourceMod
# ─────────────────────────────────────────────────────────────────────────────
info "Downloading Metamod:Source and SourceMod..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Determine OS suffix for downloads
if [[ "$PLATFORM" == "Darwin" ]]; then
    OS_TAG="mac"
else
    OS_TAG="linux"
fi

# GitHub release URLs - actual stable build filenames
MM_URL="https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1224/mmsource-1.12.0-git1224-${OS_TAG}.tar.gz"
SM_URL="https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7230/sourcemod-1.12.0-git7230-${OS_TAG}.tar.gz"

MM_ARCHIVE="$TMP_DIR/metamod.tar.gz"
SM_ARCHIVE="$TMP_DIR/sourcemod.tar.gz"

echo "  Downloading Metamod:Source..."
curl -fsSL --retry 3 -o "$MM_ARCHIVE" "$MM_URL" || fail "Failed to download Metamod."
ok "Metamod downloaded."

echo "  Downloading SourceMod..."
curl -fsSL --retry 3 -o "$SM_ARCHIVE" "$SM_URL" || fail "Failed to download SourceMod."
ok "SourceMod downloaded."

# ─────────────────────────────────────────────────────────────────────────────
#  Extract
# ─────────────────────────────────────────────────────────────────────────────
info "Extracting archives..."

MM_DIR="$TMP_DIR/metamod"
SM_DIR="$TMP_DIR/sourcemod"
mkdir -p "$MM_DIR" "$SM_DIR"

tar -xzf "$MM_ARCHIVE" -C "$MM_DIR" || fail "Failed to extract Metamod archive."
ok "Metamod extracted."

tar -xzf "$SM_ARCHIVE" -C "$SM_DIR" || fail "Failed to extract SourceMod archive."
ok "SourceMod extracted."

# ─────────────────────────────────────────────────────────────────────────────
#  Install Metamod + SourceMod  (merge into game dir)
# ─────────────────────────────────────────────────────────────────────────────
info "Installing Metamod:Source into: $L4D2_GAME"

# Locate addons/ inside the extracted tree
MM_ADDONS=$(find "$MM_DIR" -maxdepth 3 -type d -name "addons" | head -1)
[[ -n "$MM_ADDONS" ]] || fail "Could not locate addons/ inside Metamod archive."
mkdir -p "$L4D2_GAME/addons"
cp -r "$MM_ADDONS/." "$L4D2_GAME/addons/"
ok "Metamod installed."

info "Installing SourceMod..."

for sub in addons cfg; do
    SRC=$(find "$SM_DIR" -maxdepth 3 -type d -name "$sub" | head -1)
    if [[ -n "$SRC" ]]; then
        mkdir -p "$L4D2_GAME/$sub"
        cp -r "$SRC/." "$L4D2_GAME/$sub/"
        ok "SourceMod $sub/ installed."
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
#  Install GraveGain plugin
# ─────────────────────────────────────────────────────────────────────────────
info "Installing GraveGain plugin..."

PLUGINS_DIR="$L4D2_GAME/addons/sourcemod/plugins"
mkdir -p "$PLUGINS_DIR"
cp "$SMX_FILE" "$PLUGINS_DIR/"
ok "gravegain_melee_pro.smx installed."

# ─────────────────────────────────────────────────────────────────────────────
#  Install VScripts
# ─────────────────────────────────────────────────────────────────────────────
info "Installing VScripts..."

mkdir -p "$L4D2_GAME/scripts"
cp -r "$SCRIPTS_DIR/." "$L4D2_GAME/scripts/"
ok "VScripts installed."

# ─────────────────────────────────────────────────────────────────────────────
#  Fix macOS permissions (game binaries need execute bit)
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$PLATFORM" == "Darwin" ]]; then
    info "Fixing file permissions..."
    find "$L4D2_GAME/addons/metamod" -name "*.dylib" -exec chmod 755 {} \; 2>/dev/null || true
    find "$L4D2_GAME/addons/sourcemod" -name "*.dylib" -exec chmod 755 {} \; 2>/dev/null || true
    ok "Permissions fixed."
fi

# ─────────────────────────────────────────────────────────────────────────────
#  Done
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo -e "${GREEN}${BOLD}  GraveGain Mod installed successfully!${RESET}"
echo ""
echo -e "  Installed to: ${BOLD}$L4D2_GAME${RESET}"
echo ""
echo "  Next steps:"
echo "    1. Start Left 4 Dead 2"
echo "    2. Open console (~) and type: sm version"
echo "    3. You should see SourceMod loaded."
echo "    4. In-game: Block (RClick), Shove (LClick+Block),"
echo "       hold F when Ultimate is READY to arm + fire."
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo ""

# Keep terminal open when double-clicked on macOS
if [[ "$PLATFORM" == "Darwin" ]]; then
    echo "Press any key to close..."
    read -rsn1
fi
