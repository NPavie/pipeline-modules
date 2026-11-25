<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                type="px:dtbook-cleaner.script" name="main"
                px:input-filesets="dtbook"
                px:output-filesets="dtbook">

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
			<h2 px:role="name">DTBook output</h2>
			<p px:role="desc" xml:space="preserve">Output folder of the conversion to DTBook XML</p>
		</p:documentation>
	</p:option>

	<!--
	    Options for to DTBook cleanup (options that are not exposed in the Word add-in are marked hidden)
	-->

	<p:option name="repair" select="false()" cx:as="xs:boolean">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">Repair the DTBook</h2>
			<p px:role="desc" xml:space="preserve">Apply repair routines on the DTBook.</p>
		</p:documentation>
	</p:option>
	<p:option name="tidy" select="false()" cx:as="xs:boolean">
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
	<p:option name="ApplySentenceDetection" select="false()" cx:as="xs:boolean">
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

	<p:import href="library.xpl">
		<p:documentation>
			px:dtbook-clean
		</p:documentation>
	</p:import>


	<!-- ******************************************************************* -->
	<!-- DTBOOK CLEANUP: apply cleanup routines and optionally tag sentences -->
	<!-- ******************************************************************* -->

	<p:for-each px:message="Cleaning DTBook(s)" px:progess="1/2">
		<p:variable name="output-name" select="concat(replace(replace(base-uri(.),'^.*/([^/]+)$','$1'),'\.[^\.]*$',''),'.xml')"/>
		<!-- <p:group name="cleaned" px:message="Cleaning '{$output-name}' ...">
			<p:output port="result"/>
			
			<px:dtbook-upgrade />
			
			<pxi:dtbook-fix>
				<p:with-option name="repair" select="$repair"/>
				<p:with-option name="tidy" select="$tidy"/>
				<p:with-option name="simplifyHeadingLayout" select="$simplifyHeadingLayout"/>
				<p:with-option name="externalizeWhitespace" select="$externalizeWhitespace"/>
				<p:with-option name="documentLanguage" select="$documentLanguage"/>
				<p:with-option name="narrator" select="$narrator"/>
				<p:with-option name="publisher" select="$publisher"/>
			</pxi:dtbook-fix>
			<p:choose>
				<p:when test="$ApplySentenceDetection">
					<px:dtbook-break-detect/>
					<px:dtbook-unwrap-words/>
				</p:when>
				<p:otherwise>
					<p:identity/>
				</p:otherwise>
			</p:choose>
			<p:choose>
				<p:when test="$WithDoctype">
					<pxi:dtbook-doctyping/>
				</p:when>
				<p:otherwise>
					<p:identity/>
				</p:otherwise>
			</p:choose>
		</p:group> -->
		<px:dtbook-clean name="cleaned">
			<p:with-option name="repair" select="$repair"/>
			<p:with-option name="tidy" select="$tidy"/>
			<p:with-option name="simplifyHeadingLayout" select="$simplifyHeadingLayout"/>
			<p:with-option name="externalizeWhitespace" select="$externalizeWhitespace"/>
			<p:with-option name="documentLanguage" select="$documentLanguage"/>
			<p:with-option name="narrator" select="$narrator"/>
			<p:with-option name="publisher" select="$publisher"/>
			<p:with-option name="ApplySentenceDetection" select="$ApplySentenceDetection"/>
			<p:with-option name="WithDoctype" select="$WithDoctype"/>
		</px:dtbook-clean>

		<p:store px:message="Storing the cleaned DTBook and its resources ...">
			<p:with-option name="href" select="concat(resolve-uri($result),$output-name)"/>
		</p:store>
		<!-- Copying dtbook side resources -->
		<px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook">
			<p:input port="entry">
				<p:pipe step="cleaned" port="result"/>
			</p:input>
		</px:fileset-add-entry>
		<px:dtbook-load name="load" />
		<px:fileset-filter not-media-types="application/x-dtbook+xml"/>
		<px:fileset-copy name="copy">
			<p:with-option name="target" select="resolve-uri($result)"/>
		</px:fileset-copy>
		<px:fileset-store>
			<p:input port="in-memory.in">
				<p:pipe step="copy" port="result.in-memory"/>
			</p:input>
		</px:fileset-store>
	</p:for-each>

</p:declare-step>
