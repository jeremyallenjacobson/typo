# <img src="logo.svg" alt="τύπο" height="40">

*From the Greek τύπο (accusative of τύπος), meaning "impression" or "mark" — the root of "typography."*

A system for publishing LaTeX documents as navigable, multi-page SVG files served from a CDN. The reader sees exactly what pdflatex produced — no browser font substitution, no framework, no compromise.

## Read

**[Yet Another Theory of Programming](https://jeremyjacobson.dev/yatp/)** — the first article published with this system.

## How it works

LaTeX source → pdflatex → dvisvgm → per-page SVGs → single-file HTML viewer → Cloudflare Pages.

The viewer is invisible infrastructure. The reader interacts with the page, not the software. Arrow keys, swipe, or tap the edges to turn pages. Press `d` for dark mode. Share `#3` to link directly to a page.

## License

MIT
