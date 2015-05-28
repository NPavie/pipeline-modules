<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="px:dtbook-to-pef.convert" version="1.0" xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:d="http://www.daisy.org/ns/pipeline/data" xmlns:pef="http://www.daisy.org/ns/2008/pef"
    xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
    xmlns:math="http://www.w3.org/1998/Math/MathML" exclude-inline-prefixes="#all" name="main">

    <p:input port="source" px:media-type="application/x-dtbook+xml"/>
    <p:output port="result" px:media-type="application/x-pef+xml"/>

    <p:option name="default-stylesheet" required="false" select="''"/>
    <p:option name="transform" required="false" select="''"/>

    <!-- Empty temporary directory dedicated to this conversion -->
    <p:option name="temp-dir" required="true"/>

    <p:import href="http://www.daisy.org/pipeline/modules/braille/common-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>

    <p:variable name="lang" select="(/*/@xml:lang,'und')[1]"/>

    <px:dtbook-load name="load"/>
    <css:inline>
        <!-- TODO: use stylesheet referenced from DTBook itself? -->
        <p:with-option name="default-stylesheet" select="$default-stylesheet"/>
    </css:inline>

    <p:viewport match="math:math">
        <px:transform type="mathml">
            <p:with-option name="query" select="concat('(locale:',$lang,')')"/>
            <p:with-option name="temp-dir" select="$temp-dir"/>
        </px:transform>
    </p:viewport>

    <px:transform type="css" name="pef">
        <p:with-option name="query" select="concat($transform,'(locale:',$lang,')')"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
    </px:transform>

    <p:xslt name="metadata">
        <p:input port="source">
            <p:pipe step="main" port="source"/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/dtbook-to-metadata.xsl"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
    </p:xslt>

    <pef:add-metadata>
        <p:input port="source">
            <p:pipe step="pef" port="result"/>
        </p:input>
        <p:input port="metadata">
            <p:pipe step="metadata" port="result"/>
        </p:input>
    </pef:add-metadata>

</p:declare-step>
