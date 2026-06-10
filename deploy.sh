#!/usr/bin/env bash
# Build + deploy de la app owner a Vercel (prod).
# Uso: ./deploy.sh
#
# Flujo: build local con Flutter → vercel build (genera .vercel/output) →
# vercel deploy --prebuilt (sube sin re-buildear).
# Vercel no tiene Flutter en sus builders, por eso usamos --prebuilt.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "  Fernecito Owner — Deploy a producción (Vercel)"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "▸ Paso 1/3: flutter pub get + build"
flutter pub get
# --no-tree-shake-icons: en el dashboard usamos muchos íconos pasados como
# parámetros de runtime, el tree-shaker los borra y quedan invisibles.
flutter build web --release --no-tree-shake-icons

echo ""
echo "▸ Paso 2/3: vercel build (empaqueta el output)"
# Generamos manualmente .vercel/output/ para no re-correr flutter en Vercel.
rm -rf .vercel/output
mkdir -p .vercel/output/static
cp -R build/web/. .vercel/output/static/

# ── Cache busting de Material Icons font ─────────────────────────────────────
# Flutter no agrega hash al nombre del font. Cuando algún deploy lo marcó
# como `immutable`, los browsers cachean el archivo viejo (tree-shaken) y
# nunca lo refrescan. Renombramos el font con timestamp para forzar refetch.
TS=$(date +%s)
NEW_NAME="MaterialIcons-Regular-${TS}.otf"
cd .vercel/output/static
if [ -f "assets/fonts/MaterialIcons-Regular.otf" ]; then
  mv "assets/fonts/MaterialIcons-Regular.otf" "assets/fonts/${NEW_NAME}"
  # Actualizar FontManifest.json
  if command -v python3 >/dev/null; then
    python3 -c "
import json
p = 'assets/FontManifest.json'
with open(p) as f: data = json.load(f)
for fam in data:
    for f in fam.get('fonts', []):
        if f.get('asset') == 'fonts/MaterialIcons-Regular.otf':
            f['asset'] = 'fonts/${NEW_NAME}'
with open(p, 'w') as f: json.dump(data, f)
"
  fi
  # Actualizar flutter_service_worker.js (busca el path como string)
  if [ -f "flutter_service_worker.js" ]; then
    sed -i.bak "s|assets/fonts/MaterialIcons-Regular.otf|assets/fonts/${NEW_NAME}|g" flutter_service_worker.js
    rm -f flutter_service_worker.js.bak
  fi
  echo "    → Font renombrado a ${NEW_NAME} (bust cache)"
fi

# ── Favicon cache busting (Chrome cachea favicons de forma agresiva) ─────────
cp "$SCRIPT_DIR/web/favicon.png" favicon.png
cp "$SCRIPT_DIR/web/icons/favicon-32.png" icons/favicon-32.png
cp "$SCRIPT_DIR/web/icons/favicon-48.png" icons/favicon-48.png
cp "$SCRIPT_DIR/web/icons/Icon-192.png" icons/Icon-192.png
cp "$SCRIPT_DIR/web/icons/Icon-512.png" icons/Icon-512.png

if command -v python3 >/dev/null; then
  python3 -c "
import re
p = 'index.html'
with open(p) as f:
    html = f.read()
html = re.sub(
    r'(href=\"(?:favicon\\.png|icons/[^\"]+))(?:\\?v=[0-9]+)?(\")',
    r'\\1?v=${TS}\\2',
    html,
)
with open(p, 'w') as f:
    f.write(html)
"
  echo "    → Favicons con ?v=${TS} (bust cache Chrome)"
fi
cd - > /dev/null

# config.json — cache MODERADO sin `immutable`.
# Flutter web no agrega hash a los nombres (main.dart.js, fonts, etc.),
# así que `immutable` puede cachear un bundle viejo "para siempre" en el browser.
# Estrategia: must-revalidate en archivos clave + max-age corto en assets.
cat > .vercel/output/config.json <<'EOF'
{
  "version": 3,
  "routes": [
    { "src": "/main\\.dart\\.js", "headers": { "cache-control": "public, max-age=0, must-revalidate" }, "continue": true },
    { "src": "/flutter_bootstrap\\.js", "headers": { "cache-control": "public, max-age=0, must-revalidate" }, "continue": true },
    { "src": "/flutter_service_worker\\.js", "headers": { "cache-control": "public, max-age=0, must-revalidate" }, "continue": true },
    { "src": "/index\\.html", "headers": { "cache-control": "public, max-age=0, must-revalidate", "clear-site-data": "\"cache\"" }, "continue": true },
    { "src": "/favicon\\.png", "headers": { "cache-control": "public, max-age=0, must-revalidate" }, "continue": true },
    { "src": "/icons/(.*)", "headers": { "cache-control": "public, max-age=0, must-revalidate" }, "continue": true },
    { "src": "/assets/(.*)", "headers": { "cache-control": "public, max-age=3600, must-revalidate" }, "continue": true },
    {
      "src": "/(.*)",
      "headers": {
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
        "referrer-policy": "strict-origin-when-cross-origin"
      },
      "continue": true
    },
    { "handle": "filesystem" },
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
EOF

echo ""
echo "▸ Paso 3/3: vercel deploy --prebuilt --prod"
vercel deploy --prebuilt --prod --yes

echo ""
echo "✅ Deploy completo."
echo "   Producción: https://fernecitoapp.online"
