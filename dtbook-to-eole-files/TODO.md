# Creating a "dtbook to eole files" script

This dtbook-to-eole-files is based on the dtbook-cleaner script that cleans up a dtbook XML and aims to produce :
- a "${output-name}_NUM_INT.pef" file, that is a pef file in french uncontracted braille 
- a "${output-name}_NUM_ABR.pef" file that is a pef file in french contracted braille 
- a "${output-name}.xml" updated DTBook xml, with sentences tagged and legals mentions included (using "avh/mentions-legales.xsl" and "avh/mentions-audio.xsl"), 
  - and all associated resources files included in the output
- a "${output-name}.xhtml" XHTML5 file produced from the updated DTBook
- a "${output-name}.html" HTML4 file produced from the updated DTBook

Currently, the script already add legals mention for the Association Valentin Hauy organisations in the "clean.xpl" file

I would like the xproc script available in the src/main/resources/dtbook-cleaner.xpl to produce the following files in the result : 

- After the cleaning and legals mentions being added, produce in the output 2 "PEF" file using the dtbook-to-pef script.
For both files, the following options are common : 
			  - "transform": "(translator:liblouis)(formatter:dotify)",
			  - "stylesheet-parameters": "(hyphenation:\"auto\")(line-spacing:\"single\")(maximum-number-of-sheets:1000)(allow-volume-break-inside-leaf-section-factor:0)(prefer-volume-break-before-higher-level-factor:0)(notes-placement:\"end-of-book\")",
			  - "duplex": "false",
			  - "page-width": "30",
			  - "page-height": "28",
The 2 PEF file should be named as follow with the corresponding options to use for their production :
    - A "${output-name}_NUM_INT.pef" file should receive the option ""braille-code": `(liblouis-table:\"fr-bfu-comp6.utb\")`"
    - A "${output-name}_NUM_ABR.pef" file should receive the option ""braille-code": `(liblouis-table:\"fr-bfu-g2.ctb\")`"
			On error, the script should not stop the execution of the remaining steps (posibly using a try catch structure available in other scripts)
- After the PEF export, update the dtbook in memory by applying the "avh/mentions-audio.xsl" transformation on it (with p:xslt step)
- From this dtbook, produce a xhtml5 similarly as what produce the dtbook-to-html script
- From the xhtml, produce a html4 file, possibly using the px:html-downgrade step that should be available in html-utils modules

The expected output folder structure is then : 
- a "${output-name}_NUM_INT.pef" file
- a "${output-name}_NUM_ABR.pef" file
- a "${output-name}.xml" updated DTBook xml, with the "avh/mentions-audio.xsl" transformation applied, and all its associated resources
- an "${output-name}.xhtml" XHTML5 file produced from the updated DTBook
- an "${output-name}.html" HTML4 file produced from the updated DTBook