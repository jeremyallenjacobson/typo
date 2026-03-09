# <img src="site/logo.svg" alt="τύπο" height="40">

*From the Greek τύπο (accusative of τύπος), meaning "impression" or "mark," the root of "typography." The system delivers the typographic impression as LaTeX set it, with no intermediary degrading the result. Everything that is not LaTeX-rendered is, by comparison, like looking at a document with a typo.*

## Below is an instance of what this style of publishing looks like

**[Yet Another Theory of Programming](https://jeremyjacobson.dev/yatp/)**

## How It Works

LaTeX source compiles to PDF via `pdflatex`, then converts to per-page SVGs via `dvisvgm`. A minimal HTML viewer displays one SVG page at a time with instant page-flipping, dark mode, and direct page links. The reader sees only what LaTeX rendered: no browser fonts, no framework, no visible UI chrome.

## Repository Structure

```
src/              LaTeX source files and build script
site/             Deployed to Cloudflare Pages (the only directory that gets deployed)
  yatp/           "Yet Another Theory of Programming" article (SVGs + viewer)
  index.html      Viewer template
  logo.svg        LaTeX-rendered logo
docs/             MIL-STD-498 documentation
  PROCRV.md       Operating concept, rationale, and system theory
  SCOM.md         Author workflow (write, build, test, publish)
  SUM.md          Reader guide (navigation, dark mode, direct links)
```

## Build and Deploy

Build from the repo root:

```bash
src/build-tex.sh Y-A-T-P
cp src/Y-A-T-P-*.svg site/yatp/
```

Deploy (only on tagged releases):

```bash
npx wrangler pages deploy site/ --project-name jeremyjacobson-dev --commit-dirty=true
```

See [docs/SCOM.md](docs/SCOM.md) for the complete author workflow.

## License

MIT
