#!/bin/bash
# Build a .tex file in src/: lualatex -> dvi -> svg (desktop + mobile)
# Uses LuaLaTeX DVI pipeline with woff2 fonts (no autohint — preserves
# professional TrueType hinting from .ttf files loaded via fontspec)
# Usage: src/build-tex.sh <name>  (without .tex extension)
# Run from the repo root: src/build-tex.sh Y-A-T-P
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <name>  (without .tex extension)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAME="$1"

if [ ! -f "${SCRIPT_DIR}/${NAME}.tex" ]; then
  echo "Error: ${SCRIPT_DIR}/${NAME}.tex not found"
  exit 1
fi

cd "$SCRIPT_DIR"

# --- Desktop build ---
echo "Compiling ${NAME}.tex (desktop) ..."
lualatex --output-format=dvi -interaction=nonstopmode "${NAME}.tex" > /dev/null || true
lualatex --output-format=dvi -interaction=nonstopmode "${NAME}.tex" > /dev/null || true

if [ ! -f "${NAME}.dvi" ]; then echo "Error: lualatex failed to produce ${NAME}.dvi"; exit 1; fi

echo "Converting to SVG (desktop) ..."
dvisvgm --font-format=woff2 --bbox=papersize --precision=6 --page=1- "${NAME}.dvi" > /dev/null 2>&1

PAGES=$(ls -1 ${NAME}-[0-9]*.svg 2>/dev/null | wc -l)

# --- Mobile build ---
# Create a wrapper that overrides geometry for mobile page dimensions
MOBILE_TEX="${NAME}-mobile.tex"
cat > "$MOBILE_TEX" <<EOF
\newcommand{\mobileformat}{}
\PassOptionsToPackage{paperwidth=4in,paperheight=7in}{geometry}
\input{${NAME}.tex}
EOF

echo "Compiling ${NAME}.tex (mobile) ..."
lualatex --output-format=dvi -interaction=nonstopmode -jobname="${NAME}-mobile" "${MOBILE_TEX}" > /dev/null || true
lualatex --output-format=dvi -interaction=nonstopmode -jobname="${NAME}-mobile" "${MOBILE_TEX}" > /dev/null || true

if [ ! -f "${NAME}-mobile.dvi" ]; then echo "Error: lualatex failed to produce ${NAME}-mobile.dvi"; exit 1; fi

echo "Converting to SVG (mobile) ..."
dvisvgm --font-format=woff2 --bbox=papersize --precision=6 --page=1- "${NAME}-mobile.dvi" > /dev/null 2>&1

# Rename mobile SVGs: Y-A-T-P-mobile-01.svg -> Y-A-T-P-m1.svg
for f in ${NAME}-mobile-*.svg; do
  # Extract number and strip leading zeros
  num=$(echo "$f" | sed "s/${NAME}-mobile-0*\([0-9][0-9]*\)\.svg/\1/")
  mv "$f" "${NAME}-m${num}.svg"
done

MOBILE_PAGES=$(ls -1 ${NAME}-m*.svg 2>/dev/null | wc -l)

# Clean up mobile wrapper and build artifacts
rm -f "$MOBILE_TEX" "${NAME}-mobile.dvi" "${NAME}-mobile.aux" "${NAME}-mobile.log" \
      "${NAME}-mobile.out" "${NAME}-mobile.toc"

# Patch TOTAL and MOBILE_TOTAL in site/index.html if it exists
SITE_INDEX="${SCRIPT_DIR}/../site/index.html"
if [ -f "$SITE_INDEX" ]; then
  sed -i "s/var TOTAL = [0-9]*/var TOTAL = ${PAGES}/" "$SITE_INDEX"
  sed -i "s/var MOBILE_TOTAL = [0-9]*/var MOBILE_TOTAL = ${MOBILE_PAGES}/" "$SITE_INDEX"
  echo "Patched site/index.html: TOTAL = ${PAGES}, MOBILE_TOTAL = ${MOBILE_PAGES}"
fi

echo "Done. ${PAGES} desktop SVG pages, ${MOBILE_PAGES} mobile SVG pages."
