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
            # ACHTUNG: Das ist eine ungenaue Prüfung, aber sie soll hier das Originalskriptverhalten nachbilden
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
# find-Kommando bauen (KORRIGIERT)
# -------------------------

FIND_CMD=(find . -depth)

# Start der Klammer für alle ODER-Ausschlüsse
FIND_CMD+=( \( )

first=true
for pattern in "${EXCLUDES[@]}"; do
    if ! $first; then
        FIND_CMD+=( -o ) # Logisches ODER zwischen den Mustern
    fi
    # Wenn Muster zutrifft: Pfad nicht ausgeben UND Unterverzeichnis ignorieren
    FIND_CMD+=( -path "$pattern" -prune ) 
    first=false
done

# Schließen der Ausschluss-Klammer:
# Wenn die Bedingung in der Klammer (ein Ausschluss) WAHR ist, wird das
# nachfolgende ODER ignoriert und nichts ausgegeben.
# Wenn die Bedingung in der Klammer FALSCH ist (kein Ausschluss),
# springt find über das ODER zum nächsten Ausdruck (-print0) und gibt den Pfad aus.
FIND_CMD+=( \) -o -print0 ) 

# -------------------------
# Hauptschleife
# -------------------------
log "--- Starte Umbenennungslauf (DRYRUN=$DRYRUN) ---"
log "Zu prüfender find-Befehl:"
log "${FIND_CMD[@]}"
log "-------------------------------------------------"

"${FIND_CMD[@]}" |
while IFS= read -r -d '' path; do
    dir=$(dirname "$path")
    base=$(basename "$path")

    # Nur Dateinamen (basename) bereinigen
    clean=$(sanitize "$base")
    [[ "$clean" == "$base" ]] && continue

    new="$dir/$clean"

    if [[ $DRYRUN -eq 1 ]]; then
        log "WÜRDE umbenennen: '$path' -> '$new'"
    else
        log "Umbenennen: '$path' -> '$new'"
        mv -- "$path" "$new"
    fi
done

log "--- Lauf beendet ---"
