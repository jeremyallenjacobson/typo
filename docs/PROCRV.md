# Pre-Requirements Operating Concept Rationale and Validation (PROCRV)

## typo (τύπο): SVG Document Publishing System

The name comes from the Greek τύπο (accusative of τύπος), meaning "impression" or "mark," the root of "typography." The system delivers the typographic impression as LaTeX set it, with no intermediary degrading the result. Everything that is not LaTeX-rendered is, by comparison, a typo.

## Section 1: Scope

The system publishes LaTeX documents as navigable, multi-page SVG files served from a CDN. It replaces HTML-based document publishing with pure SVG output rendered by LaTeX, so that all typography, layout, and link styling are controlled by the TeX source. The scope covers the build pipeline (TeX to SVG), inter-page navigation injection, and static file hosting.

## Section 2: References

- src/Y-A-T-P.tex (working document used as test case)
- site/index.html (single-page viewer, the reader experience)
- src/build-tex.sh (TeX to PDF to SVG build script)
- .claude/skills/latex-assistant/SKILL.md (latex-assistant skill)
- dvisvgm documentation (version 2.13.1)

## Section 3: Current System State

The system is complete and deployed. The first article, "Yet Another Theory of Programming," is live at https://jeremyjacobson.dev/yatp/.

1. **Build pipeline.** LaTeX source compiles to PDF via pdflatex (two passes). PDF converts to per-page SVGs via `dvisvgm --pdf --page=1-`. Fonts render correctly. Build completes in under 2 seconds for 3 pages. Each SVG is 2–4MB (fonts embedded per page). The build script (`src/build-tex.sh`) automatically patches the TOTAL page count in `site/index.html` after generating SVGs.

2. **Viewer (index.html).** A single HTML file provides the complete reading experience. The reader sees only the LaTeX-rendered page — the HTML is invisible infrastructure. Navigation is by arrow keys, swipe on mobile, or clicking the left/right edges of the page. Rapid key presses or taps advance multiple pages instantly, like fast-forwarding. A transient page indicator ("2 / 3") fades in briefly on each flip and disappears. Dark mode toggles with the `d` key via CSS `filter: invert(0.88) hue-rotate(180deg)`. URL hash (`#3`) enables direct links to any page.

3. **Performance model.** The current page loads first (~2–4MB, sub-second). Adjacent pages preload silently in the background. By the time the reader flips, the next page is already in memory. Every page turn is instant. Rapid flipping is instant. The preloader stays one or two pages ahead, with an additional lookahead for fast flippers.

4. **LaTeX source.** The `.tex` file uses `\pagestyle{empty}` — no headers, no footers, no page numbers. The page is pure content, like a printed book. The `fancyhdr`-based Prev/Next footer navigation was removed because the viewer handles all navigation and books do not have such affordances.

5. **Hosting.** Static files are deployed to Cloudflare Pages at https://jeremyjacobson.dev. The domain was registered through Cloudflare Registrar (~$12/year). Deployment is via `wrangler pages deploy`. Static asset serving is free and unlimited — no bandwidth charges at any scale. The free tier allows 500 deployments per month, which is more than sufficient since deployments occur only when the author publishes a new or updated article.

6. **Licensing.** The code is MIT-licensed for maximum distribution. The article content is copyrighted by the author. The strategic intent is open distribution: the code is freely available, the ideas are attributed to the author, and the domain serves as the author's professional platform.

7. **Device-optimized builds.** Each article is built twice from the same LaTeX source: a desktop build using standard letter-page geometry, and a mobile build using a page geometry proportioned to a phone screen in portrait (e.g., 3in × 5.3in). LaTeX controls the typography and layout for both targets — larger relative font, appropriate margins, natural line breaks. The build script produces both sets of SVGs (e.g., `Y-A-T-P-1.svg` and `Y-A-T-P-m1.svg`). The viewer detects the device and loads the correct set. On a phone in portrait, the mobile pages fill the screen. On a phone in landscape, the viewer switches to the desktop pages, which fit the wider aspect ratio. On desktop, the desktop pages are used. The book metaphor is preserved on all devices: no scroll, no zoom, just page flips. The desktop build also uses a larger base font size (14pt) for more comfortable reading on large screens.

**Resolved problems:**

- **Inter-page navigation.** Solved by the viewer approach. The failed `sed`-based SVG injection and the `fancyhdr` LaTeX footer were both abandoned. Navigation belongs to the viewer, not to the document.

- **Dark mode.** Solved by CSS filter on the viewer. No second LaTeX build needed.

- **Hosting.** Solved by Cloudflare Pages. Static files deploy with a single command. The custom domain `jeremyjacobson.dev` provides a permanent, professional URL.

- **Automated page count.** The build script now counts generated SVG files and patches the TOTAL constant in site/index.html automatically.

**Remaining limitations:**

- **No clickable links in SVGs.** The `dvisvgm --pdf` path strips all hyperlink annotations. Citation text appears blue but is not interactive. This is accepted: in a book, the reader flips to the bibliography. Fast page flipping makes this natural rather than deficient.

- **Dark mode inverts everything.** Including any embedded images. Acceptable for text-only documents.

## Section 4: Justification

The goal is a document format that loads instantly for readers, looks identical to the LaTeX PDF, and requires no web framework. SVG meets all three requirements: it is a single static file per page, renders natively in all browsers, and preserves vector text and layout exactly as pdflatex produced it.

Global hosting is resolved. The reader anywhere in the world experiences the same instant loading and page-flipping speed as local testing. The site is deployed on Cloudflare Pages CDN at https://jeremyjacobson.dev.

### Image quality investigation findings

The following approaches were tested independently against the same baseline, each changing exactly one variable to avoid path dependence. All testing was performed on localhost via `python3 -m http.server 8000 -d site`, with the user reviewing on both desktop browser and phone.

**Root cause.** The `dvisvgm --pdf` pipeline converts every font glyph into SVG `<path>` elements (vector outlines). These paths are geometrically accurate to the LaTeX output, which is the system's requirement. However, when the browser rasterizes these paths at screen resolution, it applies generic vector anti-aliasing rather than the specialized font hinting that native text renderers use. This produces slightly rough edges on thin features — serifs, italic strokes, and the tops of letters — especially at small sizes on phone screens.

**What was tested and ruled out:**

1. **Font size increase (extarticle 17pt → 20pt desktop, 11pt → 12pt mobile).** Desktop size improvement was approved by the lead engineer. Mobile was slightly improved but roughness remained. Note: `extarticle` only supports sizes 8, 9, 10, 11, 12, 14, 17, 20pt. Invalid sizes (e.g., 13pt, 19pt) silently fall back to 10pt with no warning.
2. **dvisvgm `--precision=6 --exact-bbox`.** No visible improvement. The default precision of 0 decimal points sounds coarse, but the glyph coordinate data from the PDF already has high precision. The roughness is not caused by insufficient coordinate precision.
3. **Removing `width`/`height` attributes from SVGs (keeping only `viewBox`).** No visible improvement. The hypothesis was that fixed `pt` dimensions caused the browser to rasterize at a lower resolution than the device pixel ratio. In practice, this made no difference.
4. **Switching viewer from `<img>` to `<object>` tag.** No visible improvement with path-based SVGs. The rendering pipeline for SVG paths is the same regardless of how the SVG is embedded.
5. **Alternative font (Libertinus Serif replacing EB Garamond).** Same roughness. This confirmed the problem is not font-specific — it is inherent to path-based glyph rendering.
6. **Inkscape PDF-to-SVG conversion (Cairo backend, `--export-text-to-path`).** Slightly different quality but not better overall. Cairo produces different path approximations than dvisvgm, but both suffer from the same fundamental issue: glyphs are paths, not text.
7. **DVI path with `--font-format=woff2` (embedded web fonts, `<text>` elements).** This produced SVGs with actual `<text>` elements and embedded WOFF2 fonts, enabling native browser font rendering. However, this approach **violates the core theory of the system**: the browser's font renderer makes its own decisions about hinting, kerning, and anti-aliasing, meaning the reader no longer sees exactly what LaTeX produced. Additionally, the DVI path exhibited the known word spacing issues with EB Garamond that were previously documented. This approach was rejected.

**Constraint reaffirmed.** The system's theory requires that LaTeX controls all typography and the browser merely presents the rendered output. Any approach that hands typography decisions back to the browser (web fonts, `<text>` elements, HTML text layers) violates this constraint. The path-based SVG approach is correct — it preserves exactly what LaTeX produced.

**Next steps to try.** Within the system's constraints, two untested approaches may reduce the perceived roughness:

1. **Increase mobile font size to 14pt** (the next valid `extarticle` step up from 11pt). Larger glyphs have more pixels per feature, making anti-aliasing artifacts less perceptible. Desktop at 20pt was already approved.
2. **dvisvgm `--zoom=2`** (or higher). This scales up the SVG coordinate space, giving the browser more geometric detail to work with during rasterization. The viewer CSS already constrains the displayed size via `max-height: 100dvh`, so the visual size would not change, but the internal resolution of the path data would increase.

These should be tested independently, then combined if both show improvement.

Future work beyond image quality may include a landing page at the domain root, additional articles, or mobile viewport refinements.

## Section 5: Concept

The system has three components:

**Build pipeline.** pdflatex (two passes) produces a PDF. `dvisvgm --pdf` converts each page to SVG. No post-processing of the SVG files is needed. The LaTeX source uses `\pagestyle{empty}` so pages are pure content with no navigation chrome.

**Viewer.** A single `site/index.html` file provides the reading experience. It loads SVG pages as images, displays one at a time, and handles all navigation. The viewer is invisible infrastructure: the reader sees only the LaTeX page. The hard constraint is that everything the reader sees must be rendered by LaTeX. No sidebars, no HTML chrome, no browser-styled UI elements. Navigation is through physical gestures — arrow keys, swipe, clicking the page edges — not through visible buttons or links. The metaphor is a printed book, not a web application. The viewer preloads adjacent pages so that every page turn is instant regardless of network conditions after the initial load.

**Dark mode.** CSS `filter: invert(0.88) hue-rotate(180deg)` applied to the page image, toggled by the `d` key. No second LaTeX build. The inversion ratio of 0.88 produces a warm dark background rather than pure black.

**Hosting.** Static files are deployed to Cloudflare Pages CDN at https://jeremyjacobson.dev. Articles live at subpaths (e.g., `/yatp/`). Each article directory contains its own `index.html` viewer and SVG pages. Deployment is via `wrangler pages deploy site/ --project-name jeremyjacobson-dev`. No server logic is needed.

## Section 6: Scenarios

**Reader visits the site.** Browser loads index.html. The viewer loads the first SVG page; the reader sees the LaTeX-rendered page fill the screen. While reading, adjacent pages preload silently. The reader presses the right arrow or swipes left; the next page appears instantly. The reader sees a brief "2 / 3" indicator that fades away. The reader sees blue citation text in the body but cannot click it — as with a book, they flip to the bibliography. The reader presses `d`; the page inverts to dark mode. They share the URL `jeremyjacobson.dev/yatp/#3` with a colleague, who opens it directly to page 3.

**Reader flips rapidly.** The reader holds the right arrow or taps rapidly. Each press advances one page instantly. The experience is like fast-forwarding: five taps, five pages. If the reader outruns the preloader (unlikely for adjacent pages), the next page appears as soon as it loads — typically within a fraction of a second.

**Author updates the document.** Author edits src/Y-A-T-P.tex, runs the build script (which auto-patches the TOTAL page count), tests locally, then deploys when satisfied. See docs/RUNBOOK.md for the complete author workflow.

## Section 7: Impacts

**What works.** Font rendering is correct. Page layout matches the PDF exactly. The build from TeX to SVG is fast (under 2 seconds for 3 pages). Page-to-page navigation is instant via the viewer. Dark mode works. Direct links to specific pages work. The local experience is complete.

**What is lost.** All hyperlinks embedded by hyperref (citations, TOC cross-references, external URLs) are stripped by `dvisvgm --pdf`. Citation text appears blue but is not clickable. This is a known limitation of dvisvgm 2.13.1 in PDF mode. This is accepted because the book metaphor does not require clickable citations — the reader flips to the bibliography.

**What remains.**

- **Image quality parity with print.** On a phone screen, rendered text exhibits slightly rough or pixelated edges, most visible on thin features such as italics, serifs, and the tops of letters. The goal is that a reader viewing the SVG on a phone cannot perceive any quality difference from a physical page of the same size. An investigation was conducted to isolate the root cause. See Section 4 (Justification) for the findings and the next steps to try.

## Section 8: Theory of the Proposed System

The architecture is intentionally minimal: TeX source, a build script, a viewer, and a folder of SVGs. The viewer contains a small amount of JavaScript and CSS, but these serve only to replicate what a physical book already provides — the ability to turn pages. The reader never interacts with the JavaScript or CSS. They interact with the page.

### Principles Discovered Through Building

The following principles emerged from the development process. They are not prescriptive rules; they are observations about what the system taught us about itself.

**1. The reader's experience is the program.** When the initial plan proposed fixing build plumbing (replacing `sed` with Python for SVG injection), the lead engineer rejected it: "I want us to focus on the core problem — how to share documents so that the webpage reader only reads beautifully formatted LaTeX, loading is instant, and navigation is fast as flipping to a page in paper." The theory of this program is not about the build pipeline. It is about what the reader sees and feels. Every decision flows from that.

**2. The metaphor is a printed book.** When the viewer was built with Prev/Next footer links, the lead engineer said: "books don't have that." The `fancyhdr` LaTeX navigation was removed. When the loss of clickable citations was raised, the response was: "with a book there is no such link — one would flip there, so if flip is super fast then we are ok and fitting with the theory of the program." A limitation that aligns with the metaphor is not a deficiency. It is a feature. The system does not need to be better than a book. It needs to be a book.

**3. Performance is the interaction model.** The lead engineer asked whether first render would be slow and subsequent pages fast, then said: "I would like it all to be fast — paginate if needed to keep every load fast." Speed is not an optimization to be applied later. It is the core interaction. The reader should not perceive a network. The sliding-window preloader exists because every page turn must feel like turning a physical page: zero latency, no loading indicator, no spinner. The page is simply there.

**4. Rapid interaction must compound.** The lead engineer asked for rapid flipping "like on YouTube where clicking multiple times fast forwards." Each tap or keypress must advance exactly one page, instantly, with no animation delay or debounce. The system must not impose its own tempo on the reader. If the reader wants to skim five pages in one second, the system must allow it.

**5. Invisible infrastructure.** The HTML, JavaScript, and CSS in the viewer are invisible. The reader does not know they exist. There are no buttons, no sidebars, no browser-styled UI elements. The page fills the screen. Dark mode is toggled by a single keypress with no settings panel. The page indicator appears briefly and vanishes. The system's infrastructure should be felt, not seen.

**6. The README is a pointer, not a summary.** The README links to the article and to the documentation. It does not re-explain or summarize what is already written in the docs. Each piece of knowledge lives in exactly one place: the operating concept in PROCRV, the author workflow in the Runbook, the reader guide in SUM. The README points the reader there. Duplicating content across documents creates drift and maintenance burden.

### Naur's Criteria Applied

Naur describes three properties that a programmer must possess to hold the theory of a program:

1. **Explain how the solution relates to real-world affairs.** The real-world affair is reading. A person wants to read a beautifully typeset document in a browser as naturally as they would read a printed book. The pipeline exists to deliver that experience: LaTeX controls the typography, SVG preserves it exactly, and the viewer provides the page-turning gesture. Every component exists to serve the reader, not the author or the build system.

2. **Explain what each part of the program text does and why.** The LaTeX source uses `\pagestyle{empty}` because navigation is the viewer's job, not the document's. The viewer uses `<img>` tags for SVG pages because they are cacheable and preloadable. The preloader fetches `n+1`, `n-1`, and `n+2` because adjacent pages must be instant and rapid flippers need lookahead. The CSS filter uses `invert(0.88)` rather than `invert(1)` because pure black backgrounds are harsh. The click zones are 25% of the viewport width because the reader should be able to tap near the edge without precise aiming. Each decision is documented and reasoned.

3. **Respond constructively to demands for modification.** When the `sed`-based injection failed, the theory did not prescribe a specific fix. It prescribed the constraint: the reader must see only LaTeX-rendered content, and navigation must be instant. The viewer approach satisfied both constraints and also resolved dark mode, direct page linking, and rapid flipping — problems that SVG injection could not have addressed. When the lead engineer rejected the Prev/Next footer, the theory told us why: it violated the book metaphor. The theory enables us to evaluate any future change by asking: does this serve the reader's experience of turning pages in a beautifully typeset book?

### Summary of Advantages

- Instant rendering. SVG is parsed and painted by the browser with no layout engine, no font loading, no framework initialization.
- Typography controlled entirely by LaTeX. The reader sees exactly what pdflatex produced. No browser font substitution.
- Instant page turning. Preloaded adjacent pages swap in a single frame. Rapid flipping works without debounce.
- Dark mode. One keypress, no settings, no second build.
- Direct linking. URL hash enables sharing links to specific pages.
- Minimal hosting. Static files on a CDN. No server, no database, no framework.
- Minimal build. pdflatex + dvisvgm. No npm, no bundler, no static site generator.
- The author writes only LaTeX.

### Summary of Limitations

- No clickable hyperlinks in the SVG body. dvisvgm 2.13.1 in PDF mode strips all PDF annotations. Citation text appears blue but is not interactive. Accepted: the reader flips to the bibliography.
- No text selection or search within the SVG in most browsers. The text is rendered as positioned glyphs, not reflowable content.
- Dark mode inverts everything, including any embedded images. Acceptable for text-only documents.
- Two SVG sets per article increases storage. Accepted: SVGs are static files on a free-bandwidth CDN, and the viewer only loads the set it needs.

### Alternatives and Tradeoffs Considered

- **HTML output via make4ht.** Produces searchable, reflowable HTML with working links. Loses the LaTeX typography entirely. Browser fonts replace EB Garamond. Rejected because the core requirement is that the reader sees LaTeX-rendered output.
- **PDF served directly.** Preserves all links and typography. Requires a PDF viewer (browser built-in or external). Rendering speed depends on the viewer. No dark mode without a separate build. PDFs cannot be styled or wrapped by a thin HTML page. Remains a viable fallback.
- **DVI-to-SVG path (without --pdf).** Preserves hyperlinks from the hypertex driver. Destroys word spacing with EB Garamond. Rejected after testing. Re-tested with `--font-format=woff2` to embed actual web fonts and produce `<text>` elements for native browser rendering. Text was crisper but spacing was worse than the PDF path, and the approach violates the core constraint that LaTeX — not the browser — controls all typography. Rejected again.
- **SVG injection (sed/Python post-processor).** Attempted to inject `<a>` navigation elements directly into SVG files. The `sed` approach failed on XML entities. The approach was abandoned entirely in favor of the viewer, which solved navigation plus dark mode, direct linking, and rapid flipping — none of which injection could provide.

### Changes Considered but Not Included

- **Clickable citation links via PDF annotation extraction.** Tools like `pdftohtml -xml` or `mutool` could extract link coordinates from the PDF and inject corresponding `<a>` elements into the SVG. Not pursued because the book metaphor does not require it, and fast page flipping makes manual navigation to the bibliography natural.
- **Second LaTeX build with inverted colors for dark mode.** Would produce true dark-mode SVGs without CSS filter artifacts on images. Not needed for text-only documents where the CSS filter works well.
- **Automated TOTAL page count detection.** Implemented. The build script now counts SVG files and patches index.html automatically.
