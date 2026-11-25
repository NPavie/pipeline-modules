<?xml version="1.0" encoding="utf-8"?>
<!--
	repair anchors href
		Version
			2008-04-10

		Description
			repair anchors href where needed.

		Nodes
			a

		Namespaces
			(x) "http://www.daisy.org/z3986/2005/dtbook/"

		Doctype
			(x) DTBook

		Author
			PAVIE Nicolas - AVH
-->
<xsl:stylesheet version="2.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/">

	<xsl:include href="recursive-copy.xsl"/>
	<xsl:include href="output.xsl"/>
	
	<xsl:template match="dtb:a/@href">
        <xsl:value-of select="encode-for-uri(translate(., ' &#10;&#13;', ''))"/>
	</xsl:template>

</xsl:stylesheet>
