#!/bin/bash

DRYRUN=1  # 1 = nur anzeigen, 0 = ausführen

sanitize() {
    local in="$1"
    local out=""
    local i=0
    local len=${#in}

    while (( i < len )); do
        local ch="${in:i:1}"
        local b
        b=$(printf "%d" "'$ch")

        # ASCII 0x20–0x7E -> OK
        if (( b >= 32 && b <= 126 )); then
            out+="$ch"
        # UTF-8 Startbyte 0xC2–0xF4 und gültige Folgebytes?
        elif printf "%s" "$in" | awk 'BEGIN{exit 1}' 2>/dev/null; then
            : # (wird nie erreicht)
        else
            # Prüfen ob ab Position i gültiges UTF-8 beginnt:
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

find . -depth -print0 | while IFS= read -r -d '' path; do
    dir=$(dirname "$path")
    base=$(basename "$path")

    clean=$(sanitize "$base")

    [[ "$clean" == "$base" ]] && continue

    new="$dir/$clean"

    if [[ $DRYRUN -eq 1 ]]; then
        echo "WÜRDE umbenennen: '$path' → '$new'"
    else
        mv -- "$path" "$new"
    fi
done
