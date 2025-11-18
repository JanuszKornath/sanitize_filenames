#!/bin/bash

DRYRUN=1  # 1 = nur anzeigen, 0 = ausführen
LOGFILE="/var/log/sanitize_filenames.log"

# -------------------------
# Ordner/Pfade ausschließen
# -------------------------
EXCLUDES=(
    "*/.Trash*"
    "*/.Trash*/*"
    "*/.cache/*"
    "*/lost+found/*"
)

# -------------------------
# Logging
# -------------------------
log() {
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOGFILE"
}

# -------------------------
# Funktion: Name bereinigen
# -------------------------
sanitize() {
    local in="$1"
    local out=""
    local i=0
    local len=${#in}

    while (( i < len )); do
        local ch="${in:i:1}"
        local b
        b=$(printf "%d" "'$ch")

        if (( b >= 32 && b <= 126 )); then
            out+="$ch"
        else
            if printf '%s' "${in:i}" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
                out+="$ch"
            else
                out+="_"
            fi
        fi

        ((i++))
    done

    printf '%s' "$out"
}

# -------------------------
# find-Kommando dynamisch bauen
# -------------------------
FIND_CMD=(find . -depth)

for pattern in "${EXCLUDES[@]}"; do
    FIND_CMD+=(-path "$pattern" -prune -o)
done

# Die tatsächliche Aktion:
FIND_CMD+=(-print0)

# -------------------------
# Hauptschleife
# -------------------------
"${FIND_CMD[@]}" | while IFS= read -r -d '' path; do
    dir=$(dirname "$path")
    base=$(basename "$path")

    clean=$(sanitize "$base")
    [[ "$clean" == "$base" ]] && continue

    new="$dir/$clean"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "WÜRDE umbenennen: '$path' → '$new'"
        log "DRYRUN: '$path' → '$new'"
    else
        mv -- "$path" "$new"
        log "RENAMED: '$path' → '$new'"
    fi
done
