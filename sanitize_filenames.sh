#!/bin/bash

DRYRUN=1
LOGFILE="/var/log/sanitize_filenames.log"
EXCLUDES=( '\.git' 'lost\+found' )

mkdir -p "$(dirname "$LOGFILE")"
echo "=== Start $(date) ===" >> "$LOGFILE"

# find zusammenbauen
FIND_CMD=(find . -depth)
for pattern in "${EXCLUDES[@]}"; do
  FIND_CMD+=( -not -path "*$pattern*" )
done
FIND_CMD+=( -print0 )


"${FIND_CMD[@]}" | while IFS= read -r -d '' old; do
    dir=$(dirname "$old")
    base=$(basename "$old")

    # **Basename Byte für Byte durchgehen**
    newbase=""
    raw=$(printf '%s' "$base" | sed 's/\\/\\\\/g')

    # rohe Bytes
    while IFS= read -r -n1 ch; do
        byte=$(printf '%d' "'$ch")

        # gültige ASCII-Zeichen? (Leerzeichen bis ~)
        if (( byte >= 32 && byte <= 126 )); then
            newbase+="$ch"
        else
            newbase+="_"
        fi
    done <<< "$base"

    # Wenn keine Änderung → skip
    [[ "$newbase" == "$base" ]] && continue

    newpath="$dir/$newbase"

    # wenn Ziel existiert → suffix anhängen
    if [[ -e "$newpath" ]]; then
        i=1
        while [[ -e "$dir/${newbase}_$i" ]]; do
            ((i++))
        done
        newpath="$dir/${newbase}_$i"
    fi

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
