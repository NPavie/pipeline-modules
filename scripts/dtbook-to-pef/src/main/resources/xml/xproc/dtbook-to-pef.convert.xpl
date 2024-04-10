<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="px:dtbook-to-pef" version="1.0"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pef="http://www.daisy.org/ns/2008/pef"
                xmlns:math="http://www.w3.org/1998/Math/MathML"
                exclude-inline-prefixes="#all"
                name="main">
    
    <p:input port="source.fileset" primary="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>DTBook fileset</p>
        </p:documentation>
    </p:input>
    <p:input port="source.in-memory" sequence="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>DTBook files</p>
        </p:documentation>
    </p:input>
    <p:output port="result" primary="true" sequence="true"> <!-- sequence=false when d:status result="ok" -->
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>PEF</p>
        </p:documentation>
    </p:output>
    <p:output port="obfl" sequence="true"> <!-- sequence=false when include-obfl=true and d:status result="ok" -->
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>OBFL</p>
        </p:documentation>
        <p:pipe step="transform" port="obfl"/>
    </p:output>
    <p:output port="css" sequence="false">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>DTBook with inline CSS</p>
        </p:documentation>
        <p:pipe step="dtbook-with-css" port="result"/>
    </p:output>
    <p:output port="status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Whether or not the conversion was successful. When include-css and/or include-obfl is
            true, the conversion may fail but still output documents on the "css" and/or "obfl"
            ports.</p>
        </p:documentation>
        <p:pipe step="transform" port="status"/>
    </p:output>
    
    <p:input kind="parameter" port="parameters" sequence="true">
        <p:inline>
            <c:param-set/>
        </p:inline>
    </p:input>
    
    <p:option name="default-stylesheet" required="false" select="'#default'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>The user agent's <a href="https://www.w3.org/TR/CSS2/cascade.html#cascade">default
            style sheet</a>.</p>
            <p>The idea of this option is that a custom "DTBook to PEF" script could be written with
            its own default style sheet (and its own set of options that correspond with the style
            sheet parameters of this default style sheet).</p>
        </p:documentation>
    </p:option>
    <p:option name="stylesheet" select="''"/>
    <p:option name="transform" select="'(translator:liblouis)(formatter:dotify)'"/>
    <p:option name="include-obfl" select="'false'" cx:as="xs:string"/>
    
    <!-- Empty temporary directory dedicated to this conversion -->
    <p:option name="temp-dir" required="true"/>

    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:assert
            px:message
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/common-utils/library.xpl">
        <p:documentation>
            px:apply-stylesheets
            px:transform
            px:parse-query
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl">
        <p:documentation>
            pef:add-metadata
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-load
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-epub3/library.xpl">
        <p:documentation>
            px:dtbook-to-opf-metadata
        </p:documentation>
    </p:import>
    
    <!-- Ensure that there's exactly one c:param-set. (In case of multiple parameters with the same
         name, only the last occurence is kept.) -->
    <p:parameters name="parameters">
        <p:input port="parameters">
            <p:pipe step="main" port="parameters"/>
        </p:input>
    </p:parameters>
    
    <!-- Parse transform query to a c:param-set -->
    <px:parse-query name="parsed-transform-query">
        <p:with-option name="query" select="$transform"/>
    </px:parse-query>
    <p:sink/>
    
    <!-- Find the first and only DTBook file -->
    <p:group name="dtbook" px:message="Loading DTBook" px:progress=".04">
        <p:output port="result"/>
        <px:fileset-load media-types="application/x-dtbook+xml">
            <p:input port="fileset">
                <p:pipe step="main" port="source.fileset"/>
            </p:input>
            <p:input port="in-memory">
                <p:pipe step="main" port="source.in-memory"/>
            </p:input>
        </px:fileset-load>
        <px:assert message="No DTBook document found." test-count-min="1" error-code="PEZE00"/>
        <px:assert message="More than one DTBook found in fileset." test-count-max="1" error-code="PEZE00"/>
    </p:group>
    
    <p:group name="dtbook-with-css" px:message="Applying style sheets" px:progress=".08">
        <p:output port="result" primary="true"/>
        <p:output port="parameters">
            <p:pipe step="apply-stylesheets" port="result.parameters"/>
        </p:output>
        <p:variable name="first-css-stylesheet"
                    select="tokenize($stylesheet,'\s+')[matches(.,'\.s?css$')][1]"/>
        <p:variable name="first-css-stylesheet-index"
                    select="(if (exists($first-css-stylesheet))
                               then index-of(tokenize($stylesheet,'\s+')[not(.='')], $first-css-stylesheet)
                               else (),
                             10000)[1]"/>
        <p:variable name="stylesheets-to-be-inlined"
                    select="string-join((
                              (tokenize($stylesheet,'\s+')[not(.='')])[position()&lt;$first-css-stylesheet-index],
                              if ($default-stylesheet!='#default')
                                then $default-stylesheet
                                else resolve-uri('../../css/default.scss'),
                              (tokenize($stylesheet,'\s+')[not(.='')])[position()&gt;=$first-css-stylesheet-index]),' ')">
            <p:inline><_/></p:inline>
        </p:variable>
        <px:apply-stylesheets name="apply-stylesheets" px:progress="1" px:message="{$stylesheets-to-be-inlined}" px:message-severity="DEBUG">
            <p:with-option name="stylesheets" select="$stylesheets-to-be-inlined"/>
            <p:with-option name="media"
                           select="concat(
                                     'embossed AND (width: ',
                                     (//c:param[@name='page-width' and not(@namespace[not(.='')])]/@value,40)[1],
                                     ') AND (height: ',
                                     (//c:param[@name='page-height' and not(@namespace[not(.='')])]/@value,25)[1],
                                     ')',
                                     if (//c:param[@name='duplex' and not(@namespace[not(.='')])]/@value='true')
                                       then ' AND (duplex: 1)'
                                       else ())">
                <p:pipe step="parameters" port="result"/>
            </p:with-option>
            <p:input port="parameters">
                <p:pipe step="parameters" port="result"/>
            </p:input>
        </px:apply-stylesheets>
    </p:group>
    
    <p:choose px:progress=".04">
        <p:when test="//math:math">
            <p:viewport px:message="Transforming MathML"
                        match="math:math">
                <p:variable name="lang" select="(/*/@xml:lang,'und')[1]">
                    <p:pipe step="dtbook" port="result"/>
                </p:variable>
                <p:variable name="locale-query" select="concat('(locale:',(//c:param[@name='locale']/@value,$lang)[1],')')">
                    <p:pipe step="parsed-transform-query" port="result"/>
                </p:variable>
                <px:transform px:progress="1">
                    <p:with-option name="query" select="concat('(input:mathml)',$locale-query)"/>
                    <p:input port="parameters">
                        <p:pipe step="dtbook-with-css" port="parameters"/>
                    </p:input>
                    <p:with-param port="parameters" name="temp-dir" select="$temp-dir"/>
                </px:transform>
            </p:viewport>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
    <p:choose name="transform" px:progress=".83">
        <p:variable name="lang" select="(/*/@xml:lang,'und')[1]"/>
        <p:variable name="locale-query" select="concat('(document-locale:',$lang,')')"/>
        <p:when test="$include-obfl='true'">
            <p:output port="result" primary="true" sequence="true"/>
            <p:output port="obfl" sequence="true">
                <p:pipe step="try-obfl" port="result"/>
            </p:output>
            <p:output port="status">
                <p:pipe step="try-pef" port="status"/>
            </p:output>
            <p:try name="try-obfl" px:message="Transforming from DTBook XML with inline CSS to OBFL" px:progress=".95">
                <p:group>
                    <p:output port="result" primary="true"/>
                    <p:output port="status">
                        <p:inline>
                            <d:status result="ok"/>
                        </p:inline>
                    </p:output>
                    <p:variable name="transform-query" select="concat('(input:css)(output:obfl)',$transform,$locale-query)"/>
                    <px:transform px:progress="1" px:message-severity="DEBUG" px:message="px:transform query={$transform-query}">
                        <p:with-option name="query" select="$transform-query"/>
                        <p:with-param port="parameters" name="temp-dir" select="$temp-dir"/>
                        <p:input port="parameters">
                            <p:pipe step="dtbook-with-css" port="parameters"/>
                        </p:input>
                    </px:transform>
                </p:group>
                <p:catch name="catch">
                    <p:output port="result" primary="true" sequence="true"/>
                    <p:output port="status">
                        <p:inline><d:status result="error"/></p:inline>
                    </p:output>
                    <p:identity>
                        <p:input port="source">
                            <p:empty/>
                        </p:input>
                    </p:identity>
                    <px:message severity="ERROR">
                        <p:input port="error">
                            <p:pipe step="catch" port="error"/>
                        </p:input>
                    </px:message>
                    <p:identity px:message-severity="ERROR" px:message="Failed to convert XML with CSS to OBFL"/>
                </p:catch>
            </p:try>
            <p:try name="try-pef" px:progress=".5">
                <p:group>
                    <p:output port="result" primary="true" sequence="true"/>
                    <p:output port="status">
                        <p:pipe step="try-obfl" port="status"/>
                    </p:output>
                    <p:variable name="transform-query" select="'(input:obfl)(input:text-css)(output:pef)'"/>
                    <p:for-each px:progress="1">
                        <p:identity px:message="Transforming from OBFL to PEF"/>
                        <px:transform px:progress="1" px:message-severity="DEBUG" px:message="px:transform query={$transform-query}">
                            <p:with-option name="query" select="$transform-query"/>
                            <p:with-param port="parameters" name="temp-dir" select="$temp-dir"/>
                            <p:input port="parameters">
                                <p:pipe step="dtbook-with-css" port="parameters"/>
                            </p:input>
                        </px:transform>
                    </p:for-each>
                </p:group>
                <p:catch name="catch">
                    <p:output port="result" primary="true" sequence="true"/>
                    <p:output port="status">
                        <p:inline><d:status result="error"/></p:inline>
                    </p:output>
                    <p:identity>
                        <p:input port="source">
                            <p:empty/>
                        </p:input>
                    </p:identity>
                    <px:message>
                        <p:input port="error">
                            <p:pipe step="catch" port="error"/>
                        </p:input>
                    </px:message>
                    <p:identity px:message="Failed to convert OBFL to PEF" px:message-severity="ERROR"/>
                </p:catch>
            </p:try>
        </p:when>
        <p:otherwise px:message="Transforming from XML with inline CSS to PEF">
            <p:output port="result" primary="true" sequence="true"/>
            <p:output port="obfl" sequence="true">
                <p:empty/>
            </p:output>
            <p:output port="status">
                <p:inline>
                    <d:status result="ok"/>
                </p:inline>
            </p:output>
            <p:variable name="transform-query" select="concat('(input:css)(output:pef)',$transform,$locale-query)"/>
            <px:transform px:progress="1" px:message-severity="DEBUG" px:message="px:transform query={$transform-query}">
                <p:with-option name="query" select="$transform-query"/>
                <p:with-param port="parameters" name="temp-dir" select="$temp-dir"/>
                <p:input port="parameters">
                    <p:pipe step="dtbook-with-css" port="parameters"/>
                </p:input>
            </px:transform>
        </p:otherwise>
    </p:choose>
    
    <p:choose name="add-metadata" px:progress=".01">
        <p:xpath-context>
            <p:pipe step="transform" port="status"/>
        </p:xpath-context>
        <p:when test="/*/@result='ok'">
            <px:dtbook-to-opf-metadata name="metadata" px:message="Extracting metadata from DTBook" px:progress="1/2">
                <p:input port="source">
                    <p:pipe step="dtbook" port="result"/>
                </p:input>
            </px:dtbook-to-opf-metadata>
            <pef:add-metadata px:message="Adding metadata to PEF" px:progress="1/2">
                <p:input port="source">
                    <p:pipe step="transform" port="result"/>
                </p:input>
                <p:input port="metadata">
                    <p:pipe step="metadata" port="result"/>
                </p:input>
            </pef:add-metadata>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    
</p:declare-step>
