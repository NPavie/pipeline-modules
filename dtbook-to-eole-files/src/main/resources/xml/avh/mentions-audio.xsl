<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/">
    <!-- The DTBook namespace is the DEFAULT namespace of this stylesheet (not a "dtb:" prefix)
         so that the injected elements are created prefix-less and serialized like the rest of the
         document; xpath-default-namespace makes the unprefixed names in patterns/selects match
         the DTBook namespace -->

    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Add audio mention at the end of mentions_avh -->
    <xsl:template match="level1[@id='mentions_avh']">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <p id="mentions_audio">
                    <sent id="legals_audio_1">Ce livre vous est lu par les voix d’Acapela Group.</sent>
            </p>
        </xsl:copy>
    </xsl:template>

    <!-- Delete former audio mentions if found -->
    <xsl:template match="p[@id='mentions_audio']" />

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
