#!/usr/bin/env bash
# Baut yma.one/universe/ als verschlüsselte Seite.
# Aufruf:  STATICRYPT_PASSWORD='…' universe-src/build.sh
# Die echten Inhalte liegen in universe-src/inhalte.json (NICHT im Repository,
# siehe .gitignore). Fehlt die Datei, werden die Platzhalter verwendet.
set -euo pipefail
cd "$(dirname "$0")"
: "${STATICRYPT_PASSWORD:?Bitte STATICRYPT_PASSWORD setzen}"
INHALTE=${INHALTE:-inhalte.json}; [ -f "$INHALTE" ] || INHALTE=inhalte.beispiel.json
TMP=$(mktemp -d)
# Fotos: liegen in universe-src/fotos/ (NICHT im Repository, siehe .gitignore).
# Sie werden verkleinert, von Metadaten (z. B. GPS-Standort) befreit und
# als Teil der verschlüsselten Seite eingebettet – also ebenfalls geschützt.
IM=$(command -v magick || command -v convert || true)
node -e '
const fs=require("fs"), cp=require("child_process"), path=require("path");
const [inhalte, tmp, im] = process.argv.slice(1);
const html=fs.readFileSync("kalender.html","utf8");
let data=JSON.parse(fs.readFileSync(inhalte,"utf8"));
const sterne=Array.isArray(data)?data:data.sterne;
if(!sterne||sterne.length!==24) throw new Error("Es müssen genau 24 Sterne sein, gefunden: "+(sterne?sterne.length:0));
let kb=0;
for(const [i,s] of sterne.entries()){
  if(!s.foto) continue;
  const src=path.join("fotos",s.foto);
  if(!fs.existsSync(src)){ console.warn("Hinweis: Foto fehlt für Stern "+(i+1)+": "+src); delete s.foto; continue; }
  if(!im) throw new Error("Für die Fotos wird ImageMagick benötigt (magick oder convert).");
  const out=path.join(tmp,"f"+(i+1)+".jpg");
  const crop=s.fotoAusschnitt?["-crop",s.fotoAusschnitt,"+repage"]:[]; delete s.fotoAusschnitt;
  cp.execFileSync(im,[src,"-auto-orient",...crop,"-resize","720x480^","-gravity","center","-extent","720x480","-strip","-interlace","Plane","-quality","80",out]);
  const b=fs.readFileSync(out); kb+=b.length/1024;
  s.foto="data:image/jpeg;base64,"+b.toString("base64");
}
if(kb) console.log("Fotos eingebettet: "+Math.round(kb)+" KB");
fs.writeFileSync(tmp+"/index.html", html.replace("/*INHALTE*/[]", JSON.stringify(data).replace(/</g,"\\u003c")));
' "$INHALTE" "$TMP" "$IM"
npx --yes staticrypt@3.5.4 "$TMP/index.html" \
  -c .staticrypt.json -d "$TMP/out" --short --remember 90 \
  -t passwort-vorlage.html \
  --template-title "yma universe" \
  --template-instructions "Bitte gib hier Dein Passwort ein. Du findest es in Deiner Kaufbestätigung oder auf Deiner Geschenkkarte." \
  --template-placeholder "Passwort" \
  --template-button "Zeig mir meine Sterne" \
  --template-remember "Auf diesem Gerät angemeldet bleiben" \
  --template-error "Das Passwort stimmt leider nicht." \
  --template-toggle-show "Passwort anzeigen" --template-toggle-hide "Passwort verbergen" \
  --template-color-primary "#db5a90" --template-color-secondary "#141f3d"
mkdir -p ../public/universe
cp "$TMP/out/index.html" ../public/universe/index.html
rm -rf "$TMP"
echo "Fertig: public/universe/index.html (Inhalte aus $INHALTE)"
