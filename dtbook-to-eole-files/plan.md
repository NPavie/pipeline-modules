# Development plan — `dtbook-to-eole-files` (for AI agent implementation)

> **Status: IMPLEMENTED and green** (`mvn clean package` in this module: 14/14 tests pass, jar builds).
> The notes below describe the plan as written; the "As implemented" section at the end records the
> deviations that were necessary (mainly: the cleaning output is serialized text, so the audio mention
> is applied inside `clean.xpl` behind a new `audio-mention` option, with two cleaning passes).

Module: `dtbook-to-eole-files/` (Maven artifact `dtbook-cleaner-avh:1.0.0-SNAPSHOT`)
Goal: implement `TODO.md` in this module — extend the `dtbook-cleaner` XProc script so that,
from one input DTBook, it produces in the output folder:

- `${base}_NUM_INT.pef` — PEF, French uncontracted braille (`fr-bfu-comp6.utb`)
- `${base}_NUM_ABR.pef` — PEF, French contracted braille (`fr-bfu-g2.ctb`)
- `${base}.xml` — cleaned DTBook **with** the `avh/mentions-audio.xsl` transform applied, plus all side resources
- `${base}.xhtml` — XHTML5 produced from that DTBook (via dtbook-to-html)
- `${base}.html` — HTML4 produced from the XHTML (via `px:html-downgrade`)

where `${base}` is the input file name without extension.

Work on branch `avh-dtbook-to-eole-texts`. Build/test with Maven from the repo root or the module dir.

---

## 1. Current state (verified by reading the code)

```
dtbook-to-eole-files/
├── TODO.md                  # the requirements this plan implements
├── pom.xml                  # artifact dtbook-cleaner-avh, parent modules-parent 1.15.5
├── README.md / doc/index.md
└── src/
    ├── main/java/org/daisy/pipeline/dtbook_cleaner/impl/DTBookCleanerLibrary.java  # Saxon ext funcs getDefaultLocale(), getDate()
    ├── main/resources/
    │   ├── META-INF/catalog.xml   # maps http://www.daisy.org/pipeline/modules/dtbook-cleaner/{dtbook-cleaner.xpl,library.xpl}
    │   └── xml/
    │       ├── dtbook-cleaner.xpl # px:dtbook-cleaner.script — MAIN SCRIPT, has the TODO comment block at the end of p:for-each
    │       ├── library.xpl        # imports clean.xpl
    │       ├── clean.xpl          # px:dtbook-clean: upgrade → pxi:dtbook-fix → sentence detection → xslt avh/mentions-legales.xsl → doctyping
    │       ├── avh/mentions-legales.xsl  # inserts level1[@id='mentions_avh'] with legal mentions (already applied in clean.xpl)
    │       ├── avh/mentions-audio.xsl    # inserts p[@id='mentions_audio'] inside level1[@id='mentions_avh'] (NOT yet applied)
    │       └── fix-dtbook/…      # repair/tidy/narrator/doctyping steps + xsl (unchanged by this plan)
    └── test/
        ├── java/XProcSpecTest.java                     # extends AbstractXSpecAndXProcSpecTest
        ├── xprocspec/dtbook-cleaner.xprocspec          # scenario "test_dtbook": expects output dir == src/test/resources/test_dtbook/output/
        ├── xprocspec/clean.xprocspec, test_fix.xprocspec
        └── resources/test_dtbook/{input,output}/default_sample_for_dtbook_conversion.xml + 9 images
```

Current flow of `dtbook-cleaner.xpl` (inside `p:for-each` over input DTBooks):

1. `$output-name` = input file name with extension replaced by `.xml`
2. `px:dtbook-clean` → `cleaned` (repair/tidy/sentences/**mentions-legales**/doctype)
3. `p:store` cleaned DTBook to `resolve-uri($result),$output-name`
4. `px:fileset-add-entry` (dtbook) → `px:dtbook-load` → filter non-DTBook → `px:fileset-copy` to `$result` → `px:fileset-store` (copies side resources)
5. Then a large comment block describes exactly the missing work (same content as TODO.md).

Script options today: `result`, `temp-dir` (both required, `px:output`), `repair`, `tidy`,
`simplifyHeadingLayout`, `externalizeWhitespace`, `documentLanguage`, `narrator`, `publisher`,
`ApplySentenceDetection`, `WithDoctype`.

---

## 2. Requirements (from TODO.md, traceable)

| ID | Requirement |
|----|-------------|
| R1 | After cleaning + legal mentions, produce 2 PEF files via the dtbook-to-pef machinery. Common options: `transform` = `(translator:liblouis)(formatter:dotify)`, `stylesheet-parameters` = `(hyphenation:"auto")(line-spacing:"single")(maximum-number-of-sheets:1000)(allow-volume-break-inside-leaf-section-factor:0)(prefer-volume-break-before-higher-level-factor:0)(notes-placement:"end-of-book")`, `duplex` = `false`, `page-width` = `30`, `page-height` = `28`. |
| R2 | `${base}_NUM_INT.pef` with braille code `(liblouis-table:"fr-bfu-comp6.utb")`; `${base}_NUM_ABR.pef` with `(liblouis-table:"fr-bfu-g2.ctb")`. |
| R3 | PEF production errors must NOT abort the remaining steps → wrap each PEF conversion in `p:try`/`p:catch`. |
| R4 | After PEF export, apply `avh/mentions-audio.xsl` to the in-memory DTBook with `p:xslt`. |
| R5 | From that DTBook produce a XHTML5 file like the `dtbook-to-html` script does. |
| R6 | From the XHTML produce a HTML4 file using `px:html-downgrade` (html-utils). |
| R7 | Output folder = the 2 PEFs + `${base}.xml` (with audio mention + resources) + `${base}.xhtml` + `${base}.html`. Update tests to match. |

Verified facts the implementation relies on:

- `px:dtbook-to-pef` library step: import `http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl`
  (`dtbook-to-pef/src/main/resources/xml/xproc/library.xpl` → `dtbook-to-pef.convert.xpl`).
  Ports: `source.fileset` (primary), `source.in-memory` (sequence), outputs `result` (PEF), `status`.
  Options: `stylesheet`, `parameters` (accepts a query **string**, parsed by `pf:css-parse-param-set`),
  `transform` (full query string — the `braille-code` prefix used by the script must be included here),
  `medium` (string or map), `include-obfl`, `temp-dir` (required).
- `px:dtbook-to-html` library step: import `http://www.daisy.org/pipeline/modules/dtbook-to-html/library.xpl`
  (`convert.xpl`). Ports: `source.fileset` (primary), `source.in-memory`; outputs `result.fileset`, `result.in-memory`, `mapping`.
  Required options: `filename`, `output-dir`, `temp-dir`. Produces `{filename}.xhtml` in `output-dir`
  (usage example: `daisy3-to-epub3/src/main/resources/xml/xproc/convert.xpl` lines ~200–217).
- `px:html-downgrade`: import `http://www.daisy.org/pipeline/modules/html-utils/library.xpl`
  (`html-utils/.../xproc/html-downgrade.xpl`), ports `source` → `result`.
- try/catch pattern: copy from `dtbook-to-pef/src/main/resources/xml/xproc/dtbook-to-pef.convert.xpl` (`p:try` → `p:group` + `p:catch` with `px:message severity="ERROR"` and an empty result).
- Medium construction: copy the `$medium` variable from `dtbook-to-pef.xpl` (uses `pf:pef-assert-embossable(pf:css-parse-medium(...))`
  with `map:entry('device-width',$page-width)` etc.); requires `cx:import` of
  `http://www.daisy.org/pipeline/modules/css-utils/library.xsl` (pf:css-parse-medium) and
  `http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xsl` (pf:pef-assert-embossable).
- French tables exist: `braille/liblouis-utils/.../tables/fr-bfu-comp6.utb` and `fr-bfu-g2.ctb`.
- BOM: the parent POM imports `modules-bom`. Because this module targets the **released** parent `modules-parent:1.15.5`
  (see T1), the resolved BOM is the released `modules-bom:1.15.5` from the Maven repositories — the SNAPSHOT versions
  visible in the local `bom/pom.xml` (dtbook-to-pef 13.0.2-SNAPSHOT, pef-utils 8.0.3-SNAPSHOT, dtbook-to-html 4.1.2-SNAPSHOT,
  html-utils 6.6.2-SNAPSHOT) do NOT apply here. Declare all new dependencies **without versions** and let the released BOM manage them.

---

## 3. Design decisions

- **D1 — naming (CONFIRMED by maintainer).** All output file names are built from `$output-base` = input file name **without
  extension** (the TODO's `${output-name}` refers to this base name, not the `.xml`-suffixed variable). Keep
  `$output-name` = `concat($output-base,'.xml')` only for the DTBook output itself.
  Final outputs: `${base}_NUM_INT.pef`, `${base}_NUM_ABR.pef`, `${base}.xml`, `${base}.xhtml`, `${base}.html`.
- **D2 — PEF via library step, not the script.** Call `px:dtbook-to-pef` (convert) directly with `source.fileset`/`source.in-memory`
  from the already-loaded fileset, then `p:store` the PEF `result` to the computed href. This gives full control over output names.
  Do NOT use `px:dtbook-to-pef.store` (its naming is derived from the input base URI).
- **D3 — option mapping.** In the `px:dtbook-to-pef` call: `transform` = `(liblouis-table:"fr-bfu-comp6.utb")(translator:liblouis)(formatter:dotify)`
  (resp. `fr-bfu-g2.ctb`), `parameters` = the R1 stylesheet-parameters string, `medium` = the `$medium` variable built as in dtbook-to-pef.xpl
  with device-width 30 / device-height 28 / duplex false (this is how page-width/page-height/duplex map into the medium).
- **D4 — ordering (per TODO).** Inside `p:for-each`: clean → load fileset → PEF INT (try/catch) → PEF ABR (try/catch) →
  `p:xslt` mentions-audio → store `${base}.xml` + copy resources → `px:dtbook-to-html` → `px:html-downgrade` → store `${base}.html`.
  Note: the PEFs are produced from the DTBook **with legal mentions but before the audio mention**; the stored `.xml` is the one **after** mentions-audio.
- **D5 — keep the script id/URI unchanged** (`px:dtbook-cleaner.script`, catalog id `dtbook-cleaner`). Renaming is out of scope.
- **D6 — no new user-facing options.** All TODO options are hard-coded constants of the AVH use case. (Can be revisited later.)
- **D7 — tests.** PEF files embed metadata and braille output can vary with liblouis/dotify versions → in xprocspec, assert
  existence/count of the 5 output files and compare the `.xml` (as today); for PEF use `type="xpath"` assertions or the custom
  `x:pef-compare` step from `http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl` (see
  `dtbook-to-pef/src/test/xprocspec/test_dtbook-to-pef.script.xprocspec` for usage).

---

## 4. Implementation tasks

### T1 — `pom.xml`: add dependencies
In `dtbook-to-eole-files/pom.xml` `<dependencies>`, add (no versions — managed by modules-bom):
- `org.daisy.pipeline.modules.braille` : `dtbook-to-pef`
- `org.daisy.pipeline.modules` : `dtbook-to-html`
- `org.daisy.pipeline.modules` : `html-utils`
- `org.daisy.pipeline.modules` : `css-utils` (pf:css-parse-medium)
- `org.daisy.pipeline.modules.braille` : `pef-utils` (pf:pef-assert-embossable, and `x:pef-compare` for tests)
Keep existing deps. **DO NOT change the parent version**: the pom deliberately targets the last released
`modules-parent` **1.15.5** (not the local `1.15.6-SNAPSHOT`), because the SNAPSHOT artifacts and their dependencies have not
been released yet and would require a full rebuild of the other pipeline modules. With parent 1.15.5, Maven retrieves all
required dependencies (including the new ones) as released artifacts from the repositories — `mvn clean test` run in the module
directory is the known-working baseline command.

### T2 — `src/main/resources/xml/dtbook-cleaner.xpl`: restructure the `p:for-each` body
Replace the TODO comment block with real steps. Skeleton:

```xml
<p:for-each px:message="Cleaning DTBook(s)" px:progess="1/2">
  <p:variable name="output-base" select="replace(replace(base-uri(.),'^.*/([^/]+)$','$1'),'\.[^\.]*$','')"/>
  <p:variable name="output-name" select="concat($output-base,'.xml')"/>

  <px:dtbook-clean name="cleaned"> …(unchanged options)… </px:dtbook-clean>

  <!-- fileset + in-memory view of the cleaned dtbook, reused by PEF, resources and HTML -->
  <px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook">
    <p:input port="entry"><p:pipe step="cleaned" port="result"/></p:input>
  </px:fileset-add-entry>
  <px:dtbook-load name="load"/>

  <!-- R1–R3: PEF uncontracted, errors must not stop the script -->
  <p:try name="try-pef-int" px:message="Producing PEF (uncontracted)">
    <p:group>
      <p:output port="result" primary="true"/>
      <p:variable name="medium" select="pf:pef-assert-embossable(pf:css-parse-medium(('embossed AND (-daisy-format:pef)', map:merge((map:entry('device-width','30'), map:entry('device-height','28'), map:entry('duplex','false'), map:entry('-daisy-document-locale',(/*/@xml:lang,'und')[1]))))))">
        <p:pipe step="cleaned" port="result"/>
      </p:variable>
      <px:dtbook-to-pef name="pef-int">
        <p:input port="source.fileset"><p:pipe step="load" port="result.fileset"/></p:input>
        <p:input port="source.in-memory"><p:pipe step="load" port="result.in-memory"/></p:input>
        <p:with-option name="temp-dir" select="concat($temp-dir,'pef-int/')"/>
        <p:with-option name="transform" select="'(liblouis-table:&quot;fr-bfu-comp6.utb&quot;)(translator:liblouis)(formatter:dotify)'"/>
        <p:with-option name="parameters" select="'(hyphenation:&quot;auto&quot;)(line-spacing:&quot;single&quot;)(maximum-number-of-sheets:1000)(allow-volume-break-inside-leaf-section-factor:0)(prefer-volume-break-before-higher-level-factor:0)(notes-placement:&quot;end-of-book&quot;)'"/>
        <p:with-option name="medium" select="$medium"/>
      </px:dtbook-to-pef>
      <p:store px:message="Storing PEF (uncontracted)">
        <p:with-option name="href" select="concat(resolve-uri($result),$output-base,'_NUM_INT.pef')"/>
      </p:store>
    </p:group>
    <p:catch name="catch-int">
      <p:output port="result" primary="true" sequence="true"/>
      <p:identity><p:input port="source"><p:empty/></p:input></p:identity>
      <px:message severity="ERROR"><p:input port="error"><p:pipe step="catch-int" port="error"/></p:input></px:message>
      <p:identity px:message="Failed to produce NUM_INT PEF; continuing" px:message-severity="WARN"/>
    </p:catch>
  </p:try>

  <!-- R1–R3: PEF contracted — same block, transform liblouis-table fr-bfu-g2.ctb, name _NUM_ABR.pef, temp-dir pef-abr/ -->

  <!-- R4: audio mention on the in-memory dtbook -->
  <p:xslt name="with-audio" px:message="Adding audio mention">
    <p:input port="source"><p:pipe step="cleaned" port="result"/></p:input>
    <p:input port="stylesheet"><p:document href="avh/mentions-audio.xsl"/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>

  <!-- store final dtbook + resources -->
  <p:store px:message="Storing the updated DTBook and its resources ...">
    <p:input port="source"><p:pipe step="with-audio" port="result"/></p:input>
    <p:with-option name="href" select="concat(resolve-uri($result),$output-name)"/>
  </p:store>
  <px:fileset-filter not-media-types="application/x-dtbook+xml"/>
  <px:fileset-copy name="copy">
    <p:with-option name="target" select="resolve-uri($result)"/>
  </px:fileset-copy>
  <px:fileset-store>
    <p:input port="in-memory.in"><p:pipe step="copy" port="result.in-memory"/></p:input>
  </px:fileset-store>

  <!-- R5: XHTML5 via dtbook-to-html -->
  <px:dtbook-to-html name="to-xhtml" px:message="Converting DTBook to XHTML5">
    <p:input port="source.fileset"><p:pipe step="load" port="result.fileset"/></p:input>
    <p:input port="source.in-memory"><p:pipe step="with-audio" port="result"/></p:input>
    <p:with-option name="filename" select="$output-base"/>
    <p:with-option name="output-dir" select="resolve-uri($result)"/>
    <p:with-option name="temp-dir" select="concat($temp-dir,'dtbook-to-html/')"/>
    <p:with-option name="validation" select="'off'"/>
  </px:dtbook-to-html>
  <p:sink/>

  <!-- R6: HTML4 via px:html-downgrade -->
  <px:html-downgrade name="to-html4" px:message="Downgrading XHTML5 to HTML4">
    <p:input port="source"><p:pipe step="to-xhtml" port="result.in-memory"/></p:input>
  </px:html-downgrade>
  <p:store px:message="Storing HTML4 file">
    <p:input port="source"><p:pipe step="to-html4" port="result"/></p:input>
    <p:with-option name="href" select="concat(resolve-uri($result),$output-base,'.html')"/>
  </p:store>
</p:for-each>
```

Add the new imports at the top of the file (with `p:documentation` listing the used steps, matching repo style):

```xml
<p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl">   <!-- px:dtbook-to-pef -->
<p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-html/library.xpl">          <!-- px:dtbook-to-html -->
<p:import href="http://www.daisy.org/pipeline/modules/html-utils/library.xpl">              <!-- px:html-downgrade -->
<cx:import href="http://www.daisy.org/pipeline/modules/css-utils/library.xsl" type="application/xslt+xml">   <!-- pf:css-parse-medium -->
<cx:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xsl" type="application/xslt+xml"> <!-- pf:pef-assert-embossable -->
```

and the namespaces `xmlns:map="http://www.w3.org/2005/xpath-functions/map"` (for the `$medium` map) on `p:declare-step`.
Notes: `px:dtbook-load` output ports are `result.fileset` / `result.in-memory` (see existing usage in this file and dtbook-to-pef.xpl);
`px:fileset-filter` must run after `load` on its fileset (the existing code already chains it that way — keep that order);
check that `px:dtbook-to-html` `source.in-memory` expects the DTBook document(s) — feed `with-audio` so the XHTML also contains the audio mention.

### T3 — Tests: `src/test/xprocspec/dtbook-cleaner.xprocspec`
Update the `test_dtbook` scenario: keep the same call, but the expected output directory
`src/test/resources/test_dtbook/output/` must now contain:
`default_sample_for_dtbook_conversion.xml` (updated: contains `mentions_audio`), `…_NUM_INT.pef`, `…_NUM_ABR.pef`,
`… .xhtml`, `… .html` and the 9 images. Generate the expected files by running the script once (via the xprocspec run or the CLI, see T5),
then review them (especially the `.xml` diff: only the added `p#mentions_audio` should differ).
For the PEFs prefer `type="xpath"` existence assertions (e.g. `count(/*/*[ends-with(@name,'_NUM_INT.pef')])` equals 1 on a directory context)
or `x:pef-compare`; avoid byte-exact PEF comparison unless output proves deterministic across runs.
Add a second scenario with a minimal inline DTBook (like dtbook-to-pef tests do) to keep test runtime low if the full sample is slow.

### T4 — Docs
- `doc/index.md`: document the 5 outputs of the script.
- `README.md`: replace the truncated sentence with a real description of the module (dtbook → eole files: 2 PEF + xml + xhtml + html).
- Remove the implemented TODO comment block in `dtbook-cleaner.xpl` (done in T2) and, once everything works, shrink `TODO.md` to "done" or delete it per maintainer preference — ask before deleting.

### T5 — Build & verify
```bash
# run from the module directory (known-working baseline, parent 1.15.5 resolves released deps from the repos)
cd dtbook-to-eole-files
mvn clean test                                             # XProcSpec tests (runs the xprocspec scenarios)
mvn clean package                                          # compile + bundle (jar for deployment)
```
Do NOT run a full reactor build from the repo root and do NOT bump the parent to 1.15.6-SNAPSHOT (see T1).
Acceptance: build succeeds; `dtbook-cleaner.xprocspec` passes; a manual CLI run against the installed pipeline
(see `_test.ps1` pattern: copy `dtbook-to-eole-files/target/dtbook-cleaner-avh-1.0.0-SNAPSHOT.jar` into
`…/daisy-pipeline/system/common/`, then `pipeline2.bat cli dtbook-cleaner --source <sample.xml> --result <outdir> --temp-dir <tmp>`)
produces exactly the 5 expected files in `<outdir>`.

---

## 5. Risks / open questions

1. ~~Naming interpretation (D1)~~ — resolved: outputs use `${base}` (no `.xml`); see D1.
2. ~~Parent version mismatch~~ — resolved: keep parent at released `1.15.5` on purpose; SNAPSHOT deps are not published,
   so a full reactor rebuild would be required otherwise. Build only this module (`cd dtbook-to-eole-files && mvn clean test`).
3. **PEF determinism in tests** — PEF embeds metadata; prefer structural assertions (D7).
4. **Braille runtime in tests** — dtbook-to-pef needs dotify + liblouis; they come transitively from the `dtbook-to-pef` dependency,
   but if the OSGi/test classpath misses them, add test-scope deps on `dotify-utils` / `liblouis-utils` (mirror `dtbook-to-pef/pom.xml`).
5. **`px:dtbook-to-pef` primary port** — `source.fileset` is primary; always connect both ports as in the skeleton.
6. **HTML output naming** — verify `px:dtbook-to-html` writes `{filename}.xhtml` into `output-dir`; if it writes into a subfolder,
   store/move the `result.in-memory` doc to `${base}.xhtml` with `p:store` instead (same for the downgraded HTML).
7. **Multiple input DTBooks** — the script loops with `p:for-each`; all new outputs derive from `$output-base`, so they stay per-input. Keep it that way.

---

## 6. As implemented (post-implementation notes)

The implementation follows the plan with these adjustments, all verified by the test suite:

- **`clean.xpl` gained an `audio-mention` option** (default `false()`): when true, `avh/mentions-audio.xsl`
  is applied right after `avh/mentions-legales.xsl`, **before** the doctyping step. This is required because
  `pxi:dtbook-doctyping` uses `cx:serialize="true"`, so the output of `px:dtbook-clean` is serialized text,
  not a parsed tree — an XSLT applied after cleaning would see a text node and do nothing.
- **`dtbook-cleaner.xpl` runs `px:dtbook-clean` twice** per input DTBook:
  1. `cleaned` with `audio-mention=false()` → fileset (`px:fileset-add-entry` + `px:dtbook-load`) → the two PEF
     productions (each in `p:try`/`p:catch`, using `px:dtbook-to-pef` with the TODO's transform/parameters/medium).
  2. `cleaned-audio` with `audio-mention=true()` → stored directly as `${base}.xml` (the direct store of the
     serialized output is what carries the doctype).
- **Side resources** (images) are copied from a fileset built on the parsed **input** document
  (`px:fileset-add-entry` on `current-doc` + `px:dtbook-load`), because resource discovery needs a parsed DTBook.
- **XHTML5**: the stored `${base}.xml` is reloaded with `p:load` (`cx:depends-on` the store — filesystem race
  otherwise), wrapped in a fileset + `px:dtbook-load`, converted with `px:dtbook-to-html`
  (`filename=$output-base`, `output-dir=$result`), stored with `px:fileset-store` after filtering the fileset to
  `application/xhtml+xml` only (avoids dropping the intermediary zedai-mods/css in the output).
- **HTML4**: the stored `.xhtml` is reloaded (`p:load` with `cx:depends-on`) and downgraded with
  `px:html-downgrade`, then stored as `${base}.html`.
- **`pom.xml`**: compile deps `dtbook-to-pef` + `pef-utils` (org.daisy.pipeline.modules.braille), `dtbook-to-html`,
  `html-utils`, `css-utils`; test deps `liblouis-utils`, `libhyphen-utils`, `dotify-utils`, `obfl-utils` plus a
  `win` OS profile with the `windows` classifiers for liblouis/libhyphen (mirrors dtbook-to-pef's own pom).
  Parent stays at released `1.15.5`; build only this module.
- **Tests** (`dtbook-cleaner.xprocspec`): the directory is asserted with xpath checks on the 5 output file names
  + 9 images (PEFs are NOT byte-compared: they embed `dc:date` = run date); the `.xml` is compared against the
  updated expected resource (now including `mentions_audio`); both PEFs are checked to be `pef` documents with
  `row` content.

## 7. Extension: EPUB3 + DAISY 2.02 outputs (implemented, green — 15/15 tests)

Added at the end of the `p:for-each`, after the HTML4 store, from the stored `${base}.xml` (audio-mention
version, reloaded via `reload-final`):

- **`${base}.epub`**: the `dtbook-to-epub3` **script** is imported by its catalog URI
  (`http://www.daisy.org/pipeline/modules/dtbook-to-epub3/dtbook-to-epub3.xpl`) and called as
  `<px:dtbook-to-epub3.script>` with `result` = the output folder, `temp-dir`, `validation='off'`,
  `audio='false'`. Because the script derives the EPUB name from the first input DTBook's base URI,
  feeding it the stored `${base}.xml` produces exactly `${base}.epub` in the output folder.
- **`${base}_daisy202/`**: the `epub3-to-daisy202` **script** is called as `<px:epub3-to-daisy202.script>`
  with `source` = `${result}/${base}.epub`, `result` = a temp dir (`$temp-dir/daisy202/`), `validation='off'`
  (ordered after the EPUB step via `cx:depends-on`). The script stores the DAISY 2.02 file-set in a
  `<sanitized dc:identifier>/` subfolder of that temp dir; the subfolder is located with `p:directory-list`,
  turned into a fileset with `px:fileset-from-dir`, and relocated with `px:fileset-copy`
  (target = `${result}/${base}_daisy202/`) followed by `px:fileset-store` (the step that physically writes;
  `px:fileset-copy` alone only computes the moved fileset).
- Both conversions are wrapped in `p:try`/`p:catch` (same pattern as the PEFs): a failure logs an error
  and the remaining outputs are still produced.
- The `p:for-each` body now ends with `<p:sink>` (piping the last `p:try`'s result): the last step of the
  body must have no output port, otherwise err:XS0006 "Unbound primary output port on last step".
- **pom.xml**: new compile deps `dtbook-to-epub3` and `epub3-to-daisy202` (versions managed by the released
  BOM 1.15.5); their catalogs make the script URIs resolvable.
- **Tests**: the `test_dtbook` scenario additionally asserts the existence of
  `default_sample_for_dtbook_conversion.epub` and of the `default_sample_for_dtbook_conversion_daisy202/`
  folder containing `ncc.html`.

## 8. Fix: no more `dtb:` prefix on the injected AVH mentions (green — 16/16 tests)

The mentions injected by `avh/mentions-legales.xsl` / `avh/mentions-audio.xsl` were serialized as
`<dtb:level1 xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/" …>` because the stylesheets bound the DTBook
namespace to a `dtb:` prefix and used prefixed literal result elements. Both stylesheets now declare the
DTBook namespace as the default namespace (`xmlns=…`) **and** `xpath-default-namespace=…` (needed because
unprefixed names in XSLT patterns/selects do NOT use the stylesheet default namespace — only literal result
elements do). The injected elements now come out prefix-less (`<level1 id="mentions_avh">…`), matching the
rest of the document. The doctyping/"plain text" hypothesis was ruled out: the mentions are applied on a
parsed tree inside `clean.xpl`, before `pxi:dtbook-doctyping` (`cx:serialize="true"`) runs.

Tests: `clean.xprocspec` inline expectation and the `test_dtbook/output` expected resource were refreshed
to the prefix-less form; `dtbook-cleaner.xprocspec` gained a regression assertion
`count(//*[starts-with(name(),'dtb:')])=0` on the stored DTBook.
