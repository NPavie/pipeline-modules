<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/">
    <!-- The DTBook namespace is the DEFAULT namespace of this stylesheet (not a "dtb:" prefix)
         so that the injected elements are created prefix-less and serialized like the rest of the
         document; xpath-default-namespace makes the unprefixed names in patterns/selects match
         the DTBook namespace -->

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="frontmatter">
        <xsl:copy>
            <xsl:apply-templates select="doctitle"/>
            <xsl:apply-templates select="docauthor"/>
            <level1 id="mentions_avh">
                <p id="mentions_legales">
                    <sent id="legals_avh_1">Cette adaptation est réalisée et diffusée par l’Association Valentin Haüy dans le cadre de l’exception au droit d’auteur en faveur des personnes en situation de handicap prévue aux articles L. 122-5, L. 122-5-1 et L. 122-5-2 et R. 122-13 à 22 du code de la propriété intellectuelle.</sent>
                    <sent id="legals_avh_2">Cette adaptation ne peut être utilisée que par la personne qui l’a empruntée et ne doit en aucune manière être transmise à un tiers de quelque façon que ce soit.</sent>
                </p>
            </level1>
            <xsl:apply-templates select="node()[not(self::doctitle or self::docauthor)]"/>
        </xsl:copy>
    </xsl:template>

    <!-- Delete former mentions if found -->
    <xsl:template match="level1[@id='mentions_avh']" />

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
