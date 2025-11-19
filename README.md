# sanitize_filenames.sh

Ein Bash-Skript zum rekursiven Bereinigen von Dateinamen.
Ungültige oder beschädigte Zeichen werden ersetzt, UTF-8-Zeichen werden erkannt und beibehalten.
Unterstützt Dry-Run, Logging und definierte Ausschlussmuster.

## Features

Rekursive Dateinamen-Bereinigung

Erkennung gültiger UTF-8-Zeichen

Ersetzen ungültiger Zeichen durch _

Dry-Run (DRYRUN=1) und Live-Modus

Logging nach /var/log/sanitize_filenames.log

Ausschluss definierter Systempfade mittels find -prune

## Verwendung
Skript ausführbar machen
```
chmod +x sanitize_filenames.sh
```

Dry-Run ausführen (Standard)
```
./sanitize_filenames.sh
```

Echtmodus (Umbenennungen werden durchgeführt)
```
DRYRUN=0 ./sanitize_filenames.sh
```

Oder Variable im Skript anpassen:
```
DRYRUN=0
```
## Ausschlüsse

Folgende Pfade werden von der Verarbeitung ausgeschlossen:
```
*/.Trash*
*/.Trash*/*
*/.Trash*/**/*
*/.cache/*
*/lost+found/*
```
## Funktionsweise
### 1. Aufbau des find-Befehls

Das Skript erzeugt ein find-Kommando, das alle Ausschlüsse per -prune berücksichtigt und anschließend nur die restlichen Pfade mit -print0 ausgibt.

### 2. Sanitizing-Funktion

Die Funktion sanitize() verarbeitet Dateinamen zeichenweise:

ASCII (0x20–0x7E): erlaubt

UTF-8-gültig (via iconv geprüft): erlaubt

Andernfalls: Ersetzung durch _

### 3. Hauptschleife

basename extrahieren

Bereinigte Version erzeugen

Vergleichen

Bei Änderungen → entweder anzeigen (Dry-Run) oder umbenennen
