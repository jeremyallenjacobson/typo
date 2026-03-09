#!/bin/bash
# Build a navigable SVG site from a LaTeX document.
# Usage: ./build-svg-site.sh <name-without-extension>
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <name-without-extension>"
  exit 1
fi

NAME="$1"

if [ ! -f "${NAME}.tex" ]; then
  echo "Error: ${NAME}.tex not found"
  exit 1
fi

# Step 1: Compile PDF (two passes for TOC/refs)
echo "Compiling ${NAME}.tex ..."
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null
pdflatex -interaction=nonstopmode "${NAME}.tex" > /dev/null

# Step 2: Convert PDF to SVG (good fonts, no links)
echo "Converting to SVG ..."
dvisvgm --pdf --page=1- "${NAME}.pdf" > /dev/null 2>&1

# Step 3: Count pages
PAGES=$(ls -1 ${NAME}-*.svg 2>/dev/null | wc -l)
echo "Generated ${PAGES} pages."

# Step 4: Inject navigation links into each SVG
echo "Injecting navigation links ..."
for i in $(seq 1 $PAGES); do
  SVG="${NAME}-${i}.svg"

  # Read width and height from the <svg> tag (handles single quotes)
  W=$(grep -oP "width='\\K[^']+" "$SVG" | head -1 | sed 's/pt//')
  H=$(grep -oP "height='\\K[^']+" "$SVG" | head -1 | sed 's/pt//')

  # viewBox uses "0 -H W H" so Y coordinates are negative
  # Navigation position: 20pt from the bottom
  NAV_Y=-20
  CENTER_X=$(echo "$W / 2" | bc)
  PREV_X=$(echo "$CENTER_X - 50" | bc)
  NEXT_X=$(echo "$CENTER_X + 50" | bc)

  # Build the nav SVG snippet
  NAV='<g font-family="serif" font-size="10" fill="#0000CC">'

  if [ $i -gt 1 ]; then
    PREV=$((i - 1))
    NAV="${NAV}<a xlink:href=\"${NAME}-${PREV}.svg\"><text x=\"${PREV_X}\" y=\"${NAV_Y}\" text-anchor=\"middle\" style=\"cursor:pointer\">&lt; Prev</text></a>"
  fi

  NAV="${NAV}<text x=\"${CENTER_X}\" y=\"${NAV_Y}\" text-anchor=\"middle\" fill=\"#333\">${i} / ${PAGES}</text>"

  if [ $i -lt $PAGES ]; then
    NEXT=$((i + 1))
    NAV="${NAV}<a xlink:href=\"${NAME}-${NEXT}.svg\"><text x=\"${NEXT_X}\" y=\"${NAV_Y}\" text-anchor=\"middle\" style=\"cursor:pointer\">Next &gt;</text></a>"
  fi

  NAV="${NAV}</g>"

  # Insert before closing </svg> tag
  sed -i "s|</svg>|${NAV}</svg>|" "$SVG"

  echo "  ${SVG}: nav injected"
done

echo "Done."
