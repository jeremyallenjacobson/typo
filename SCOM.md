# Software User Manual (SUM)

## τύπο (typo): Author Workflow

This document describes how to write, build, test, and publish articles using the typo system.

## 1. Prerequisites

- pdflatex (TeX Live or equivalent)
- dvisvgm (version 2.13.1 or later)
- wrangler (Cloudflare CLI): `npm install -g wrangler`
- Authenticated with Cloudflare: `npx wrangler login`

## 2. Writing a New Article

### 2.1 Use the latex-assistant skill

Load the `latex-assistant` skill in Amp to write and edit LaTeX. The skill renders LaTeX to SVG for in-browser preview during writing. This lets you iterate on content, fonts, and layout without leaving the editor.

### 2.2 LaTeX conventions

Follow the conventions established in `Y-A-T-P.tex`:

- `\pagestyle{empty}` — no headers, footers, or page numbers. The viewer handles navigation.
- `\usepackage[colorlinks=true, linkcolor=blue, citecolor=blue, urlcolor=blue]{hyperref}` — links appear blue even though they are not clickable in the SVG output. This is accepted per the book metaphor.
- Font stack: EB Garamond (text), Fourier (math), Latin Modern Mono (code).
- `\usepackage{microtype}` — for typographic refinement.

## 3. Building

From the project root:

```bash
./build-tex.sh Y-A-T-P
```

This runs:
1. `pdflatex` (two passes, for TOC and cross-references)
2. `dvisvgm --pdf --page=1-` (converts PDF to per-page SVGs)
3. Patches `TOTAL` in `index.html` to match the number of generated SVG pages

Output: `Y-A-T-P-1.svg`, `Y-A-T-P-2.svg`, etc.

## 4. Local Testing

**Do not deploy to test.** The Cloudflare free tier allows 500 deployments per month. Use local testing for all iteration on content, fonts, and layout.

Start a local server from the project root:

```bash
python3 -m http.server 8000
```

Then open in your browser:

```
http://localhost:8000/yatp/
```

Test:
- Page navigation (arrow keys, click zones, swipe)
- Dark mode (`d` key)
- Direct page links (`http://localhost:8000/yatp/#2`)
- Rapid flipping (hold arrow key)

When you change the `.tex` file, rebuild and refresh the browser:

```bash
./build-tex.sh Y-A-T-P
cp Y-A-T-P-*.svg yatp/
cp index.html yatp/
```

## 5. Publishing a Release

Work on feature branches. Merge to `main` when ready. Deploy only on tagged releases.

```bash
# 1. Merge your feature branch to main
git checkout main
git merge feature/your-branch

# 2. Copy final build artifacts to the article directory
cp index.html yatp/
cp Y-A-T-P-*.svg yatp/

# 3. Update CHANGELOG.md with what changed

# 4. Commit, tag, and push
git add -A
git commit -m "Release v1.x.0: description"
git tag v1.x.0
git push && git push --tags

# 5. Deploy
npx wrangler pages deploy . --project-name jeremyjacobson-dev --commit-dirty=true
```

The article is live at https://jeremyjacobson.dev/yatp/ within seconds.

**Discipline:** Do not deploy without tagging. The free tier allows 500 deployments per month. Local testing (Section 4) should catch everything before a release.

## 6. Adding a New Article

To publish a second article (e.g., "My Next Article"):

1. Write `my-next-article.tex` following the LaTeX conventions above.
2. Build: `./build-tex.sh my-next-article`
3. Create the article directory: `mkdir -p my-next-article`
4. Copy the viewer and SVGs: `cp index.html my-next-article/` and `cp my-next-article-*.svg my-next-article/`
5. Update the `NAME` constant in `my-next-article/index.html` to match the new filename prefix.
6. Test locally: `python3 -m http.server 8000` → `http://localhost:8000/my-next-article/`
7. Deploy: `npx wrangler pages deploy . --project-name jeremyjacobson-dev --commit-dirty=true`
8. Live at: `https://jeremyjacobson.dev/my-next-article/`

## 7. Domain and Hosting

- **Domain:** `jeremyjacobson.dev` — registered via Cloudflare Registrar (~$12/year)
- **Hosting:** Cloudflare Pages (free tier) — unlimited static asset bandwidth
- **Project name:** `jeremyjacobson-dev`
- **Deployment limit:** 500/month on free tier (deploy only when publishing, not for testing)
- **Custom domain:** Connected via Cloudflare dashboard → Workers & Pages → Custom domains
