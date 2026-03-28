# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.3.0] - 2026-03-27

### Added
- LaTeX page numbers via fancyhdr: article title (scriptsize) upper-left, page number upper-right
- First page shows page number only (no title, since it's the title page)

### Changed
- Display: Apple Books Night mode (#b0b0b0 text on #121212 background) via SVG feColorMatrix filter, replacing CSS invert(0.88) hue-rotate(180deg)
- Mobile font reduced from 14pt to 12pt
- Text alignment: raggedright globally (no justification, no hyphenation)
- Mobile section headings use normalsize (was large)
- Mobile list indentation tightened to 1.2em
- Paragraph separation via parskip (was parindent)
- Removed table of contents (short article)
- Removed microtype, setspace, unicode-math, amsmath, amsthm packages (unused)
- Build script: fixed sed patterns to match `var TOTAL` (was `const TOTAL`)
- Build script: desktop page count glob uses `[0-9]*` to avoid matching mobile SVGs
- Updated article text with revised sections and new content

### Removed
- Popup page indicator (page numbers now rendered by LaTeX)
- Dark mode toggle references from SUM

## [1.2.1] - 2026-03-26

### Changed
- Viewer fills device screen: mobile SVGs expand to full viewport width, desktop SVGs expand to full viewport height, with the other dimension scaling proportionally via the SVG aspect ratio

## [1.2.0] - 2026-03-09

### Added
- Device-optimized builds: desktop (17pt, letter page) and mobile (11pt, 4×7in page, 0.2in margins)
- Build script produces both SVG sets (`NAME-N.svg` and `NAME-mN.svg`) in a single run
- Viewer auto-detects mobile portrait and loads mobile SVGs; switches to desktop SVGs in landscape
- Phone rotation swaps SVG sets automatically

### Changed
- Desktop font increased from 12pt `article` to 17pt `extarticle` for larger, more readable text
- LaTeX source uses `\ifdefined\mobileformat` conditional for font size and geometry
- PROCRV updated with device-optimized builds design and removed "no responsive layout" limitation

## [1.1.0] - 2026-03-09

### Changed
- Reorganized repository: source files in `src/`, deployed files in `site/`, documentation in `docs/`
- Build script (`src/build-tex.sh`) now resolves paths relative to its own location
- Deploy command targets `site/` instead of repo root
- Added author (Jeremy Jacobson) and date (March 9, 2026) to "Yet Another Theory of Programming"

### Removed
- Deleted `build-svg-site.sh` (abandoned navigation injection prototype)

## [1.0.0] - 2026-03-09

### Added
- Viewer (index.html) with page-flip navigation, dark mode, SVG preloading
- Build pipeline: pdflatex to dvisvgm with automatic TOTAL page count patching
- Mobile dark mode toggle (double-tap center of page)
- Direct page linking via URL hash
- Deployed first article "Yet Another Theory of Programming" at jeremyjacobson.dev/yatp/
- Cloudflare Pages hosting at jeremyjacobson.dev
- MIL-STD-498 documentation: PROCRV, SUM, Runbook
- LaTeX-rendered logo
- MIT license
