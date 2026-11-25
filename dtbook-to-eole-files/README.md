# DTBook to EOLE files pipeline module

Pipeline module (`dtbook-cleaner-avh`) that cleans up a DTBook XML (repair/tidy/sentence detection,
AVH legal and audio mentions) and produces, in the output folder: the updated `${base}.xml` with its
resources, two PEF braille files (`${base}_NUM_INT.pef` uncontracted and `${base}_NUM_ABR.pef`
contracted French braille), an XHTML5 file (`${base}.xhtml`) and an HTML4 file (`${base}.html`).

The main script is `src/main/resources/xml/dtbook-cleaner.xpl` (step `px:dtbook-cleaner.script`).
See `plan.md` for the development plan and `TODO.md` for the original requirements.