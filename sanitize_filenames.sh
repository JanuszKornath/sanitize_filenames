#!/bin/bash

DRYRUN=1  # 0 = umbenennen, 1 = nur anzeigen

sanitize_name() {
    printf '%s' "$1" \
        | iconv -f UTF-8 -t UTF-8//TRANSLIT 2>/dev/null \
        || :

    # iconv ersetzt ungültige Bytes durch Fragezeichen → wir wandeln "?" in "_" um
}

find . -depth -print0 | while IFS= read -r -d '' path; do
    dir=$(dirname "$path")
    base=$(basename "$path")

    # Nur testen, ob UTF-8 valide
    if printf '%s' "$base" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
        # gültiges UTF-8 → nichts tun
        continue
    fi

    # Basis bereinigen: ungültige Bytes → ?
    clean=$(printf '%s' "$base" | iconv -f UTF-8 -t UTF-8//TRANSLIT 2>/dev/null)

    # Fragezeichen → Unterstrich
    clean="${clean//\?/_}"

    new="$dir/$clean"

    if [[ "$path" != "$new" ]]; then
        if [[ $DRYRUN -eq 1 ]]; then
            echo "WÜRDE umbenennen: '$path' → '$new'"
        else
            mv -- "$path" "$new"
        fi
    fi
done
