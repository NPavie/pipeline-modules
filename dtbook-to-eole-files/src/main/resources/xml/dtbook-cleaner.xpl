<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                type="px:dtbook-cleaner.script" name="main"
                px:input-filesets="dtbook"
                px:output-filesets="files">

	<p:documentation xmlns="http://www.w3.org/1999/xhtml">
		<h1 px:role="name">DTBook Cleaner</h1>
		<p px:role="desc" xml:space="preserve">Cleanup a dtbook file</p>
		<a px:role="homepage" href="http://daisy.github.io/pipeline/Get-Help/User-Guide/Scripts/dtbook-cleaner/">
			Online documentation
		</a>
		<dl px:role="author">
			<dt>Name:</dt>
			<dd px:role="name">Nicolas Pavie</dd>
			<dt>E-mail:</dt>
			<dd><a px:role="contact" href="mailto:pavie.nicolas@gmail.com">pavie.nicolas@gmail.com</a></dd>
			<dt>Organisation:</dt>
			<dd px:role="organization">DAISY Consortium</dd>
		</dl>
	</p:documentation>

	<p:input port="source" primary="true" px:media-type="application/x-dtbook+xml" sequence="true">
		<p:documentation>
			<h2 px:role="name">Input DTBook</h2>
			<p px:role="desc" xml:space="preserve">The document you want to cleanup.</p>
		</p:documentation>
	</p:input>
	<p:option name="result" required="true" px:output="result" px:type="anyDirURI">
		<p:documentation>
			<h2 px:role="name">Files output</h2>
			<p px:role="desc" xml:space="preserve">Output folder of the conversion of the DTBook XML</p>
		</p:documentation>
	</p:option>

	<!--
	    Options for to DTBook cleanup (options that are not exposed in the Word add-in are marked hidden)
	-->

	<p:option name="repair" select="true()" cx:as="xs:boolean">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Repair the DTBook</h2>
			<p px:role="desc" xml:space="preserve">Apply repair routines on the DTBook.</p>
		</p:documentation>
	</p:option>
	<p:option name="tidy" select="true()" cx:as="xs:boolean">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Tidy up the DTBook</h2>
			<p px:role="desc" xml:space="preserve">Apply tidying routines on the DTBook.</p>
		</p:documentation>
	</p:option>
	<p:option name="simplifyHeadingLayout" select="false()" cx:as="xs:boolean" px:hidden="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Tidy - Simplify headings layout</h2>
			<p px:role="desc" xml:space="preserve">Simplify the level structure

Redundant level structure is sometimes used to mimic the original layout, but can pose a problem in
some circumstances. By selecting this option the script simplifies the level structure by removing
redundant levels (subordinate levels will be moved upwards). Note that the headings of the affected
levels will also change, which will alter the appearance of the layout.</p>
		</p:documentation>
	</p:option>
	<p:option name="externalizeWhitespace" select="false()" cx:as="xs:boolean" px:hidden="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Tidy - Externalize whitespaces</h2>
			<p px:role="desc" xml:space="preserve">Externalize leading and trailing whitespace

from em, strong, sub, sup, pagenum, noteref.</p>
		</p:documentation>
	</p:option>
	<p:option name="documentLanguage" select="''" px:hidden="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Tidy - Document language</h2>
			<p px:role="desc">Set a document language</p>
		</p:documentation>
	</p:option>
	<p:option name="narrator" select="false()" cx:as="xs:boolean">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Cleanup the document for audio synthesis</h2>
			<p px:role="desc" xml:space="preserve">Apply cleaning routines on the document to prepare it for text-to-speech processes.</p>
		</p:documentation>
	</p:option>
	<p:option name="publisher" select="''" cx:as="xs:string">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Narrator - Publisher</h2>
			<p px:role="desc" xml:space="preserve">Publisher to be added as dc:Publisher if none is defined in the dtbook</p>
		</p:documentation>
	</p:option>
	<p:option name="ApplySentenceDetection" select="true()" cx:as="xs:boolean">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Apply sentences detection</h2>
			<p px:role="desc">Encapsulate sentences within the document</p>
		</p:documentation>
	</p:option>
	<p:option name="WithDoctype" select="true()" cx:as="xs:boolean" px:hidden="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Include doctype in resulting DTBook(s)</h2>
			<p px:role="desc" xml:space="preserve">Include doctype in resulting DTBook(s)

The resulting DTBook will have a standard DTBook 2005-3 doctype, optionally with MathML declaration
if MathML is present in the document.</p>
		</p:documentation>
	</p:option>

	<p:option name="temp-dir" required="true" px:output="temp" px:type="anyDirURI">
		<!-- directory used for temporary files -->
	</p:option>

	<p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
		<p:documentation>
			px:error
			px:log-error
		</p:documentation>
	</p:import>
	<p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
		<p:documentation>
			px:fileset-add-entry
			px:fileset-copy
			px:fileset-filter
			px:fileset-store
		</p:documentation>
	</p:import>
	
	<p:import href="http://www.daisy.org/pipeline/modules/dtbook-utils/library.xpl">
		<p:documentation>
			px:dtbook-break-detect
			px:dtbook-unwrap-words
			px:dtbook-upgrade
			px:dtbook-load
		</p:documentation>
	</p:import>
	<p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/library.xpl">
		<p:documentation>
			px:dtbook-to-pef
		</p:documentation>
	</p:import>
	<p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-html/library.xpl">
		<p:documentation>
			px:dtbook-to-html
		</p:documentation>
	</p:import>
	<p:import href="http://www.daisy.org/pipeline/modules/html-utils/library.xpl">
		<p:documentation>
			px:html-downgrade
		</p:documentation>
	</p:import>
	<cx:import href="http://www.daisy.org/pipeline/modules/css-utils/library.xsl" type="application/xslt+xml">
		<p:documentation>
			pf:css-parse-medium
		</p:documentation>
	</cx:import>
	<cx:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xsl" type="application/xslt+xml">
		<p:documentation>
			pf:pef-assert-embossable
		</p:documentation>
	</cx:import>

	<p:import href="library.xpl">
		<p:documentation>
			px:dtbook-clean
		</p:documentation>
	</p:import>


	<!-- ******************************************************************* -->
	<!-- DTBOOK CLEANUP: apply cleanup routines and optionally tag sentences -->
	<!-- ******************************************************************* -->

	<p:for-each px:message="Cleaning DTBook(s)" px:progess="1/2">
		<p:variable name="output-base" select="replace(replace(base-uri(.),'^.*/([^/]+)$','$1'),'\.[^\.]*$','')"/>
		<p:variable name="output-name" select="concat($output-base,'.xml')"/>

		<p:identity name="current-doc"/>

		<!-- Clean the DTBook (legal mentions added, no audio mention yet): used for the PEF outputs -->
		<px:dtbook-clean name="cleaned">
			<p:input port="source">
				<p:pipe step="current-doc" port="result"/>
			</p:input>
			<p:with-option name="repair" select="$repair"/>
			<p:with-option name="tidy" select="$tidy"/>
			<p:with-option name="simplifyHeadingLayout" select="$simplifyHeadingLayout"/>
			<p:with-option name="externalizeWhitespace" select="$externalizeWhitespace"/>
			<p:with-option name="documentLanguage" select="$documentLanguage"/>
			<p:with-option name="narrator" select="$narrator"/>
			<p:with-option name="publisher" select="$publisher"/>
			<p:with-option name="ApplySentenceDetection" select="true()"/>
			<p:with-option name="WithDoctype" select="$WithDoctype"/>
			<p:with-option name="audio-mention" select="false()"/>
		</px:dtbook-clean>

		<!-- Fileset + in-memory view of the cleaned DTBook, for the PEF outputs -->
		<px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook">
			<p:input port="source.fileset">
				<p:inline exclude-inline-prefixes="#all"><d:fileset/></p:inline>
			</p:input>
			<p:input port="entry">
				<p:pipe step="cleaned" port="result"/>
			</p:input>
		</px:fileset-add-entry>
		<px:dtbook-load name="load">
			<p:input port="source.fileset">
				<p:pipe step="dtbook" port="result.fileset"/>
			</p:input>
			<p:input port="source.in-memory">
				<p:pipe step="dtbook" port="result.in-memory"/>
			</p:input>
		</px:dtbook-load>

		<!-- PEF production, uncontracted French braille (NUM_INT) - an error must not stop the remaining steps -->
		<p:try name="try-pef-int" px:message="Producing the NUM_INT PEF file (uncontracted braille)">
			<p:group>
				<p:output port="result" primary="true" sequence="true"/>
				<!-- Medium for the PEF production: 30x28 pages, no duplex (maps the page-width/page-height/duplex options) -->
				<p:variable name="medium"
				            select="pf:pef-assert-embossable(pf:css-parse-medium(('embossed AND (-daisy-format:pef)', map:merge((map:entry('device-width','30'), map:entry('device-height','28'), map:entry('duplex','false'), map:entry('-daisy-document-locale',(/*/@xml:lang,'und')[1]))))))">
					<p:pipe step="load" port="result.in-memory"/>
				</p:variable>
				<px:dtbook-to-pef name="pef-int">
					<p:input port="source.fileset">
						<p:pipe step="load" port="result.fileset"/>
					</p:input>
					<p:input port="source.in-memory">
						<p:pipe step="load" port="result.in-memory"/>
					</p:input>
					<p:with-option name="temp-dir" select="concat($temp-dir,'pef-int/')"/>
					<p:with-option name="transform" select="'(liblouis-table:&quot;fr-bfu-comp6.utb&quot;)(translator:liblouis)(formatter:dotify)'"/>
					<p:with-option name="parameters" select="'(hyphenation:&quot;auto&quot;)(line-spacing:&quot;single&quot;)(maximum-number-of-sheets:1000)(allow-volume-break-inside-leaf-section-factor:0)(prefer-volume-break-before-higher-level-factor:0)(notes-placement:&quot;end-of-book&quot;)'"/>
					<p:with-option name="medium" select="$medium"/>
				</px:dtbook-to-pef>
				<p:store px:message="Storing the NUM_INT PEF file">
					<p:input port="source">
						<p:pipe step="pef-int" port="result"/>
					</p:input>
					<p:with-option name="href" select="concat(resolve-uri($result),$output-base,'_NUM_INT.pef')"/>
				</p:store>
				<p:identity name="pef-int-result">
					<p:input port="source">
						<p:pipe step="pef-int" port="result"/>
					</p:input>
				</p:identity>
			</p:group>
			<p:catch name="catch-int">
				<p:output port="result" primary="true" sequence="true"/>
				<p:identity name="catch-int-result">
					<p:input port="source">
						<p:empty/>
					</p:input>
				</p:identity>
				<px:message severity="ERROR">
					<p:input port="error">
						<p:pipe step="catch-int" port="error"/>
					</p:input>
				</px:message>
				<p:identity px:message="Failed to produce the NUM_INT PEF file, continuing with the remaining steps" px:message-severity="WARN"/>
			</p:catch>
		</p:try>

		<!-- PEF production, contracted French braille (NUM_ABR) - an error must not stop the remaining steps -->
		<p:try name="try-pef-abr" px:message="Producing the NUM_ABR PEF file (contracted braille)">
			<p:group>
				<p:output port="result" primary="true" sequence="true"/>
				<!-- Medium for the PEF production: 30x28 pages, no duplex (maps the page-width/page-height/duplex options) -->
				<p:variable name="medium"
				            select="pf:pef-assert-embossable(pf:css-parse-medium(('embossed AND (-daisy-format:pef)', map:merge((map:entry('device-width','30'), map:entry('device-height','28'), map:entry('duplex','false'), map:entry('-daisy-document-locale',(/*/@xml:lang,'und')[1]))))))">
					<p:pipe step="load" port="result.in-memory"/>
				</p:variable>
				<px:dtbook-to-pef name="pef-abr">
					<p:input port="source.fileset">
						<p:pipe step="load" port="result.fileset"/>
					</p:input>
					<p:input port="source.in-memory">
						<p:pipe step="load" port="result.in-memory"/>
					</p:input>
					<p:with-option name="temp-dir" select="concat($temp-dir,'pef-abr/')"/>
					<p:with-option name="transform" select="'(liblouis-table:&quot;fr-bfu-g2.ctb&quot;)(translator:liblouis)(formatter:dotify)'"/>
					<p:with-option name="parameters" select="'(hyphenation:&quot;auto&quot;)(line-spacing:&quot;single&quot;)(maximum-number-of-sheets:1000)(allow-volume-break-inside-leaf-section-factor:0)(prefer-volume-break-before-higher-level-factor:0)(notes-placement:&quot;end-of-book&quot;)'"/>
					<p:with-option name="medium" select="$medium"/>
				</px:dtbook-to-pef>
				<p:store px:message="Storing the NUM_ABR PEF file">
					<p:input port="source">
						<p:pipe step="pef-abr" port="result"/>
					</p:input>
					<p:with-option name="href" select="concat(resolve-uri($result),$output-base,'_NUM_ABR.pef')"/>
				</p:store>
				<p:identity name="pef-abr-result">
					<p:input port="source">
						<p:pipe step="pef-abr" port="result"/>
					</p:input>
				</p:identity>
			</p:group>
			<p:catch name="catch-abr">
				<p:output port="result" primary="true" sequence="true"/>
				<p:identity name="catch-abr-result">
					<p:input port="source">
						<p:empty/>
					</p:input>
				</p:identity>
				<px:message severity="ERROR">
					<p:input port="error">
						<p:pipe step="catch-abr" port="error"/>
					</p:input>
				</px:message>
				<p:identity px:message="Failed to produce the NUM_ABR PEF file, continuing with the remaining steps" px:message-severity="WARN"/>
			</p:catch>
		</p:try>

		<!-- Copying dtbook side resources (from the parsed input document, so that the resources are discovered) -->
		<px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook-res">
			<p:input port="source.fileset">
				<p:inline exclude-inline-prefixes="#all"><d:fileset/></p:inline>
			</p:input>
			<p:input port="entry">
				<p:pipe step="current-doc" port="result"/>
			</p:input>
		</px:fileset-add-entry>
		<px:dtbook-load name="load-res">
			<p:input port="source.fileset">
				<p:pipe step="dtbook-res" port="result.fileset"/>
			</p:input>
			<p:input port="source.in-memory">
				<p:pipe step="dtbook-res" port="result.in-memory"/>
			</p:input>
		</px:dtbook-load>
		<px:fileset-filter not-media-types="application/x-dtbook+xml"/>
		<px:fileset-copy name="copy">
			<p:with-option name="target" select="resolve-uri($result)"/>
		</px:fileset-copy>
		<px:fileset-store>
			<p:input port="in-memory.in">
				<p:pipe step="copy" port="result.in-memory"/>
			</p:input>
		</px:fileset-store>

		<!-- Clean again with the audio mention added: used for the DTBook, XHTML5 and HTML4 outputs -->
		<px:dtbook-clean name="cleaned-audio">
			<p:input port="source">
				<p:pipe step="current-doc" port="result"/>
			</p:input>
			<p:with-option name="repair" select="$repair"/>
			<p:with-option name="tidy" select="$tidy"/>
			<p:with-option name="simplifyHeadingLayout" select="$simplifyHeadingLayout"/>
			<p:with-option name="externalizeWhitespace" select="$externalizeWhitespace"/>
			<p:with-option name="documentLanguage" select="$documentLanguage"/>
			<p:with-option name="narrator" select="$narrator"/>
			<p:with-option name="publisher" select="$publisher"/>
			<p:with-option name="ApplySentenceDetection" select="true()"/>
			<p:with-option name="WithDoctype" select="$WithDoctype"/>
			<p:with-option name="audio-mention" select="true()"/>
		</px:dtbook-clean>

		<p:store name="store-final" px:message="Storing the updated DTBook ...">
			<p:input port="source">
				<p:pipe step="cleaned-audio" port="result"/>
			</p:input>
			<p:with-option name="href" select="concat(resolve-uri($result),$output-name)"/>
		</p:store>

		<!-- Reload the stored DTBook as a parsed document, for the HTML outputs -->
		<p:load name="reload-final" cx:depends-on="store-final">
			<p:with-option name="href" select="concat(resolve-uri($result),$output-name)"/>
		</p:load>

		<!-- Fileset + in-memory view of the stored DTBook (with the audio mention), for the HTML outputs -->
		<px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook-final">
			<p:input port="source.fileset">
				<p:inline exclude-inline-prefixes="#all"><d:fileset/></p:inline>
			</p:input>
			<p:input port="entry">
				<p:pipe step="reload-final" port="result"/>
			</p:input>
		</px:fileset-add-entry>
		<px:dtbook-load name="load-final">
			<p:input port="source.fileset">
				<p:pipe step="dtbook-final" port="result.fileset"/>
			</p:input>
			<p:input port="source.in-memory">
				<p:pipe step="dtbook-final" port="result.in-memory"/>
			</p:input>
		</px:dtbook-load>

		<!-- XHTML5 output, produced similarly to the dtbook-to-html script -->
		<px:dtbook-to-html name="to-xhtml" px:message="Converting the DTBook to XHTML5">
			<p:input port="source.fileset">
				<p:pipe step="load-final" port="result.fileset"/>
			</p:input>
			<p:input port="source.in-memory">
				<p:pipe step="load-final" port="result.in-memory"/>
			</p:input>
			<p:with-option name="filename" select="$output-base"/>
			<p:with-option name="output-dir" select="resolve-uri($result)"/>
			<p:with-option name="temp-dir" select="concat($temp-dir,'dtbook-to-html/')"/>
			<p:with-option name="validation" select="'off'"/>
		</px:dtbook-to-html>
		<!-- Store only the XHTML5 document (not the intermediary ZedAI files) -->
		<px:fileset-filter name="xhtml-only" media-types="application/xhtml+xml">
			<p:input port="source">
				<p:pipe step="to-xhtml" port="result.fileset"/>
			</p:input>
		</px:fileset-filter>
		<px:fileset-store name="store-xhtml" px:message="Storing the XHTML5 file">
			<p:input port="fileset.in">
				<p:pipe step="xhtml-only" port="result"/>
			</p:input>
			<p:input port="in-memory.in">
				<p:pipe step="to-xhtml" port="result.in-memory"/>
			</p:input>
		</px:fileset-store>

		<!-- Reload the stored XHTML5 as a parsed document -->
		<p:load name="reload-xhtml" cx:depends-on="store-xhtml">
			<p:with-option name="href" select="concat(resolve-uri($result),$output-base,'.xhtml')"/>
		</p:load>

		<!-- HTML4 output from the XHTML5, using px:html-downgrade from html-utils -->
		<px:html-downgrade name="to-html4" px:message="Downgrading the XHTML5 file to HTML4">
			<p:input port="source">
				<p:pipe step="reload-xhtml" port="result"/>
			</p:input>
		</px:html-downgrade>
		<p:store px:message="Storing the HTML4 file">
			<p:input port="source">
				<p:pipe step="to-html4" port="result"/>
			</p:input>
			<p:with-option name="href" select="concat(resolve-uri($result),$output-base,'.html')"/>
		</p:store>
	</p:for-each>

</p:declare-step>
