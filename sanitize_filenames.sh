#!/bin/bash

# -------------------------------
# Einstellungen
# -------------------------------

DRYRUN=1        # 1 = nur anzeigen, 0 = wirklich umbenennen
LOGFILE="/var/logs/sanitize_filenames.log"

# Muster, die ignoriert werden sollen (Regex von find)
EXCLUDES=(
    '\.git'
    'node_modules'
    'lost\+found'
)

# -------------------------------
# Start Logging
# -------------------------------
mkdir -p "$(dirname "$LOGFILE")"
echo "=== Start $(date) ===" >> "$LOGFILE"


# -------------------------------
# find-Befehl dynamisch bauen
# -------------------------------
FIND_CMD=(find . -depth)

for pattern in "${EXCLUDES[@]}"; do
    FIND_CMD+=( -not -path "*$pattern*" )
done

FIND_CMD+=( -print0 )


# -------------------------------
# Hauptschleife
# -------------------------------
"${FIND_CMD[@]}" | while IFS= read -r -d '' old; do
    dir=$(dirname "$old")
    base=$(basename "$old")

    # UTF-8 prüfen → ungültige Bytes werden "_" 
    new=$(printf "%s" "$base" \
        | iconv -f utf-8 -t utf-8 --byte-subst="_" --unicode-subst="_" 2>/dev/null)

    # keine Änderung?
    [[ "$new" == "$base" ]] && continue

    newpath="$dir/$new"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "WÜRDE umbenennen: '$old' → '$newpath'"
        echo "$(date)  DRYRUN  '$old' → '$newpath'" >> "$LOGFILE"
    else
        echo "Umbenenne: '$old' → '$newpath'"
        echo "$(date)  RENAME  '$old' → '$newpath'" >> "$LOGFILE"
        mv -- "$old" "$newpath"
    fi
done

echo "=== Ende $(date) ===" >> "$LOGFILE"
