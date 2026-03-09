# Runbook

## τύπο (typo): Author Workflow

This document describes how to write, build, test, and publish articles using the typo system.

## 1. Prerequisites

- pdflatex (TeX Live or equivalent)
- dvisvgm (version 2.13.1 or later)
- wrangler (Cloudflare CLI): `npm install -g wrangler`
- Authenticated with Cloudflare: `npx wrangler login`
- A Cloudflare Pages project (create with `npx wrangler pages project create <project-name> --production-branch main`)
- Optionally, a custom domain connected via Cloudflare dashboard

## 2. Writing a New Article

### 2.1 Use the latex-assistant skill

Load the `latex-assistant` skill in Amp to write and edit LaTeX. The skill renders LaTeX to SVG for in-browser preview during writing. This lets you iterate on content, fonts, and layout without leaving the editor.

### 2.2 LaTeX conventions

Follow the conventions established in `src/Y-A-T-P.tex`:

- `\pagestyle{empty}` — no headers, footers, or page numbers. The viewer handles navigation.
- `\usepackage[colorlinks=true, linkcolor=blue, citecolor=blue, urlcolor=blue]{hyperref}` — links appear blue even though they are not clickable in the SVG output. This is accepted per the book metaphor.
- Font stack: EB Garamond (text), Fourier (math), Latin Modern Mono (code).
- `\usepackage{microtype}` — for typographic refinement.

## 3. Building

From the project root:

```bash
src/build-tex.sh <name>
```

This runs:
1. `pdflatex` (two passes, for TOC and cross-references)
2. `dvisvgm --pdf --page=1-` (converts PDF to per-page SVGs)
3. Patches `TOTAL` in `site/index.html` to match the number of generated SVG pages

Output: `src/<name>-1.svg`, `src/<name>-2.svg`, etc.

## 4. Local Testing

**Do not deploy to test.** The Cloudflare free tier allows 500 deployments per month. Use local testing for all iteration on content, fonts, and layout.

Start a local server from the `site/` directory:

```bash
python3 -m http.server 8000 -d site
```

Then open in your browser:

```
http://localhost:8000/<article-directory>/
```

Test:
- Page navigation (arrow keys, click zones, swipe)
- Dark mode (`d` key on desktop, double-tap center on mobile)
- Direct page links (`http://localhost:8000/<article-directory>/#2`)
- Rapid flipping (hold arrow key)

When you change the `.tex` file, rebuild and refresh the browser:

```bash
src/build-tex.sh <name>
cp src/<name>-*.svg site/<article-directory>/
cp site/index.html site/<article-directory>/
```

## 5. Publishing a Release

Work on feature branches. Merge to `main` when ready. Deploy only on tagged releases.

```bash
# 1. Merge your feature branch to main
git checkout main
git merge feature/your-branch

# 2. Copy final build artifacts to the article directory
cp site/index.html site/<article-directory>/
cp src/<name>-*.svg site/<article-directory>/

# 3. Update CHANGELOG.md with what changed

# 4. Commit, tag, and push
git add -A
git commit -m "Release vX.Y.Z: description"
git tag vX.Y.Z
git push && git push --tags

# 5. Deploy
npx wrangler pages deploy site/ --project-name <project-name> --commit-dirty=true
```

**Discipline:** Do not deploy without tagging. The free tier allows 500 deployments per month. Local testing (Section 4) should catch everything before a release.

## 6. Adding a New Article

1. Write `src/<name>.tex` following the LaTeX conventions above.
2. Build: `src/build-tex.sh <name>`
3. Create the article directory: `mkdir -p site/<article-directory>`
4. Copy the viewer and SVGs: `cp site/index.html site/<article-directory>/` and `cp src/<name>-*.svg site/<article-directory>/`
5. Update the `NAME` constant in `site/<article-directory>/index.html` to match the filename prefix.
6. Test locally: `python3 -m http.server 8000 -d site` then open `http://localhost:8000/<article-directory>/`
7. Tag and deploy per Section 5.

## 7. Hosting

- **Hosting:** Cloudflare Pages (free tier), unlimited static asset bandwidth
- **Deployment limit:** 500/month on free tier (deploy only when publishing, not for testing)
- **Domain:** Register via Cloudflare Registrar, connect via dashboard under Workers & Pages → Custom domains
