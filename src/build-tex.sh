#!/bin/bash
# Build a .tex file in src/: tex -> pdf -> svg
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

echo "Compiling ${NAME}.tex ..."
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null

echo "Converting to SVG ..."
dvisvgm --pdf --page=1- "${NAME}.pdf" > /dev/null 2>&1

PAGES=$(ls -1 ${NAME}-*.svg 2>/dev/null | wc -l)

# Patch TOTAL in site/index.html if it exists
SITE_INDEX="${SCRIPT_DIR}/../site/index.html"
if [ -f "$SITE_INDEX" ]; then
  sed -i "s/const TOTAL = [0-9]*/const TOTAL = ${PAGES}/" "$SITE_INDEX"
  echo "Patched site/index.html: TOTAL = ${PAGES}"
fi

echo "Done. ${PAGES} SVG pages."
