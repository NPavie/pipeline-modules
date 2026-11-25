<link rev="dp2:doc" href="../src/main/resources/xml/dtbook-cleaner.xpl"/>
<link rel="rdf:type" href="http://www.daisy.org/ns/pipeline/userdoc"/>

# DTBook to EOLE files (DTBook XML Cleaner)

Clean up a DTBook document (repair, tidy, sentence detection) and add the AVH legal and audio mentions,
then produce from it, in the output folder:

- `${base}.xml`: the updated DTBook (with the audio mention) and its associated resources
- `${base}_NUM_INT.pef`: a PEF file in French uncontracted braille (`fr-bfu-comp6.utb`)
- `${base}_NUM_ABR.pef`: a PEF file in French contracted braille (`fr-bfu-g2.ctb`)
- `${base}.xhtml`: an XHTML5 file produced from the updated DTBook
- `${base}.html`: an HTML4 file produced from the XHTML5 file
- `${base}.epub`: an EPUB3 file produced from the updated DTBook with the `dtbook-to-epub3` script
- `${base}_daisy202/`: a DAISY 2.02 file-set produced from the EPUB3 with the `epub3-to-daisy202` script

where `${base}` is the input file name without extension.

## Synopsis

{{>synopsis}}
