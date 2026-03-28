# Pre-Requirements Operating Concept Rationale and Validation (PROCRV)

## typo (τύπο): SVG Document Publishing System

The name comes from the Greek τύπο (accusative of τύπος), meaning "impression" or "mark," the root of "typography." The system delivers the typographic impression as LaTeX set it, with no intermediary degrading the result. Everything that is not LaTeX-rendered is, by comparison, a typo.

## Section 1: Scope

The system publishes LaTeX documents as navigable, multi-page SVG files served from a CDN. It replaces HTML-based document publishing with pure SVG output rendered by LaTeX, so that all typography and layout are controlled by the TeX source. The scope covers the build pipeline (LuaLaTeX to DVI to SVG), the viewer, and static file hosting.

## Section 2: References

- src/Y-A-T-P.tex (working document used as test case)
- site/index.html (single-page viewer, the reader experience)
- src/build-tex.sh (LuaLaTeX to DVI to SVG build script)
- .claude/skills/latex-assistant/SKILL.md (latex-assistant skill for authoring)
- dvisvgm documentation (version 3.6+)
- Martin Gieseking's dvisvgm FAQ on font rendering for web display
- Donald Knuth, *The METAFONTbook* (1986) — the philosophy of device-adaptive typography
- C.R. Jakobsen, J. Sutherland, K. Johnson, "Scrum and CMMI Level 5: The Magic Potion for Code Warriors" — combining XP principles with rigorous engineering standards

## Section 3: Current System State

The system is complete and deployed. The first article, "Yet Another Theory of Programming," is live at https://jeremyjacobson.dev/yatp/.

1. **Build pipeline.** LaTeX source compiles to DVI via `lualatex --output-format=dvi` (two passes). LuaLaTeX loads fonts from system `.ttf` files via `fontspec`, preserving professional TrueType hinting. DVI converts to per-page SVGs via `dvisvgm --font-format=woff2 --bbox=papersize --precision=6 --page=1-` — no `autohint` flag, so the professional hinting in the `.ttf` files is preserved rather than overridden by dvisvgm's generic autohinter. The dvisvgm flags: `--precision=6` sets the number of decimal places for SVG coordinates (6 provides sub-pixel accuracy for glyph positioning); `--page=1-` processes all pages in the DVI file, producing one SVG per page (e.g., `Y-A-T-P-1.svg`, `Y-A-T-P-2.svg`, etc.); `--bbox=papersize` sets the SVG viewBox to the page dimensions from the LaTeX geometry. The build script (`src/build-tex.sh`) automatically patches the TOTAL page count in `site/index.html` after generating SVGs.

2. **Viewer (index.html).** A single HTML file provides the complete reading experience. The reader sees only the LaTeX-rendered page — the HTML is invisible infrastructure. The display is always dark: text at #b0b0b0 on background #121212 via an SVG feColorMatrix filter (Apple Books Night mode). There is no light mode and no toggle — books do not have display options. The SVG page fills the device screen: on mobile, it expands to full viewport width (height scales proportionally); on desktop, it expands to full viewport height (width scales proportionally). Navigation is by arrow keys on desktop, or tapping the left/right halves of the screen on mobile. Holding a tap flips pages rapidly. On mobile, the viewer is portrait-only; landscape shows a "Rotate to portrait" message, because books do not have orientations. Page numbers are rendered by LaTeX in the document itself. URL hash (`#3`) enables direct links to any page.

3. **Performance model.** The current page loads first (~15–25KB per page with the DVI+woff2 pipeline, sub-second). Adjacent pages preload silently in the background. By the time the reader flips, the next page is already in memory. Every page turn is instant. Rapid flipping is instant. The preloader stays one or two pages ahead, with an additional lookahead for fast flippers.

4. **LaTeX source.** The `.tex` file uses `fancyhdr` with the article title (scriptsize) in the upper-left header and page number (scriptsize) in the upper-right header. The first page omits the title (page number only). The table of contents was removed (short article). The `fancyhdr`-based Prev/Next footer navigation was removed because the viewer handles all navigation and books do not have such affordances.

5. **Hosting.** Static files are deployed to Cloudflare Pages at https://jeremyjacobson.dev. The domain was registered through Cloudflare Registrar (~$12/year). Deployment is via `wrangler pages deploy`. Static asset serving is free and unlimited — no bandwidth charges at any scale. The free tier allows 500 deployments per month, which is more than sufficient since deployments occur only when the author publishes a new or updated article.

6. **Licensing.** The code is MIT-licensed for maximum distribution. The article content is copyrighted by the author. The strategic intent is open distribution: the code is freely available, the ideas are attributed to the author, and the domain serves as the author's professional platform.

7. **Device-optimized builds.** Each article is built twice from the same LaTeX source: a desktop build using standard letter-page geometry (20pt), and a mobile build using a page geometry proportioned to a phone screen in portrait (4in × 7in, 12pt). The mobile build uses `\raggedright` (left-aligned, no justification) with `\setlist{nosep, leftmargin=1.2em}` for tighter list indentation, and section headings use `\normalsize\bfseries` instead of `\large\bfseries`. LaTeX controls the typography and layout for both targets — appropriate font size, margins, and natural line breaks. The build script produces both sets of SVGs (e.g., `Y-A-T-P-1.svg` and `Y-A-T-P-m1.svg`). The viewer detects the device and loads the correct set. On mobile, the viewer is portrait-only — landscape displays a "Rotate to portrait" message. Books do not have orientations. No scroll, no zoom, just page flips.

8. **Font selection.** The system uses Gentium Book Plus, a calligraphic oldstyle serif loaded via `fontspec` from system `.ttf` files. Gentium Book Plus provides professional TrueType hinting — detailed instructions for aligning stems and baselines to the pixel grid at every size. This follows Knuth's philosophy: METAFONT generated device-specific bitmaps tuned to each printer's resolution; TrueType hinting is the modern equivalent, tuning outlines to each screen's pixel grid. The LuaLaTeX pipeline loads `.ttf` files directly, so the professional hinting is preserved end-to-end through to the browser's font rasterizer. No `hyperref` package is used — links are not functional in SVG output, and books do not change print color for references.

**Resolved problems:**

- **Inter-page navigation.** Solved by the viewer approach. The failed `sed`-based SVG injection and the `fancyhdr` LaTeX footer were both abandoned. Navigation belongs to the viewer, not to the document.

- **Display.** Always dark — text at #b0b0b0 on background #121212 via an SVG feColorMatrix filter (Apple Books Night mode). No toggle, no options. Books do not have display settings.

- **Hosting.** Solved by Cloudflare Pages. Static files deploy with a single command. The custom domain `jeremyjacobson.dev` provides a permanent, professional URL.

- **Automated page count.** The build script now counts generated SVG files and patches the TOTAL constant in site/index.html automatically.

**Remaining limitations:**

- **Font selection is constrained to fonts with professional TrueType hinting.** The LuaLaTeX pipeline loads `.ttf` files directly via `fontspec`, preserving professional hinting. Fonts with only CFF/PostScript stem hints (EB Garamond, Latin Modern, STIX Two, TeX Gyre families) do not provide the pixel-grid alignment instructions needed for crisp screen rendering. The system requires fonts with full TrueType hinting tables (fpgm, prep, cvt, gasp). Gentium Book Plus is the current approved font.

## Section 4: Justification

The goal is a document format that loads instantly for readers, is as comfortable to read as printed paper — or better — and requires no web framework. SVG meets all three requirements: it is a single static file per page, renders natively in all browsers, and preserves the typographic layout determined by LaTeX. With professional TrueType hinting adapted to the reader's screen, the on-screen rendering can exceed print quality at high PPI.

Global hosting is resolved. The reader anywhere in the world experiences the same instant loading and page-flipping speed as local testing. The site is deployed on Cloudflare Pages CDN at https://jeremyjacobson.dev.

### Image quality investigation findings

The following approaches were tested independently against the same baseline, each changing exactly one variable to avoid path dependence. All testing was performed on localhost via `python3 -m http.server 8000 -d site`, with the user reviewing on both desktop browser and phone.

**Phase 1: Path-based rendering (dvisvgm --pdf pipeline).**

The `dvisvgm --pdf` pipeline converts every font glyph into SVG `<path>` elements (vector outlines). These paths are geometrically accurate to the LaTeX output. However, when the browser rasterizes these paths at screen resolution, it applies generic vector anti-aliasing rather than the specialized font hinting that native text renderers use. This produces slightly rough edges on thin features — serifs, italic strokes, and the tops of letters — especially at small sizes on phone screens.

What was tested and ruled out within the path-based pipeline:

1. **Font size increase (extarticle 17pt → 20pt desktop, 11pt → 12pt mobile).** Desktop size improvement was approved by the lead engineer. Mobile was slightly improved but roughness remained. Note: `extarticle` only supports sizes 8, 9, 10, 11, 12, 14, 17, 20pt. Invalid sizes (e.g., 13pt, 19pt) silently fall back to 10pt with no warning.
2. **dvisvgm `--precision=6 --exact-bbox`.** No visible improvement. The default precision of 0 decimal points sounds coarse, but the glyph coordinate data from the PDF already has high precision. The roughness is not caused by insufficient coordinate precision.
3. **Removing `width`/`height` attributes from SVGs (keeping only `viewBox`).** No visible improvement. The hypothesis was that fixed `pt` dimensions caused the browser to rasterize at a lower resolution than the device pixel ratio. In practice, this made no difference.
4. **Switching viewer from `<img>` to `<object>` tag.** No visible improvement with path-based SVGs. The rendering pipeline for SVG paths is the same regardless of how the SVG is embedded.
5. **Alternative font (Libertinus Serif replacing EB Garamond).** Same roughness. This confirmed the problem is not font-specific — it is inherent to path-based glyph rendering.
6. **Inkscape PDF-to-SVG conversion (Cairo backend, `--export-text-to-path`).** Slightly different quality but not better overall. Cairo produces different path approximations than dvisvgm, but both suffer from the same fundamental issue: glyphs are paths, not text.

**Phase 2: DVI pipeline with embedded web fonts.**

The DVI pipeline with `--font-format=woff2,autohint` was initially rejected on the grounds that it "hands typography decisions back to the browser." This was a misunderstanding of what the browser actually controls.

In the DVI+woff2 pipeline, LaTeX still controls all typographic decisions: font selection, font size, line breaking, word spacing, kerning, paragraph layout, justification, and page breaks. The DVI file encodes the exact position of every glyph on the page. dvisvgm translates those positions into SVG `<text>` elements with precise coordinates. The browser's role is limited to rasterizing — converting the vector outlines of each glyph into pixels at the device's resolution. This is the same role that a laser printer plays when it rasterizes a DVI file, and no one would say that a laser printer "controls the typography."

What the browser's font rasterizer does control is **hinting**: the pixel-level adjustment of glyph outlines to align with the screen's pixel grid. This is precisely the function that Knuth designed METAFONT to perform. METAFONT generated device-specific bitmaps tuned to each printer's resolution. TrueType hinting is the modern equivalent — instructions embedded in the font that tell the rasterizer how to align stems, baselines, and curves to the pixel grid at each size. The DVI+woff2 pipeline allows these hinting instructions to take effect. The path-based pipeline destroys them by converting glyphs to raw geometry.

Martin Gieseking, the creator of dvisvgm, explicitly recommends the DVI pipeline with `--font-format=woff2,autohint` for web display. From his documentation and FAQ: "unhinted fonts might look bad on low-resolution devices."

**Testing methodology caveat.** Earlier testing was conducted in Chrome DevTools device emulation, which emulates the viewport dimensions (e.g., 430×932 for iPhone 14 Pro Max) but renders at the monitor's native DPI (~96–110 PPI). This is roughly 4× less than an actual iPhone's 460 PPI display. At 96 PPI, 14pt text has only ~21 physical pixels per em-height, where roughness is highly visible and hinting matters most. At 460 PPI, the same text has ~84 physical pixels per em — enough for crisp rendering even without hinting. Some of the roughness observed in earlier testing may have been an artifact of the testing environment rather than a real deficiency on the target device.

**Font hinting categories discovered through investigation:**

- **Full TrueType hinting** (professional, per-glyph instructions): Noto Serif (hinted by Monotype for Google). Contains fpgm (hinting program), prep (pre-program), cvt (control values), gasp (grid-fitting preferences).
- **CFF stem hints only** (basic — identifies stems but does not control pixel alignment): EB Garamond, Latin Modern, STIX Two, TeX Gyre Pagella, TeX Gyre Termes. Every TeX-origin serif font tested falls in this category.
- **Partial** (CFF stems plus some TrueType tables): Libertinus Serif has prep and gasp in addition to CFF hints, which is unusual for a CFF font.

**Important caveat on the DVI pipeline and hinting (now resolved).** The original `latex`-based DVI pipeline loaded fonts from `.pfb` (PostScript Font Binary) files, not `.ttf` files. dvisvgm's autohinter applied its own hinting uniformly, overriding whatever hinting the original font contained. This meant professional TrueType hinting was inaccessible. The solution was to switch to LuaLaTeX, which loads `.ttf` files directly via `fontspec`. With `dvisvgm --font-format=woff2` (no `autohint`), the professional hinting in the `.ttf` files is preserved end-to-end.

**Resolution.** The LuaLaTeX DVI pipeline with `--font-format=woff2` (no autohint) is adopted as the correct approach. LuaLaTeX loads `.ttf` files directly via `fontspec`, preserving professional TrueType hinting. The browser rasterizes the glyphs to the device's pixel grid, guided by these hinting instructions. This is Knuth's philosophy fully realized: the author controls the typography, the device adapts the rendering. The font chosen is Gentium Book Plus, a calligraphic oldstyle serif with excellent screen rendering.

Future work includes refining font color and table of contents styling, further LaTeX formatting improvements, separating the typo publishing system from the published articles (so typo serves as a reusable publishing platform and articles are maintained in their own repositories), a local mobile testing workflow to reduce deployment usage, and a landing page at the domain root.

## Section 5: Concept

The system has three components:

**Build pipeline.** `lualatex --output-format=dvi` (two passes) produces a DVI file, loading fonts from system `.ttf` files via `fontspec`. `dvisvgm --font-format=woff2 --bbox=papersize --precision=6 --page=1-` converts each page to SVG with embedded WOFF2 web fonts, preserving professional TrueType hinting. No post-processing of the SVG files is needed. The LaTeX source uses `fancyhdr` with the article title and page number in the header.

**Viewer.** A single `site/index.html` file provides the reading experience. It loads SVG pages via `<object>` tags, displays one at a time, and handles all navigation. The viewer is invisible infrastructure: the reader sees only the LaTeX page. The hard constraint is that everything the reader sees must be rendered by LaTeX. No sidebars, no HTML chrome, no browser-styled UI elements. Navigation is through physical gestures — arrow keys on desktop, tapping left/right halves on mobile — not through visible buttons or links. Holding a tap flips pages rapidly. The metaphor is a printed book, not a web application. The viewer preloads adjacent pages so that every page turn is instant. On mobile, the viewer is portrait-only.

**Display.** Always dark — text at #b0b0b0 on background #121212 via an SVG feColorMatrix filter (Apple Books Night mode). There is no light mode, no toggle, no settings. Books do not have display options.

**Hosting.** Static files are deployed to Cloudflare Pages CDN at https://jeremyjacobson.dev. Articles live at subpaths (e.g., `/yatp/`). Each article directory contains its own `index.html` viewer and SVG pages. Deployment is via `wrangler pages deploy site/ --project-name jeremyjacobson-dev`. No server logic is needed.

## Section 6: Scenarios

**Reader visits the site.** Browser loads index.html. The reader sees light gray text on a dark background — the page is immediately readable, like Apple Books Night mode. Adjacent pages preload silently. The reader presses the right arrow or taps the right half of the screen; the next page appears instantly. The page number is visible in the header, rendered by LaTeX. Citations appear as numbered references in the body — as with a book, the reader flips to the bibliography. They share the URL `jeremyjacobson.dev/yatp/#3` with a colleague, who opens it directly to page 3.

**Reader flips rapidly.** On desktop, the reader holds the right arrow key. On mobile, the reader holds their finger on the right half of the screen. After a brief delay, pages flip automatically every 150ms — like fast-forwarding. If the reader outruns the preloader (unlikely for adjacent pages), the next page appears as soon as it loads.

**Author updates the document.** Author edits src/Y-A-T-P.tex, runs the build script (which auto-patches the TOTAL page count), tests locally, then deploys when satisfied. See docs/RUNBOOK.md for the complete author workflow.

## Section 7: Impacts

**What works.** Font rendering uses the LuaLaTeX DVI+woff2 pipeline with Gentium Book Plus, which preserves both LaTeX's typographic layout and the font's professional TrueType hinting for crisp screen display. Page layout matches the LaTeX output exactly — all glyph positions, line breaks, and spacing are determined by LaTeX. Page-to-page navigation is instant via the viewer. The always-dark Apple Books Night mode display is comfortable for reading. Portrait-only mobile enforces the book metaphor. Direct links to specific pages work.

**What is gained over the previous path-based pipeline.** The DVI+woff2 pipeline produces significantly smaller SVGs (30–40KB vs. 2–4MB for path-based), as font data is shared across glyphs rather than each glyph being a separate path. Text is rendered as actual `<text>` elements, enabling the browser's font rasterizer to apply hinting. This resolves the image quality issue documented in Section 4.

**What remains.**

- **No known remaining issues.** The viewer fills the device screen on both mobile and desktop.

## Section 8: Theory of the Proposed System

The architecture is intentionally minimal: TeX source, a build script, a viewer, and a folder of SVGs. The viewer contains a small amount of JavaScript and CSS, but these serve only to replicate what a physical book already provides — the ability to turn pages. The reader never interacts with the JavaScript or CSS. They interact with the page.

### Principles Discovered Through Building

The following principles emerged from the development process. They are not prescriptive rules; they are observations about what the system taught us about itself.

**1. The reader's experience is the program.** When the initial plan proposed fixing build plumbing (replacing `sed` with Python for SVG injection), the lead engineer rejected it: "I want us to focus on the core problem — how to share documents so that the webpage reader only reads beautifully formatted LaTeX, loading is instant, and navigation is fast as flipping to a page in paper." The theory of this program is not about the build pipeline. It is about what the reader sees and feels. Every decision flows from that.

**2. The metaphor is a printed book.** When the viewer was built with Prev/Next footer links, the lead engineer said: "books don't have that." The `fancyhdr` LaTeX navigation was removed. When the loss of clickable citations was raised, the response was: "with a book there is no such link — one would flip there, so if flip is super fast then we are ok and fitting with the theory of the program." A limitation that aligns with the metaphor is not a deficiency. It is a feature. The system does not need to be better than a book. It needs to be a book.

**3. Performance is the interaction model.** The lead engineer asked whether first render would be slow and subsequent pages fast, then said: "I would like it all to be fast — paginate if needed to keep every load fast." Speed is not an optimization to be applied later. It is the core interaction. The reader should not perceive a network. The sliding-window preloader exists because every page turn must feel like turning a physical page: zero latency, no loading indicator, no spinner. The page is simply there.

**4. Rapid interaction must compound.** The lead engineer asked for rapid flipping "like on YouTube where clicking multiple times fast forwards." Each tap or keypress must advance exactly one page, instantly, with no animation delay or debounce. The system must not impose its own tempo on the reader. If the reader wants to skim five pages in one second, the system must allow it.

**5. Invisible infrastructure.** The HTML, JavaScript, and CSS in the viewer are invisible. The reader does not know they exist. There are no buttons, no sidebars, no browser-styled UI elements, no settings, no options. The page fills the screen. Page numbers are rendered by LaTeX as part of the document, not by the viewer. The system's infrastructure should be felt, not seen.

**6. Adapt the rendering to the device.** Knuth built METAFONT so that the same letterform could be adapted to different output devices. Computer Modern was not one font — it was a parameterized program that generated different shapes for different printers at different resolutions. That is hinting before hinting existed. The system follows this philosophy: LaTeX controls all typographic decisions (what text goes where, in what font, at what size, with what spacing), but the final pixel-level rendering is adapted to the reader's screen by the browser's font rasterizer, guided by professional TrueType hinting instructions. This is why the system uses LuaLaTeX with `fontspec` to load `.ttf` files directly, and `dvisvgm --font-format=woff2` without autohint — so the font's professional hinting is preserved end-to-end. The path-based approach was initially adopted on the theory that "LaTeX controls all typography and the browser merely presents the rendered output." The correction came from understanding that rasterization is not typography — it is device adaptation, and Knuth would optimize for the device.

**7. The README is a pointer, not a summary.** The README links to the article and to the documentation. It does not re-explain or summarize what is already written in the docs. Each piece of knowledge lives in exactly one place: the operating concept in PROCRV, the author workflow in the Runbook, the reader guide in SUM. The README points the reader there. Duplicating content across documents creates drift and maintenance burden.

**8. Combine XP metaphors with MIL-STD-498 rigor.** The engineering process uses MIL-STD-498 templates (Operational Concept Description, Runbook, etc.) to structure the software development effort, while drawing on the principles and values of Extreme Programming — particularly the reliance on metaphors to guide design decisions. The book metaphor is an XP metaphor applied within a MIL-STD-498 framework. This combination has been described as a "magic potion" (see Jakobsen, Sutherland, and Johnson, "Scrum and CMMI Level 5: The Magic Potion for Code Warriors"): agile values provide the creative direction, rigorous engineering standards provide the structure and traceability.

### Naur's Criteria Applied

Naur describes three properties that a programmer must possess to hold the theory of a program:

1. **Explain how the solution relates to real-world affairs.** The real-world affair is reading. A person wants to read a beautifully typeset document in a browser as naturally as they would read a printed book. The pipeline exists to deliver that experience: LaTeX controls the typography, hinting adapts it to the reader's screen, and the viewer provides the page-turning gesture. Every component exists to serve the reader, not the author or the build system.

2. **Explain what each part of the program text does and why.** The LaTeX source uses `fancyhdr` with the article title and page number in the header — minimal navigation context without violating the book metaphor. No `hyperref` is loaded because links are not functional in SVG output, and books do not change print color for references. The build script uses `lualatex --output-format=dvi` because LuaLaTeX loads `.ttf` files directly via `fontspec`, preserving professional TrueType hinting. dvisvgm uses `--font-format=woff2` without `autohint` so the professional hinting is not overridden; `--precision=6` for sub-pixel glyph positioning accuracy; `--page=1-` to process all pages; `--bbox=papersize` to match the SVG viewBox to LaTeX's page geometry. The viewer uses `<object>` tags for SVG pages because the DVI+woff2 pipeline produces SVGs with `<text>` elements and embedded fonts that require full SVG document rendering. A transparent overlay div captures all touch events because the `<object>` element creates its own browsing context that would otherwise intercept touches. The preloader fetches `n+1`, `n-1`, and `n+2` because adjacent pages must be instant and rapid flippers need lookahead. The SVG feColorMatrix filter applies Apple Books Night mode colors permanently — not as a toggle — because books do not have display options. Navigation splits the screen into left/right halves because the reader should be able to tap anywhere, not aim for a narrow edge. Each decision is documented and reasoned.

3. **Respond constructively to demands for modification.** When the `sed`-based injection failed, the theory did not prescribe a specific fix. It prescribed the constraint: the reader must see only LaTeX-rendered content, and navigation must be instant. The viewer approach satisfied both constraints and also resolved dark mode, direct page linking, and rapid flipping — problems that SVG injection could not have addressed. When the lead engineer rejected the Prev/Next footer, the theory told us why: it violated the book metaphor. When the path-based SVG pipeline produced rough text on screens, the theory — informed by Knuth's METAFONT philosophy — told us to adapt the rendering to the device rather than accept device-agnostic degradation. The LuaLaTeX DVI+woff2 pipeline was the answer: it preserves LaTeX's typographic control while preserving professional TrueType hinting for the browser to adapt the rendering to the screen. When `hyperref` was reconsidered, the theory told us to remove it: links are not functional in SVG, and books do not change print color for references. The theory enables us to evaluate any future change by asking: does this serve the reader's experience of turning pages in a beautifully typeset book?

### Summary of Advantages

- Instant rendering. SVG is parsed and painted by the browser with no layout engine, no framework initialization. Fonts are embedded as WOFF2, loaded once per page.
- Typography controlled by LaTeX, rendering adapted to the device. LaTeX determines all typographic decisions (font selection, spacing, line breaking, layout). The browser's font rasterizer applies hinting to adapt glyph rendering to the screen's pixel grid — Knuth's METAFONT philosophy applied to modern displays.
- Crisp text on all devices. The LuaLaTeX DVI+woff2 pipeline preserves professional TrueType hinting, enabling the browser's native font engine to produce crisp text with proper stem alignment and baseline snapping.
- Compact SVGs. With fonts embedded as WOFF2 rather than per-glyph path data, SVGs are 30–40KB rather than 2–4MB.
- Instant page turning. Preloaded adjacent pages swap in a single frame. Rapid flipping works without debounce.
- Apple Books Night mode display. Always dark, text at #b0b0b0 on background #121212. No settings, no options, no second build.
- Direct linking. URL hash enables sharing links to specific pages.
- Minimal hosting. Static files on a CDN. No server, no database, no framework.
- Minimal build. lualatex + dvisvgm. No npm, no bundler, no static site generator.
- Authors focus on content. The latex-assistant skill handles LaTeX formatting; the typo pipeline handles publishing. LaTeX's decades of typographic engineering are leveraged for web publishing without the author needing to know LaTeX.

### Summary of Limitations

- Font selection is constrained to fonts with professional TrueType hinting loaded via `fontspec` from `.ttf` files. Most TeX-origin serif fonts use CFF outlines with only basic stem hints. Gentium Book Plus is the current approved font. See Section 3 item 8 and Section 4 for details.
- Two SVG sets per article increases storage. Accepted: SVGs are static files on a free-bandwidth CDN, and the viewer only loads the set it needs.
- Cloudflare free tier allows 500 deployments per month. Sufficient for publishing but not for using deployments as a mobile testing workflow.

### Alternatives and Tradeoffs Considered

- **HTML output via make4ht.** Produces searchable, reflowable HTML with working links. Loses the LaTeX typography entirely. Browser fonts replace the author's chosen fonts. Rejected because the core requirement is that the reader sees LaTeX-rendered output.
- **PDF served directly.** Preserves all links and typography. Requires a PDF viewer (browser built-in or external). Rendering speed depends on the viewer. No dark mode without a separate build. PDFs cannot be styled or wrapped by a thin HTML page. Remains a viable fallback.
- **PDF-to-SVG path (dvisvgm --pdf).** The original pipeline. Converts glyphs to SVG `<path>` elements — geometrically accurate but without hinting. Produces crisp text at high PPI (460 PPI on modern phones) but rough text at low PPI (~96 PPI on monitors). SVG files are large (2–4MB per page) because every glyph is a separate path. Replaced by the LuaLaTeX DVI+woff2 pipeline after the image quality investigation revealed the root cause. See Section 4 for the full analysis.
- **SVG injection (sed/Python post-processor).** Attempted to inject `<a>` navigation elements directly into SVG files. The `sed` approach failed on XML entities. The approach was abandoned entirely in favor of the viewer, which solved navigation plus dark mode, direct linking, and rapid flipping — none of which injection could provide.

### Changes Considered but Not Included

- **Separating typo from published articles.** Typo would become a reusable publishing platform; articles would live in their own repositories. The current article serves as a demo. Planned for a future phase.
- **Local mobile testing workflow.** A way to test on a phone without deploying to Cloudflare. Options include port forwarding from WSL, ngrok, or a local network server. Would reduce deployment usage.

### Previously Considered and Now Implemented

- **LuaLaTeX pipeline for native TrueType font loading.** Implemented. LuaLaTeX loads `.ttf` files directly via `fontspec`, preserving professional TrueType hinting. The `autohint` flag was removed from dvisvgm so the font's own hinting is preserved end-to-end. Gentium Book Plus was selected as the approved font.
- **Automated TOTAL page count detection.** Implemented. The build script counts SVG files and patches index.html automatically.
- **Removal of hyperref.** Implemented. Links are not functional in SVG output, and books do not change print color for references.
- **Always-dark display.** Implemented. Dark mode was originally a toggle (`d` key on desktop, double-tap on mobile). The toggle was removed because books do not have display options. The display is now always dark, like a Kindle. This also eliminated the double-tap-to-zoom conflict on iOS browsers.
- **Portrait-only mobile.** Implemented. Landscape on mobile showed desktop SVGs stretched across the screen, breaking the book metaphor. The viewer now shows a "Rotate to portrait" message in landscape. Books do not have orientations.
- **Apple Books Night mode.** Implemented. The CSS `filter: invert(0.88) hue-rotate(180deg)` was replaced with an SVG feColorMatrix filter producing text at #b0b0b0 on background #121212 — matching Apple Books Night mode colors. This eliminates the CSS inversion artifact that inverted embedded images.
- **LaTeX page numbers with fancyhdr.** Implemented. `\pagestyle{empty}` was replaced with `fancyhdr` headers: article title (scriptsize) upper-left, page number (scriptsize) upper-right. The first page omits the title. The transient JavaScript page indicator was removed — page numbers are now rendered by LaTeX in the document itself.
