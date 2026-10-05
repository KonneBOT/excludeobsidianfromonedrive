#!/usr/bin/env bash

set -u

ONEDRIVE_DIR="$HOME/OneDrive"
ONEDRIVE_SERVICE="onedrive.service"
CHECK_INTERVAL=5

declare -a VAULTS=()

find_vaults() {
    VAULTS=()

    while IFS= read -r -d '' obsidian_dir; do
        vault_dir="$(dirname "$obsidian_dir")"
        VAULTS+=("$vault_dir")
    done < <(find "$ONEDRIVE_DIR" -type d -name ".obsidian" -print0)
}

setup_nosync() {
    find_vaults

    for vault in "${VAULTS[@]}"; do
        # Drop .nosync file in parent dir to signalize nosync in this dir
        touch "$vault/.nosync"
        echo "Applied nosync to vault: $vault"
    done
}

is_obsidian_running() {
    pgrep -f '/usr/lib/obsidian/app.asar' >/dev/null 2>&1
}

sync_vaults() {
    find_vaults

    if [ "${#VAULTS[@]}" -eq 0 ]; then
        echo "No Obsidian vaults found."
        return
    fi

    echo "Obsidian closed - synchronizing vaults..."

    # Stop OneDrive-Monitor service temporarily
    systemctl --user stop "$ONEDRIVE_SERVICE"

    # Falls der Service noch nicht vollständig beendet ist.
    while pgrep -x onedrive >/dev/null 2>&1; do
        sleep 1
    done

    # If interrupted, clean up
    cleanup() {
        echo "Reinstating .nosync protection..."
        for vault in "${VAULTS[@]}"; do
            touch "$vault/.nosync"
        done

        systemctl --user start "$ONEDRIVE_SERVICE"
    }

    trap cleanup EXIT INT TERM

    for vault in "${VAULTS[@]}"; do
        relative="${vault#"$ONEDRIVE_DIR"/}"

        echo
        echo "========================================"
        echo "Sync: $relative"
        echo "========================================"

        rm -f "$vault/.nosync"

        if ! onedrive --sync --single-directory "$relative"; then
            echo "ERROR syncing: $relative"
        fi

        # Reinstate .nosync here
        touch "$vault/.nosync"
    done

    trap - EXIT INT TERM

    systemctl --user start "$ONEDRIVE_SERVICE"

    echo
    echo "Synced all vaults in OneDrive dir."
}

# On startup, setup nosync in every relevant dir
setup_nosync

previous_state="closed"

if is_obsidian_running; then
    previous_state="open"
fi

echo "Obsidian-OneDrive helper is running."
echo "initial state: $previous_state"

while true; do
    if is_obsidian_running; then
        current_state="open"
    else
        current_state="closed"
    fi

    # Only react when chaning from open to closed
    if [[ "$previous_state" == "open" && "$current_state" == "closed" ]]; then
        sync_vaults
    fi

    previous_state="$current_state"

    sleep "$CHECK_INTERVAL"
done