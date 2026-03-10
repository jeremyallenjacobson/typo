#!/bin/bash
# Build a .tex file in src/: tex -> pdf -> svg (desktop + mobile)
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
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null

echo "Converting to SVG (desktop) ..."
dvisvgm --pdf --page=1- "${NAME}.pdf" > /dev/null 2>&1

PAGES=$(ls -1 ${NAME}-*.svg 2>/dev/null | wc -l)

# --- Mobile build ---
# Create a wrapper that overrides geometry for mobile page dimensions
MOBILE_TEX="${NAME}-mobile.tex"
cat > "$MOBILE_TEX" <<EOF
\newcommand{\mobileformat}{}
\PassOptionsToPackage{paperwidth=4in,paperheight=7in}{geometry}
\input{${NAME}.tex}
EOF

echo "Compiling ${NAME}.tex (mobile) ..."
pdflatex -interaction=nonstopmode -jobname="${NAME}-mobile" "${MOBILE_TEX}" > /dev/null
pdflatex -interaction=nonstopmode -jobname="${NAME}-mobile" "${MOBILE_TEX}" > /dev/null

echo "Converting to SVG (mobile) ..."
dvisvgm --pdf --page=1- "${NAME}-mobile.pdf" > /dev/null 2>&1

# Rename mobile SVGs: Y-A-T-P-mobile-01.svg -> Y-A-T-P-m1.svg
for f in ${NAME}-mobile-*.svg; do
  # Extract number and strip leading zeros
  num=$(echo "$f" | sed "s/${NAME}-mobile-0*\([0-9][0-9]*\)\.svg/\1/")
  mv "$f" "${NAME}-m${num}.svg"
done

MOBILE_PAGES=$(ls -1 ${NAME}-m*.svg 2>/dev/null | wc -l)

# Clean up mobile wrapper and build artifacts
rm -f "$MOBILE_TEX" "${NAME}-mobile.pdf" "${NAME}-mobile.aux" "${NAME}-mobile.log" \
      "${NAME}-mobile.out" "${NAME}-mobile.toc"

# Patch TOTAL and MOBILE_TOTAL in site/index.html if it exists
SITE_INDEX="${SCRIPT_DIR}/../site/index.html"
if [ -f "$SITE_INDEX" ]; then
  sed -i "s/const TOTAL = [0-9]*/const TOTAL = ${PAGES}/" "$SITE_INDEX"
  sed -i "s/const MOBILE_TOTAL = [0-9]*/const MOBILE_TOTAL = ${MOBILE_PAGES}/" "$SITE_INDEX"
  echo "Patched site/index.html: TOTAL = ${PAGES}, MOBILE_TOTAL = ${MOBILE_PAGES}"
fi

echo "Done. ${PAGES} desktop SVG pages, ${MOBILE_PAGES} mobile SVG pages."
