# Pre-Requirements Operating Concept Rationale and Validation (PROCRV)

## typo (τύπο): SVG Document Publishing System

The name comes from the Greek τύπο (accusative of τύπος), meaning "impression" or "mark," the root of "typography." The system delivers the typographic impression as LaTeX set it, with no intermediary degrading the result. Everything that is not LaTeX-rendered is, by comparison, a typo.

## Section 1: Scope

The system publishes LaTeX documents as navigable, multi-page SVG files served from a CDN. It replaces HTML-based document publishing with pure SVG output rendered by LaTeX, so that all typography, layout, and link styling are controlled by the TeX source. The scope covers the build pipeline (TeX to SVG), inter-page navigation injection, and static file hosting.

## Section 2: References

- Y-A-T-P.tex (working document used as test case)
- build-tex.sh, build-yatp.sh (current build scripts)
- build-svg-site.sh (navigation injection prototype, incomplete)
- latex-assistant skill (SKILL.md)
- dvisvgm documentation (version 2.13.1)

## Section 3: Current System State

LaTeX source compiles to PDF via pdflatex. PDF converts to per-page SVGs via `dvisvgm --pdf --page=1-`. SVGs open in the Windows browser via wslview. Fonts render correctly through this path.

Two problems remain unsolved:

1. **No clickable links in SVGs.** The `dvisvgm --pdf` path strips all hyperlink annotations from the PDF. The alternative DVI path (`dvisvgm` without `--pdf`) preserves hyperlinks but destroys word spacing with EB Garamond, producing unreadable output.

2. **No inter-page navigation.** LaTeX footer navigation was prototyped using `fancyhdr` with `\href` targets pointing to adjacent SVG filenames. The links compiled correctly into the PDF but were lost during PDF-to-SVG conversion. A post-processing script (`build-svg-site.sh`) was attempted to inject `<a xlink:href>` elements into the SVG XML. It failed due to `sed` interpreting `&` in XML entities (`&lt;`, `&gt;`) as backreferences.

3. **No hosting.** SVGs are viewed locally only.

## Section 4: Justification

The goal is a document format that loads instantly for readers, looks identical to the LaTeX PDF, and requires no web framework. SVG meets all three requirements: it is a single static file per page, renders natively in all browsers, and preserves vector text and layout exactly as pdflatex produced it.

The current system is blocked on the link injection problem. Without navigation, the reader has no way to move between pages.

## Section 5: Concept

The system has three components:

**Build pipeline.** pdflatex (two passes) produces a PDF. `dvisvgm --pdf` converts each page to SVG. A post-processing step injects navigation into each SVG file. The post-processor must not use sed for XML injection. A Python or awk script that appends SVG elements before the closing `</svg>` tag is more appropriate.

**Navigation model.** Each SVG page contains Prev/Next links and a page indicator (e.g., "2 / 5") at the bottom of the page. Links are `<a>` elements with `xlink:href` pointing to sibling SVG files by filename. The link text and styling are injected as SVG `<text>` elements matching the blue used by hyperref (`#0000CC`). The viewBox coordinate system is `0 -H W H` (negative Y-axis, origin at top-left), so navigation Y must be a small negative value (near zero) to appear at the bottom.

Alternative navigation approaches are acceptable if link injection proves too difficult. Options include swipe gestures (on mobile) or keyboard shortcuts (arrow keys) for paging. These could be provided by a thin wrapper (a minimal HTML page that embeds the SVG and listens for input events). The hard constraint is that everything the reader sees must be rendered by LaTeX. No sidebars, no HTML chrome, no browser-styled UI elements.

**Dark mode.** The system should support a dark mode option. This could be implemented as an SVG filter or CSS `filter: invert(1)` applied by the wrapper, or by producing a second set of SVGs from a LaTeX build with inverted colors. The approach is TBD.

**Hosting.** Static SVG files are deployed to a CDN. Cloudflare Pages is the primary candidate: free, fastest CDN available, single-command deploy via `wrangler pages deploy`. An index.html redirects to the first SVG page. No server logic is needed.

## Section 6: Scenarios

**Reader visits the site.** Browser loads index.html, which redirects to Y-A-T-P-1.svg. The SVG renders instantly (no JS, no CSS, no font loading). Reader clicks "Next >" at the bottom, browser loads Y-A-T-P-2.svg. Reader clicks a citation link in the text. In the current concept, internal PDF links (citations, TOC) are not preserved by `dvisvgm --pdf`, so citation links will not be clickable. Only the injected navigation links work.

**Author updates the document.** Author edits Y-A-T-P.tex, runs `./build-svg-site.sh Y-A-T-P`, and redeploys. The page count may change; the script handles this dynamically.

## Section 7: Impacts

**What works.** Font rendering is correct. Page layout matches the PDF exactly. The build from TeX to SVG is fast (under 3 seconds for 3 pages). Hosting is trivial for static files.

**What is lost.** All hyperlinks embedded by hyperref (citations, TOC cross-references, external URLs) are stripped by `dvisvgm --pdf`. Only the post-injected navigation links will be clickable. This means the blue citation text in the body will appear blue but will not be clickable. This is a known limitation of dvisvgm 2.13.1 in PDF mode.

**Possible mitigation.** A future version of dvisvgm may support PDF annotation extraction. Alternatively, the post-processor could parse the PDF's link annotations (using a tool like `pdftohtml -xml` or `mutool`) and inject corresponding `<a>` elements at the correct SVG coordinates.

## Section 8: Theory of the Proposed System

The critical open item is replacing the failed sed-based injection with a working post-processor. This is a straightforward scripting task. Once navigation injection works, the local test is complete and hosting can proceed.

The loss of internal hyperlinks (citations, TOC) is an acceptable trade-off for the initial version. The document is short enough that page navigation alone is sufficient. For longer documents, a clickable TOC on page 1 would need to be addressed, likely through coordinate-based link injection from PDF annotation data.

The architecture is intentionally minimal: TeX source, a build script, and a folder of SVGs. No JavaScript, no CSS, no build framework. This is the core value proposition.

### Naur's Criteria for Theory Building

Naur describes several properties that a programmer must possess in order to hold the theory of a program. These are relevant to this system because the system itself is an exercise in theory building: we are constructing a publishing pipeline, and the theory of that pipeline must be held by its maintainer.

1. The programmer must be able to explain how the solution relates to the affairs of the real world that it handles. For this system: the real-world affair is that a reader in a browser expects instant rendering, consistent typography, and page-to-page navigation. The pipeline exists to satisfy these expectations using only LaTeX and static files.

2. The programmer must be able to explain what each part of the program text does and why. For this system: every step in the pipeline (pdflatex, dvisvgm, post-processing, CDN deploy) exists for a specific reason documented in this PROCRV. The failure of the DVI path, the failure of sed, the choice of Cloudflare over S3 are all part of the theory.

3. The programmer must be able to respond constructively to any demand for modification. For this system: when the navigation approach fails (as it did with sed), the theory tells us why it failed (XML entity escaping) and what alternatives exist (Python post-processor, thin HTML wrapper with keyboard/swipe events). When a new requirement appears (dark mode), the theory tells us where it fits (CSS filter on the wrapper, or a second LaTeX build).

### Summary of Advantages

- Instant rendering. SVG is parsed and painted by the browser with no JavaScript, no CSS layout, and no font loading.
- Typography controlled entirely by LaTeX. The reader sees exactly what pdflatex produced. No browser font substitution.
- Minimal hosting. Static files on a CDN. No server, no database, no framework.
- Minimal build. One shell script. No npm, no bundler, no static site generator.
- The author writes only LaTeX. No HTML, no CSS, no templates to maintain.

### Summary of Disadvantages and Limitations

- No clickable hyperlinks in the SVG body. dvisvgm 2.13.1 in PDF mode strips all PDF annotations. Citation links and TOC links appear styled but are not interactive.
- Navigation must be injected by post-processing or provided by a wrapper. LaTeX cannot produce inter-file SVG links through the PDF path.
- No text selection or search within the SVG in most browsers. The text is rendered as positioned glyphs, not reflowable content.
- No responsive layout. The page is a fixed-size vector image. On narrow screens, the reader must zoom or scroll horizontally.
- Dark mode requires either a CSS filter (which inverts everything, including any images) or a second build with inverted LaTeX colors.

### Alternatives and Tradeoffs Considered

- **HTML output via make4ht.** Produces searchable, reflowable HTML with working links. Loses the LaTeX typography entirely. Browser fonts replace EB Garamond. Rejected because the core requirement is that the reader sees LaTeX-rendered output.
- **PDF served directly.** Preserves all links and typography. Requires a PDF viewer (browser built-in or external). Rendering speed depends on the viewer. No dark mode without a separate build. PDFs cannot be styled or wrapped by a thin HTML page. Remains a viable fallback.
- **DVI-to-SVG path (without --pdf).** Preserves hyperlinks from the hypertex driver. Destroys word spacing with EB Garamond. Rejected after testing.
- **Embedded SVG in HTML.** A minimal HTML page uses `<object>` or `<img>` to embed the SVG and provides navigation via keyboard/swipe listeners. The reader sees only the LaTeX-rendered content. The HTML is invisible infrastructure. This is the leading alternative if link injection into raw SVGs proves unreliable.
