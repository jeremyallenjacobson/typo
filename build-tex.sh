#!/bin/bash
# Build any .tex file: tex -> pdf -> svg, then open in Windows browser
# Usage: ./build-tex.sh <name>  (without .tex extension)
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <name>  (without .tex extension)"
  exit 1
fi

NAME="$1"

if [ ! -f "${NAME}.tex" ]; then
  echo "Error: ${NAME}.tex not found"
  exit 1
fi

echo "Compiling ${NAME}.tex ..."
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null

echo "Converting to SVG ..."
dvisvgm --pdf --page=1- "${NAME}.pdf" > /dev/null 2>&1

PAGES=$(ls -1 ${NAME}-*.svg 2>/dev/null | wc -l)

# Patch TOTAL in index.html if it exists
if [ -f "index.html" ]; then
  sed -i "s/const TOTAL = [0-9]*/const TOTAL = ${PAGES}/" index.html
  echo "Patched index.html: TOTAL = ${PAGES}"
fi

echo "Done. ${PAGES} SVG pages."
