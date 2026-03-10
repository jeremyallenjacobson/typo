# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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
