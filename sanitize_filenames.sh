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
# Logging-Funktion
# -------------------------
log() {
    printf "%s\n" "$1" | tee -a "$LOGFILE"
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

        # ASCII 0x20–0x7E = ok
        if (( b >= 32 && b <= 126 )); then
            out+="$ch"
        else
            # Prüfen ob ab Position i gültiges UTF-8 beginnt
            if printf '%s' "${in:i}" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
                out+="$ch"
            else
                out+="_"
            fi
        fi
        ((i++))
    done

    printf "%s" "$out"
}

# -------------------------
# find-Kommando bauen
# -------------------------

FIND_CMD=(find . -depth)

for pattern in "${EXCLUDES[@]}"; do
    FIND_CMD+=( \( -path "$pattern" -prune \) -o )
done

FIND_CMD+=(-print0)

# -------------------------
# Hauptschleife
# -------------------------
"${FIND_CMD[@]}" |
while IFS= read -r -d '' path; do
    dir=$(dirname "$path")
    base=$(basename "$path")

    clean=$(sanitize "$base")
    [[ "$clean" == "$base" ]] && continue

    new="$dir/$clean"

    if [[ $DRYRUN -eq 1 ]]; then
        log "WÜRDE umbenennen: '$path' → '$new'"
    else
        log "Umbenennen: '$path' → '$new'"
        mv -- "$path" "$new"
    fi
done
