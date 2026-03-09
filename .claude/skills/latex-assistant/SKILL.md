---
name: latex-assistant
description: Write, edit, and render LaTeX documents as SVG for viewing in the browser. Use when creating or modifying LaTeX documents.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# LaTeX Writing Assistant

Help the user write, edit, compile, and view LaTeX documents.

## Render pipeline

The best path on this WSL2 machine is:

```
pdflatex (x2 for TOC/refs) -> dvisvgm --pdf --page=1- -> wslview *.svg
```

Do NOT use these inferior paths:
- DVI -> SVG via dvisvgm (breaks word spacing with EB Garamond)
- DVI -> PS -> SVG via inkscape (worse font quality)

## Build and view

If a `build-tex.sh` script exists in the project, use it:
```bash
./build-tex.sh <name-without-extension>
```

Otherwise, run these steps:
```bash
pdflatex -interaction=nonstopmode FILE.tex > /dev/null
pdflatex -interaction=nonstopmode FILE.tex > /dev/null
dvisvgm --pdf --page=1- FILE.pdf > /dev/null 2>&1
for f in FILE-*.svg; do wslview "$f"; done
```

## Style conventions

Unless the user specifies otherwise, use this font and style setup:

```latex
% !TEX program = pdflatex
\documentclass[12pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{hyperref}
\usepackage{enumitem}
\usepackage{titlesec}
\usepackage{setspace}
\usepackage{xurl}
\setlist{nosep}
\titleformat{\section}{\large\bfseries}{}{0em}{}
\titlespacing*{\section}{0pt}{1ex}{0.6ex}
\usepackage{fourier}          % math
\usepackage{lmodern}           % mono
\renewcommand{\ttdefault}{lmtt}
\usepackage[lining]{ebgaramond} % body text
\usepackage{amsmath,amssymb,amsthm}
\usepackage{microtype}
```

## Writing rules

- No em dashes. Use commas, colons, or parentheses instead.
- No emojis.

## Workflow

1. Read the existing .tex file before editing.
2. Make the requested changes.
3. Compile and convert to SVG.
4. Open the SVGs with wslview.
