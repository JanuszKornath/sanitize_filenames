#!/bin/bash
# sanitize_filenames_safe.sh
# Trockenlauf standardmäßig. Arbeitet im aktuellen Verzeichnis (.) wie gewünscht.

DRYRUN=1
LOGFILE="/var/logs/sanitize_filenames.log"

EXCLUDES=(
  '\.git'
  'node_modules'
  'lost\+found'
)

mkdir -p "$(dirname "$LOGFILE")"
echo "=== Start $(date) ===" >> "$LOGFILE"

# Build find command with excludes
FIND_CMD=(find . -depth)
for pattern in "${EXCLUDES[@]}"; do
  FIND_CMD+=( -not -path "*$pattern*" )
done
FIND_CMD+=( -print0 )

"${FIND_CMD[@]}" | while IFS= read -r -d '' old; do
    dir=$(dirname "$old")
    base=$(basename "$old")

    # iconv ersetzt ungültige UTF-8 Bytes durch _
    newbase=$(printf "%s" "$base" \
        | iconv -f utf-8 -t utf-8 --byte-subst="_" --unicode-subst="_" 2>/dev/null || true)

    # Falls iconv nichts zurückgibt oder nur Whitespace -> Ersatzname
    # Entferne führende/trailing whitespace (nur zur Sicherheit)
    newbase="$(printf '%s' "$newbase" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Sicherheit: kein leerer Name und nicht "." oder ".."
    if [[ -z "$newbase" || "$newbase" == "." || "$newbase" == ".." ]]; then
        newbase="_"
    fi

    # Wenn unverändert -> nichts tun
    if [[ "$newbase" == "$base" ]]; then
        continue
    fi

    newpath="$dir/$newbase"

    # Falls Ziel schon existiert -> eindeutigen Suffix anhängen
    if [[ -e "$newpath" ]]; then
        stem="$newbase"
        ext=""
        # optional: behandle Erweiterung separat (name.ext -> name_ext)
        if [[ "$newbase" == *.* && ! "$newbase" == .* ]]; then
            stem="${newbase%.*}"
            ext=".${newbase##*.}"
        fi
        i=1
        while [[ -e "$dir/${stem}_$i$ext" ]]; do
            ((i++))
        done
        newpath="$dir/${stem}_$i$ext"
    fi

    # Endgültige Prüfung: vermeide Umbenennung auf gleichen Pfad
    if [[ "$old" == "$newpath" ]]; then
        continue
    fi

    if [[ $DRYRUN -eq 1 ]]; then
        echo "WÜRDE umbenennen: '$old' → '$newpath'"
        echo "$(date)  DRYRUN  '$old' → '$newpath'" >> "$LOGFILE"
    else
        echo "Umbenenne: '$old' → '$newpath'"
        echo "$(date)  RENAME  '$old' → '$newpath'" >> "$LOGFILE"
        mv -- "$old" "$newpath"
        if [[ $? -ne 0 ]]; then
            echo "$(date)  ERROR renaming '$old' -> '$newpath'" >> "$LOGFILE"
        fi
    fi
done

echo "=== Ende $(date) ===" >> "$LOGFILE"
