<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step name="main" px:input-filesets="dtbook" px:output-filesets="rtf" type="px:dtbook-to-rtf" version="1.0" xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/" xmlns:p="http://www.w3.org/ns/xproc" xmlns:px="http://www.daisy.org/ns/pipeline/xproc">
<!--
	<p:input port="fileset.in" primary="true"/>
	<p:input port="in-memory.in" sequence="false"/>
	<p:input port="meta" sequence="true"/>
	<p:input kind="parameter" port="parameters"/>
-->

	<p:documentation xmlns="http://www.w3.org/1999/xhtml">
		<h1 px:role="name">DTBook to RTF</h1>
		<p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into an RTF (Rich Text Format).</p>
		<a href="http://daisy.github.io/pipeline/modules/dtbook-to-rtf" px:role="homepage">Online documentation</a>
		<dl px:role="author">
			<dt>Name:</dt>
			<dd px:role="name">Yilin Langlois</dd>
			<dt>Organization:</dt>
			<dd href="http://www.braillenet.org/" px:role="organization">BrailleNet</dd>
			<dt>E-mail:</dt>
			<dd>
				<a href="mailto:yilin.langlois@braillenet.org" px:role="contact">yilin.langlois@braillenet.org</a>
			</dd>
		</dl>
	</p:documentation>
		
	
	<p:input port="source" primary="true" px:media-type="application/x-dtbook+xml" sequence="true">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">DTBook file(s)</h2>
			<p px:role="desc">One or more 2005-3 DTBook files to be transformed. In the case of multiple files, the first one will be taken.</p>
		</p:documentation>
		<p:document href="10312_xmldtbook_1.xml"/>
		<!--<p:document href="dtbook.xml"/>-->
	</p:input>
	

	<p:option name="include-table-of-content" required="false" select="'false'">
		<p:documentation/>
	</p:option>

	<p:option name="include-page-number" required="false" select="'false'">
		<p:documentation/>
	</p:option>

	<p:option name="output-dir" px:output="result" px:type="anyDirURI" required="false">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<h2 px:role="name">RTF file</h2>
			<p px:role="desc">The resulting rtf file.</p>
		</p:documentation>
	</p:option>


	<p:split-sequence initial-only="true" name="first-dtbook" test="position()=1"/>
	<p:sink/>
	
	<!--
		
	<p:xslt name="output-dir-uri">
		<p:with-param name="href" select="concat($output-dir,'/')">
			<p:empty/>
		</p:with-param>
		<p:input port="source">
			<p:inline>
				<d:file/>
			</p:inline>
		</p:input>
		<p:input port="stylesheet">
			<p:inline>
				<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://www.daisy.org/ns/pipeline/functions" version="2.0">
					<xsl:import href="http://www.daisy.org/pipeline/modules/file-utils/uri-functions.xsl"/>
					<xsl:param name="href" required="yes"/>
					<xsl:template match="/*">
						<xsl:copy>
							<xsl:attribute name="href" select="pf:normalize-uri($href)"/>
						</xsl:copy>
					</xsl:template>
				</xsl:stylesheet>
			</p:inline>
		</p:input>
	</p:xslt>
	<p:sink/>
-->

	<p:xslt name="add-dtbook-id">
		<p:input port="source">
			<p:pipe step="first-dtbook" port="matched" />
		</p:input>
		<p:input port="stylesheet">
			<p:document href="add_ids_to_dtbook.xsl" />
		</p:input>
		<p:input port="parameters">
			<p:empty />
		</p:input>
	</p:xslt>
	<p:sink/>
	

	<p:xslt name="convert-to-rtf">
		<p:input port="source">
			<p:pipe step="add-dtbook-id" port="result"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="dtbook_to_rtf.xsl"/>
		</p:input>
		<p:with-param name="inclTOC" select="$include-table-of-content"/>
		<p:with-param name="inclPagenum" select="$include-page-number"/>
	</p:xslt>
	<p:sink/>
	
	<p:store href="file:///home/llanglois/tmp/firstfile.xml">
			<p:input port="source">
				<p:pipe step="first-dtbook" port="matched"/>
			</p:input>
	</p:store>

	<p:store href="file:///home/llanglois/tmp/idAdded.xml">
		<p:input port= "source">
			<p:pipe port="result" step="add-dtbook-id"/>
		</p:input>
	</p:store>
	

	<p:store href="file:///home/llanglois/tmp/resulting.rtf" method="text">
		<p:input port="source">
			<p:pipe port="result" step="convert-to-rtf"/>
		</p:input>
	</p:store>
<!--
	<px:fileset-store name="store">
		<p:input port="in-memory.in">
			<p:pipe port="result" step="convert-to-rtf"/>
		</p:input>
	</px:fileset-store>
	-->
</p:declare-step>