#!/usr/bin/env bash
# Baut yma.one/universe/ als verschlüsselte Seite.
# Aufruf:  STATICRYPT_PASSWORD='…' universe-src/build.sh
# Die echten Inhalte liegen in universe-src/inhalte.json (NICHT im Repository,
# siehe .gitignore). Fehlt die Datei, werden die Platzhalter verwendet.
set -euo pipefail
cd "$(dirname "$0")"
: "${STATICRYPT_PASSWORD:?Bitte STATICRYPT_PASSWORD setzen}"
INHALTE=inhalte.json; [ -f "$INHALTE" ] || INHALTE=inhalte.beispiel.json
TMP=$(mktemp -d)
node -e '
const fs=require("fs");
const html=fs.readFileSync("kalender.html","utf8");
const data=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
if(data.length!==24) throw new Error("Es müssen genau 24 Inhalte sein, gefunden: "+data.length);
fs.writeFileSync(process.argv[2]+"/index.html", html.replace("/*INHALTE*/[]", JSON.stringify(data)));
' "$INHALTE" "$TMP"
npx --yes staticrypt@3.5.4 "$TMP/index.html" \
  -c .staticrypt.json -d "$TMP/out" --short --remember 90 \
  -t passwort-vorlage.html \
  --template-title "yma universe" \
  --template-instructions "Gib hier Dein Passwort ein. Du findest es in Deiner Kaufbestätigung oder auf Deiner Geschenkkarte." \
  --template-placeholder "Passwort" \
  --template-button "Sterne öffnen ✨" \
  --template-remember "Auf diesem Gerät angemeldet bleiben" \
  --template-error "Das Passwort stimmt leider nicht." \
  --template-toggle-show "Passwort anzeigen" --template-toggle-hide "Passwort verbergen" \
  --template-color-primary "#db5a90" --template-color-secondary "#141f3d"
mkdir -p ../public/universe
cp "$TMP/out/index.html" ../public/universe/index.html
rm -rf "$TMP"
echo "Fertig: public/universe/index.html (Inhalte aus $INHALTE)"
