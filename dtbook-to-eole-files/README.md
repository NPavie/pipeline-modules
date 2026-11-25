# DTBook to EOLE files pipeline module

Pipeline module (`dtbook-cleaner-avh`) that cleans up a DTBook XML (repair/tidy/sentence detection,
AVH legal and audio mentions) and produces, in the output folder: the updated `${base}.xml` with its
resources, two PEF braille files (`${base}_NUM_INT.pef` uncontracted and `${base}_NUM_ABR.pef`
contracted French braille), an XHTML5 file (`${base}.xhtml`), an HTML4 file (`${base}.html`), an EPUB3 file (`${base}.epub`,
via the `dtbook-to-epub3` script) and a DAISY 2.02 file-set (`${base}_daisy202/`, via the
`epub3-to-daisy202` script run on the EPUB).

The main script is `src/main/resources/xml/dtbook-cleaner.xpl` (step `px:dtbook-cleaner.script`).
See `plan.md` for the development plan and `TODO.md` for the original requirements.