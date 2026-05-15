#!/usr/bin/env bash
# =============================================================================
#  GraveGain Mod - macOS / Linux Uninstaller
#  Double-click uninstall_gravegain.command on macOS, or run:
#    bash uninstall_gravegain.command
#  Optional env vars:
#    L4D2_PATH - path to your Left 4 Dead 2 folder (parent of left4dead2/)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[1;35m'; BOLD='\033[1m'; RESET='\033[0m'

info() { echo -e "${CYAN}==> $*${RESET}"; }
ok()   { echo -e "${GREEN}  [OK] $*${RESET}"; }
warn() { echo -e "${YELLOW}  [!!] $*${RESET}"; }
fail() { echo -e "${RED}  [ERROR] $*${RESET}"; exit 1; }

remove_if_exists() {
    local path="$1" label="$2"
    if [[ -e "$path" ]]; then
        rm -rf "$path"
        ok "Removed: $label"
    else
        warn "Not found (skipping): $label"
    fi
}

remove_if_empty_dir() {
    local dir="$1" label="$2"
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; then
        rmdir "$dir"
        ok "Removed empty dir: $label"
    fi
}

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
echo "        GraveGain Melee Overhaul - macOS/Linux Uninstaller"
echo -e "${RESET}"

PLATFORM="$(uname -s)"

# ─────────────────────────────────────────────────────────────────────────────
#  Find L4D2
# ─────────────────────────────────────────────────────────────────────────────
info "Locating Left 4 Dead 2..."

if [[ -z "${L4D2_PATH:-}" ]]; then
    CANDIDATES=('')
    CANDIDATES=()
    if [[ "$PLATFORM" == "Darwin" ]]; then
        CANDIDATES+=(
            "$HOME/Library/Application Support/Steam/steamapps/common/Left 4 Dead 2"
            "/Applications/Steam/steamapps/common/Left 4 Dead 2"
        )
        VDF="$HOME/Library/Application Support/Steam/steamapps/libraryfolders.vdf"
    else
        CANDIDATES+=(
            "$HOME/.steam/steam/steamapps/common/Left 4 Dead 2"
            "$HOME/.local/share/Steam/steamapps/common/Left 4 Dead 2"
        )
        VDF="$HOME/.steam/steam/steamapps/libraryfolders.vdf"
    fi

    if [[ -f "$VDF" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \"path\"[[:space:]]*\"([^\"]+)\" ]]; then
                CANDIDATES+=("${BASH_REMATCH[1]}/steamapps/common/Left 4 Dead 2")
            fi
        done < "$VDF"
    fi

    for c in "${CANDIDATES[@]}"; do
        if [[ -d "$c/left4dead2" ]]; then
            L4D2_PATH="$c"; break
        fi
    done
fi

if [[ -z "${L4D2_PATH:-}" ]] || [[ ! -d "${L4D2_PATH}/left4dead2" ]]; then
    warn "Could not auto-detect L4D2."
    echo -n "Enter full path to Left 4 Dead 2 folder (contains left4dead2/): "
    read -r L4D2_PATH
    L4D2_PATH="${L4D2_PATH%/}"
fi

L4D2_GAME="$L4D2_PATH/left4dead2"
[[ -d "$L4D2_GAME" ]] || fail "Could not find 'left4dead2/' inside: $L4D2_PATH"
ok "Found: $L4D2_PATH"

# ─────────────────────────────────────────────────────────────────────────────
#  Confirm scope
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}What would you like to remove?${RESET}"
echo "  [1] GraveGain mod files only (plugin + VScripts)"
echo "  [2] GraveGain + SourceMod (removes ALL SourceMod plugins/data)"
echo "  [3] GraveGain + SourceMod + Metamod (full uninstall)"
echo "  [q] Quit"
echo ""
echo -n "Enter choice: "
read -r CHOICE

REMOVE_SM=false
REMOVE_MM=false

case "$CHOICE" in
    1) ;;
    2) REMOVE_SM=true ;;
    3) REMOVE_SM=true; REMOVE_MM=true ;;
    q|Q) echo "Cancelled."; exit 0 ;;
    *) fail "Invalid choice." ;;
esac

CONFIRM_MSG="This will remove GraveGain"
# Compare strings explicitly - bash treats the string 'false' as truthy in boolean context
if [[ "$REMOVE_MM" == "true" ]]; then
    CONFIRM_MSG+=" + Metamod:Source + SourceMod"
elif [[ "$REMOVE_SM" == "true" ]]; then
    CONFIRM_MSG+=" + SourceMod"
fi
CONFIRM_MSG+=" from: $L4D2_GAME"
echo ""
echo -e "${YELLOW}$CONFIRM_MSG${RESET}"
echo -n "Continue? (y/N): "
read -r CONFIRM
# Use tr for lowercase - bash 3.2 (macOS default) does not support ${var,,}
CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
[[ "$CONFIRM_LOWER" == "y" ]] || { echo "Cancelled."; exit 0; }

# ─────────────────────────────────────────────────────────────────────────────
#  Remove GraveGain plugin
# ─────────────────────────────────────────────────────────────────────────────
info "Removing GraveGain plugin..."

remove_if_exists "$L4D2_GAME/addons/sourcemod/plugins/gravegain_melee_pro.smx"  "addons/sourcemod/plugins/gravegain_melee_pro.smx"
remove_if_exists "$L4D2_GAME/addons/sourcemod/scripting/gravegain_melee_pro.sp"  "addons/sourcemod/scripting/gravegain_melee_pro.sp"
remove_if_exists "$L4D2_GAME/addons/sourcemod/scripting/gravegain_melee_pro.smx" "addons/sourcemod/scripting/gravegain_melee_pro.smx"

# ─────────────────────────────────────────────────────────────────────────────
#  Remove VScripts
# ─────────────────────────────────────────────────────────────────────────────
info "Removing GraveGain VScripts..."

VSCRIPTS=(
    "scripts/vscripts/coop.nut"
    "scripts/vscripts/director_base_addon.nut"
    "scripts/vscripts/gravegain_melee_core.nut"
    "scripts/vscripts/lore_system.nut"
)
for rel in "${VSCRIPTS[@]}"; do
    remove_if_exists "$L4D2_GAME/$rel" "$rel"
done

remove_if_empty_dir "$L4D2_GAME/scripts/vscripts" "scripts/vscripts/"
remove_if_empty_dir "$L4D2_GAME/scripts"           "scripts/"

# ─────────────────────────────────────────────────────────────────────────────
#  Optionally remove SourceMod
# ─────────────────────────────────────────────────────────────────────────────
if $REMOVE_SM; then
    info "Removing SourceMod..."
    remove_if_exists "$L4D2_GAME/addons/sourcemod" "addons/sourcemod/"
    remove_if_exists "$L4D2_GAME/cfg/sourcemod"    "cfg/sourcemod/"
fi

# ─────────────────────────────────────────────────────────────────────────────
#  Optionally remove Metamod
# ─────────────────────────────────────────────────────────────────────────────
if $REMOVE_MM; then
    info "Removing Metamod:Source..."
    remove_if_exists "$L4D2_GAME/addons/metamod"     "addons/metamod/"
    remove_if_exists "$L4D2_GAME/addons/metamod.vdf" "addons/metamod.vdf"
    remove_if_empty_dir "$L4D2_GAME/addons" "addons/"
fi

# ─────────────────────────────────────────────────────────────────────────────
#  Done
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo -e "${GREEN}${BOLD}  GraveGain uninstall complete.${RESET}"
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo ""

if [[ "$PLATFORM" == "Darwin" ]]; then
    echo "Press any key to close..."
    read -rsn1
fi
