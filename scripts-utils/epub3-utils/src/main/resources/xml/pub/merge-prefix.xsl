<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:f="http://www.daisy.org/ns/pipeline/internal-functions"
                xmlns="http://www.idpf.org/2007/opf"
                xpath-default-namespace="http://www.idpf.org/2007/opf"
                exclude-result-prefixes="#all">

    <xsl:include href="../epub3-vocab.xsl"/>

    <xsl:param name="reserved-prefixes" required="yes"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@prefix"/>

    <xsl:template match="/*" priority="1">
        <xsl:variable name="implicit" as="element(f:vocab)*" select="f:parse-prefix-decl($reserved-prefixes)"/>
        <xsl:variable name="all" as="element()*" select="f:all-prefix-decl(/)"/>
        <xsl:variable name="unified" as="element(f:vocab)*" select="f:unified-prefix-decl($all//f:vocab,$implicit)"/>
        <xsl:next-match>
            <xsl:with-param name="implicit" tunnel="yes" select="$implicit"/>
            <xsl:with-param name="all" tunnel="yes" select="$all"/>
            <xsl:with-param name="unified" tunnel="yes" select="$unified"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="/*">
        <xsl:param name="unified" as="element(f:vocab)*" tunnel="yes" required="yes"/>
        <xsl:copy>
            <xsl:if test="exists($unified)">
                <xsl:attribute name="prefix"
                               select="for $vocab in $unified return concat($vocab/@prefix,': ',$vocab/@uri)"/>
            </xsl:if>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="meta/@property|meta/@scheme|link/@rel">
        <xsl:param name="implicit" as="element(f:vocab)*" tunnel="yes" required="yes"/>
        <xsl:param name="all" as="element()*" tunnel="yes" required="yes"/>
        <xsl:param name="unified" as="element(f:vocab)*" tunnel="yes" required="yes"/>
        <xsl:variable name="normalized" as="xs:string?"
                      select="f:expand-property(.,$implicit,$all,$unified)/@name"/>
        <xsl:if test="exists($normalized)">
            <xsl:attribute name="{name(.)}" select="$normalized"/>
        </xsl:if>
    </xsl:template>

    <!--
        Returns a `f:property` element from a property-typeed attribute where:

        * @prefix contains the resolved, unified prefix for the property
        * @uri contains the resolved absolute URI of the property
        * @name contains the resolved name for the property, prefixed by the unified prefix
    -->
    <xsl:function name="f:expand-property" as="element(f:property)?">
        <xsl:param name="property" as="attribute()?"/>
        <xsl:param name="implicit" as="element(f:vocab)*"/>
        <xsl:param name="all" as="element()*"/>
        <xsl:param name="unified" as="element(f:vocab)*"/>
        <xsl:variable name="prefix" select="substring-before($property,':')" as="xs:string"/>
        <xsl:variable name="reference" select="replace($property,'(.+:)','')" as="xs:string"/>
        <xsl:variable name="vocab" as="xs:string?"
                      select="($all[@id=generate-id($property/ancestor::*[@prefix or not(parent::*)])]/f:vocab[@prefix=$prefix]/@uri,
                               if ($prefix='') then $vocab-package-uri else ()
                              )[1]"/>
        <xsl:if test="exists($vocab)">
            <xsl:variable name="unified-prefix" as="xs:string?"
                          select="(if ($vocab=$vocab-package-uri) then '' else (),
                                   $implicit[@uri=$vocab]/@prefix,
                                   $unified[@uri=$vocab]/@prefix
                                  )[1]"/>
            <f:property prefix="{$unified-prefix}"
                        uri="{concat($vocab,$reference)}"
                        name="{if ($unified-prefix) then concat($unified-prefix,':',$reference)  else $reference}"/>
        </xsl:if>
    </xsl:function>

    <!--
        Returns all the vocabs declared in the various @prefix attributes, as `f:vocab` elements
        grouped by elements having a `@id` attribute generated by `generate-id()`.

        Vocabs that are not used in `@property`, `@scheme` or `@rel` are discarded.
    -->
    <xsl:function name="f:all-prefix-decl" as="element()*">
        <xsl:param name="doc" as="document-node()?"/>
        <xsl:for-each select="$doc//*[@prefix or not(parent::*)]">
            <_ id="{generate-id(.)}">
                <xsl:variable name="used-prefixes" as="xs:string*"
                              select="distinct-values(
                                        for $prop in distinct-values(.//meta/(@property|@scheme)|.//link/@rel)[contains(.,':')]
                                        return substring-before($prop,':'))"/>
                <xsl:variable name="parsed-prefix-attr" as="element(f:vocab)*" select="f:parse-prefix-decl(@prefix)"/>
                <xsl:sequence select="for $prefix in $used-prefixes return
                                      ($parsed-prefix-attr[@prefix=$prefix],$f:default-prefixes[@prefix=$prefix])[1]"/>
            </_>
        </xsl:for-each>
    </xsl:function>

    <!--
        Returns a sequence of `f:vocab` elements representing unified vocab declarations
        throughout the document passed as argument.

        * reserved vocabs are discarded (don't have to be declared)
        * @prefix are unified, if it is overriding a reserved prefix, a new prefix is defined
    -->
    <xsl:function name="f:unified-prefix-decl" as="element()*">
        <xsl:param name="all" as="element(f:vocab)*"/>
        <xsl:param name="implicit" as="element(f:vocab)*"/>
        <xsl:for-each-group select="f:merge-prefix-decl($all)
                                    [not(@uri=($vocab-package-uri,
                                               $implicit/@uri))]"
                            group-by="@uri">
            <xsl:sequence select="current()"/>
        </xsl:for-each-group>
    </xsl:function>

    <xsl:template match="/phony" xpath-default-namespace="">
        <!-- avoid SXXP0005 warning -->
        <xsl:next-match/>
    </xsl:template>

</xsl:stylesheet>
