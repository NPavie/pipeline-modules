<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/" exclude-result-prefixes="dtb">

    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Add audio mention at the end of mentions_avh -->
    <xsl:template match="dtb:level1[@id='mentions_avh']">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <dtb:p id="mentions_audio">
                    <dtb:sent id="legals_audio_1">Ce livre vous est lu par les voix d’Acapela Group.</dtb:sent>
            </dtb:p>
        </xsl:copy>
    </xsl:template>

    <!-- Delete former audio mentions if found -->
    <xsl:template match="dtb:p[@id='mentions_audio']" />

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>