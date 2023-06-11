<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:tmp="http://www.daisy.org/ns/pipeline/tmp"
                xmlns:z="http://www.daisy.org/ns/z3998/authoring/"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:l="http://xproc.org/library"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                type="px:dtbook-to-zedai" name="main"
                exclude-inline-prefixes="#all">

    <p:documentation>
        Transforms DTBook XML into ZedAI XML.
    </p:documentation>

    <p:input port="source.fileset" primary="true">
        <p:documentation>
            A fileset containing references to all the DTBook files and any resources they reference (images etc.).
            The xml:base is also set with an absolute URI for each file, and is intended to represent the "original file", while the href can change during
            conversions to reflect the path and filename of the resource in the output fileset.
        </p:documentation>
    </p:input>
    <p:input port="source.in-memory" sequence="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            One or more DTBook documents to be transformed. In the case of multiple documents, a merge will be performed.
            While all resources are referenced in the fileset on the `fileset` output port, the `in-memory`-port can contain pre-loaded documents so that they won't
            have to be loaded from disk. This means that the input documents does not have to be stored to disk -
            they could have been generated by a preceding conversion, allowing for easy chaining of scripts.
            DTBook documents may contain aural CSS (tts:*) attributes and they will be preserved in the output.
        </p:documentation>
    </p:input>

    <p:output port="result.fileset" primary="true">
        <p:documentation>
            A fileset containing references to the DTBook file and any resources it references
            (images etc.). For each file that is not stored in memory, the xml:base is set with
            an absolute URI pointing to the location on disk where it is stored. This lets the
            href reflect the path and filename of the resulting resource without having to store
            it. This is useful for chaining conversions.
        </p:documentation>
        <p:pipe port="result" step="result.fileset"/>
    </p:output>
    <p:output port="result.in-memory" sequence="true">
        <p:documentation>The ZedAI and MODS metadata documents.</p:documentation>
        <p:pipe step="result.in-memory" port="result.in-memory"/>
    </p:output>

    <p:output port="mapping">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>A <code>d:fileset</code> document that contains a mapping from input files (DTBook)
            to output file (ZedAI) and contained <code>id</code> attributes.</p>
        </p:documentation>
        <p:pipe step="choose-to-merge-dtbook-files" port="mapping"/>
    </p:output>

    <p:option name="output-dir" required="true" cx:type="xs:anyURI" cx:as="xs:string">
        <p:documentation>
            The directory to store the generated files in.
        </p:documentation>
    </p:option>

    <p:option name="zedai-filename" required="false" cx:as="xs:string" select="'zedai.xml'">
        <p:documentation>
            Filename for the generated ZedAI file
        </p:documentation>
    </p:option>
    <p:option name="mods-filename" required="false" cx:as="xs:string" select="'zedai-mods.xml'">
        <p:documentation>
            Filename for the generated MODS file
        </p:documentation>
    </p:option>
    <p:option name="css-filename" required="false" cx:as="xs:string" select="'zedai-css.css'">
        <p:documentation>
            Filename for the generated CSS file
        </p:documentation>
    </p:option>
    <p:option name="lang" required="false" cx:type="xs:string" select="''">
        <p:documentation>
            Language code of the input document.
        </p:documentation>
    </p:option>
    <p:option name="validation" cx:type="off|report|abort" select="'abort'">
        <p:documentation>
            Whether to stop processing and raise an error on validation issues (abort), only report
            them (report), or to ignore any validation issues (off). If validation is enabled and
            the input DTBook is valid, processing will stop on any invalid intermediary result.
        </p:documentation>
    </p:option>
    <p:option name="output-validation" cx:type="off|report|abort" select="$validation">
        <p:documentation>
            Determines whether to validate the ZedAI output and what to do on validation
            errors. When not specified, follows the <code>validation</code> option.
        </p:documentation>
    </p:option>
    <p:option name="copy-external-resources" cx:as="xs:boolean" select="true()">
        <p:documentation>
            Whether or not to include any referenced external resources like images and CSS-files in the output.
        </p:documentation>
    </p:option>
    <p:option name="dtbook-is-valid" cx:as="xs:boolean" select="true()">
        <p:documentation>
            Whether the input is a valid DTBook.
        </p:documentation>
    </p:option>
    <p:option name="nimas" cx:as="xs:boolean" select="false()">
        <p:documentation>
            Whether the input is NIMAS.
        </p:documentation>
    </p:option>

    <p:output port="validation-report" sequence="true">
        <p:documentation>
            HTML-formatted report of the ZedAI validation. Empty if validation is disabled.
        </p:documentation>
        <p:pipe step="validate-zedai" port="report"/>
    </p:output>
    <p:output port="validation-status" sequence="true">
        <p:documentation>
            Status of the ZedAI validation.
        </p:documentation>
        <p:pipe step="validate-zedai" port="status"/>
    </p:output>

    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:assert
        </p:documentation>
    </p:import>
    <p:import href="dtbook2005-3-to-zedai.xpl">
        <p:documentation>
            pxi:dtbook2005-3-to-zedai
        </p:documentation>
    </p:import>
    <p:import href="dtbook-to-zedai-meta.xpl">
        <p:documentation>
            px:dtbook-to-zedai-meta
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-utils/library.xpl">
        <p:documentation>
            px:dtbook-validate
            px:dtbook-to-mods-meta
            px:dtbook-upgrade
            px:dtbook-merge
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/zedai-utils/library.xpl">
        <p:documentation>
            px:zedai-validate
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-load
            px:fileset-create
            px:fileset-add-entry
            px:fileset-add-entries
            px:fileset-join
            px:fileset-intersect
            px:fileset-copy
            px:fileset-filter-in-memory
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/mediatype-utils/library.xpl">
        <p:documentation>
            px:mediatype-detect
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/file-utils/library.xpl">
        <p:documentation>
            px:set-base-uri
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/metadata-utils/library.xpl">
        <p:documentation>
            px:validate-mods
        </p:documentation>
    </p:import>


    <p:variable name="output-dir-with-slash"
                select="resolve-uri(if (ends-with($output-dir,'/')) then $output-dir else concat($output-dir,'/'))"/>

    <p:variable name="zedai-file" select="concat($output-dir-with-slash, $zedai-filename)"/>
    <p:variable name="mods-file" select="concat($output-dir-with-slash, $mods-filename)"/>
    <p:variable name="css-file" select="concat($output-dir-with-slash, $css-filename)"/>

    <p:identity px:message-severity="DEBUG" px:message="ZedAI file name: {$zedai-filename}"/>
    <p:identity px:message-severity="DEBUG" px:message="MODS file name: {$mods-filename}"/>
    <p:identity px:message-severity="DEBUG" px:message="CSS file name: {$css-filename}"/>

    <!-- =============================================================== -->
    <!-- LOAD INPUT DTBOOKS -->
    <!-- =============================================================== -->
    <p:group name="dtbook-input" px:progress="1/23">
        <p:output port="result" sequence="true"/>
        <px:fileset-load media-types="application/x-dtbook+xml">
            <p:input port="in-memory">
                <p:pipe step="main" port="source.in-memory"/>
            </p:input>
        </px:fileset-load>
        <!-- TODO: describe the error on the wiki and insert correct error code -->
        <px:assert message="No XML documents with the DTBook media type ('application/x-dtbook+xml') found in the fileset."
                   test-count-min="1" error-code="PEZE00"/>
    </p:group>

    <!-- =============================================================== -->
    <!-- UPGRADE -->
    <!-- =============================================================== -->
    <p:documentation>Upgrade the DTBook document(s) to 2005-3</p:documentation>
    <p:for-each name="upgrade-dtbook" px:progress="2/23" px:message="Upgrading DTBook to 2005-3">
        <p:output port="result" sequence="true"/>
        <px:dtbook-upgrade/>
    </p:for-each>

    <!-- =============================================================== -->
    <!-- VALIDATE -->
    <!-- =============================================================== -->
    <p:documentation>Validate the DTBook input (after the upgrade)</p:documentation>
    <p:choose px:progress="3/23">
        <p:xpath-context>
            <p:empty/>
        </p:xpath-context>
        <p:when test="$validation='abort' or ($validation='report' and $dtbook-is-valid)" px:message="Validating DTBook">
            <p:for-each px:progress="1">
                <p:identity name="dtbook"/>
                <p:sink/>
                <px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook-fileset">
                    <p:input port="entry">
                        <p:pipe step="dtbook" port="result"/>
                    </p:input>
                </px:fileset-add-entry>
                <p:choose px:progress="1">
                    <p:when test="$dtbook-is-valid">
                        <!-- input DTBooks are valid, so we expect the upgraded DTBook to be valid
                             too, otherwise we made a coding error -->
                        <p:try px:progress="1">
                            <p:group>
                                <px:dtbook-validate skip-schematron="true" report-method="error" px:progress="1"
                                                    allow-aural-css-attributes="true">
                                    <p:input port="source.in-memory">
                                        <p:pipe step="dtbook-fileset" port="result.in-memory"/>
                                    </p:input>
                                </px:dtbook-validate>
                            </p:group>
                            <p:catch name="catch">
                                <px:log-error severity="DEBUG">
                                    <p:input port="error">
                                        <p:pipe step="catch" port="error"/>
                                    </p:input>
                                </px:log-error>
                                <px:error code="BUG" message="An unexpected error happened. Please contact maintainer."/>
                            </p:catch>
                        </p:try>
                    </p:when>
                    <p:otherwise>
                        <px:dtbook-validate skip-schematron="true" report-method="error" px:progress="1"
                                            allow-aural-css-attributes="true">
                            <p:input port="source.in-memory">
                                <p:pipe step="dtbook-fileset" port="result.in-memory"/>
                            </p:input>
                        </px:dtbook-validate>
                    </p:otherwise>
                </p:choose>
            </p:for-each>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    <p:identity name="validate-dtbook"/>

    <!-- =============================================================== -->
    <!-- MERGE -->
    <!-- =============================================================== -->
    <p:documentation>If there is more than one input DTBook document, merge them into a single
        document.</p:documentation>
    <p:count name="num-input-documents" limit="2"/>
    <p:choose name="choose-to-merge-dtbook-files" px:progress="2/23">
        <p:when test=".//c:result[. > 1]" px:message="Merging DTBook files">
            <p:output port="result" primary="true"/>
            <p:output port="mapping">
                <p:pipe step="merge" port="mapping"/>
            </p:output>
            <p:sink/>
            <px:dtbook-merge name="merge" px:progress="0.75">
                <p:input port="source">
                    <p:pipe port="result" step="validate-dtbook"/>
                </p:input>
                <p:with-option name="output-base-uri" select="$zedai-file"/>
            </px:dtbook-merge>
            <p:choose px:progress="0.25" px:message="Validating">
                <p:when test="$validation='abort' or ($validation='report' and $dtbook-is-valid)" px:message="Validating">
                    <p:identity name="dtbook"/>
                    <p:sink/>
                    <px:fileset-add-entry media-type="application/x-dtbook+xml" name="dtbook-fileset">
                        <p:input port="entry">
                            <p:pipe step="dtbook" port="result"/>
                        </p:input>
                    </px:fileset-add-entry>
                    <!-- input DTBooks are valid, so we expect the merged DTBook to be valid too,
                         otherwise we made a coding error -->
                    <p:try px:progress="1">
                        <p:group>
                            <px:dtbook-validate skip-schematron="true" allow-aural-css-attributes="true" report-method="error"
                                                px:progress="1">
                                <p:input port="source.in-memory">
                                    <p:pipe step="dtbook-fileset" port="result.in-memory"/>
                                </p:input>
                            </px:dtbook-validate>
                        </p:group>
                        <p:catch name="catch">
                            <px:log-error severity="DEBUG">
                                <p:input port="error">
                                    <p:pipe step="catch" port="error"/>
                                </p:input>
                            </px:log-error>
                            <px:error code="BUG" message="An unexpected error happened. Please contact maintainer."/>
                        </p:catch>
                    </p:try>
                </p:when>
                <p:otherwise>
                    <!-- reporting validation issues in intermediary documents is not helpful for user -->
                    <p:identity/>
                </p:otherwise>
            </p:choose>
        </p:when>
        <p:otherwise>
            <p:output port="result" primary="true">
                <p:pipe step="upgrade-dtbook" port="result"/>
            </p:output>
            <p:output port="mapping">
                <p:pipe step="mapping" port="result" />
            </p:output>
            <p:template name="mapping">
                <p:input port="template">
                    <p:inline>
                        <d:fileset>
                            <d:file href="{$zedai-file}" original-href="{$dtbook-file}"/>
                        </d:fileset>
                    </p:inline>
                </p:input>
                <p:with-param name="zedai-file" select="$zedai-file"/>
                <p:with-param name="dtbook-file" select="base-uri(/*)">
                    <p:pipe step="upgrade-dtbook" port="result"/>
                </p:with-param>
            </p:template>
        </p:otherwise>
    </p:choose>

    <!-- =============================================================== -->
    <!-- CREATE ZEDAI -->
    <!-- =============================================================== -->

    <p:documentation>Convert DTBook 2005-3 to ZedAI</p:documentation>
    <pxi:dtbook2005-3-to-zedai name="transform-to-zedai" px:progress="5/23" px:message="Converting DTBook 2005-3 to ZedAI"/>

    <!-- =============================================================== -->
    <!-- CSS -->
    <!-- =============================================================== -->
    <!-- This is a step here instead of being an external library, because the following properties are required for generating CSS:
        * elements are stable (no more moving them around and potentially changing their IDs)
        * CSS information is still available (via @tmp:* attributes)
    -->
    <p:documentation>Generate CSS from the visual property attributes in the ZedAI
        document</p:documentation>
    <p:xslt px:progress="1/23" px:message="Generating CSS">
        <p:with-param name="css-file" select="$css-file"/>
        <p:input port="stylesheet">
            <p:inline>
                <!-- This is a wrapper to XML-ify the raw CSS output.  XProc will only accept it this way. -->
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                    xmlns:tmp="http://www.daisy.org/ns/pipeline/tmp">
                    <xsl:import href="generate-css.xsl"/>
                    <xsl:template match="/">
                        <tmp:wrapper>
                            <xsl:apply-imports/>
                        </tmp:wrapper>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
    </p:xslt>
    <px:set-base-uri name="generate-css">
        <p:with-option name="base-uri" select="$css-file"/>
    </px:set-base-uri>

    <p:documentation>If CSS was generated, add a reference to the ZedAI document</p:documentation>
    <p:choose name="add-css-reference" px:progress="1/23">
        <p:xpath-context>
            <p:pipe port="result" step="generate-css"/>
        </p:xpath-context>
        <p:when test="//tmp:wrapper/text()">
            <p:output port="result"/>

            <p:xslt name="add-css-reference-xslt">

                <p:input port="source">
                    <p:pipe step="transform-to-zedai" port="result"/>
                </p:input>
                <p:with-param name="css" select="$css-filename"/>
                <p:input port="stylesheet">
                    <p:inline>
                        <!-- This adds a processing instruction to reference the CSS file.  In the end, it's easier than using XProc's p:insert. -->
                        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                            version="2.0">
                            <xsl:output indent="yes" method="xml"/>
                            <xsl:param name="css"/>

                            <xsl:template match="/">
                                <xsl:message>Adding CSS PI</xsl:message>
                                <xsl:processing-instruction name="xml-stylesheet">
                                        href="<xsl:value-of select="$css"/>" </xsl:processing-instruction>
                                <xsl:apply-templates/>
                            </xsl:template>
                            <!-- identity template -->
                            <xsl:template match="@*|node()">
                                <xsl:copy>
                                    <xsl:apply-templates select="@*|node()"/>
                                </xsl:copy>
                            </xsl:template>
                        </xsl:stylesheet>
                    </p:inline>
                </p:input>
            </p:xslt>
        </p:when>
        <p:otherwise>
            <p:output port="result"/>
            <p:identity name="not-adding-css-PI">
                <p:input port="source">
                    <p:pipe port="result" step="transform-to-zedai"/>
                </p:input>
            </p:identity>
        </p:otherwise>
    </p:choose>

    <!-- this step should remove the 'tmp' prefix (it is no longer needed after this point) but it doesn't! -->
    <p:documentation>Strip temporary attributes from the ZedAI
        document.</p:documentation>
    <p:xslt name="remove-css-attributes" px:progress="1/23">
        <p:input port="parameters">
            <p:empty/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="remove-tmp-attributes.xsl"/>
        </p:input>
        <p:input port="source">
            <p:pipe step="add-css-reference" port="result"/>
        </p:input>
    </p:xslt>


    <!-- =============================================================== -->
    <!-- METADATA -->
    <!-- =============================================================== -->
    <p:documentation>Generate MODS metadata</p:documentation>
    <p:choose px:progress="2/23">
        <!-- not when input is NIMAS because there will be no head element and MODS document would
             be empty (and therefore invalid) -->
        <p:when test="$nimas">
            <p:identity>
                <p:input port="source">
                    <p:empty/>
                </p:input>
            </p:identity>
        </p:when>
        <p:otherwise>
            <px:dtbook-to-mods-meta px:progress="1/2" px:message="Generating MODS metadata">
                <p:input port="source">
                    <p:pipe step="choose-to-merge-dtbook-files" port="result"/>
                </p:input>
            </px:dtbook-to-mods-meta>
            <p:choose px:progress="1/2">
                <p:when test="$validation='abort' or ($validation='report' and $dtbook-is-valid)">
                    <!-- DTBook is valid, so we expect the resulting MODS document to be valid too,
                         otherwise we made a coding error -->
                    <p:try>
                        <p:group>
                            <px:validate-mods/>
                        </p:group>
                        <p:catch name="catch">
                            <px:log-error severity="DEBUG">
                                <p:input port="error">
                                    <p:pipe step="catch" port="error"/>
                                </p:input>
                            </px:log-error>
                            <px:error code="BUG" message="An unexpected error happened. Please contact maintainer."/>
                        </p:catch>
                    </p:try>
                </p:when>
                <p:otherwise>
                    <!-- reporting validation issues in intermediary documents is not helpful for user -->
                    <p:identity/>
                </p:otherwise>
            </p:choose>
            <px:set-base-uri>
                <p:with-option name="base-uri" select="$mods-file"/>
            </px:set-base-uri>
            <p:add-xml-base/>
        </p:otherwise>
    </p:choose>
    <p:identity name="mods-metadata"/>
    <p:sink/>

    <p:documentation>Generate ZedAI metadata</p:documentation>
    <px:dtbook-to-zedai-meta name="generate-zedai-metadata" px:progress="2/23" px:message="Generating ZedAI metadata">
        <p:input port="source">
            <p:pipe step="choose-to-merge-dtbook-files" port="result"/>
        </p:input>
    </px:dtbook-to-zedai-meta>

    <p:group>
        <p:output port="result"/>
        <p:documentation>Insert metadata into the head of ZedAI</p:documentation>
        <p:insert match="/z:document/z:head" position="last-child">
            <p:input port="insertion">
                <p:pipe port="result" step="generate-zedai-metadata"/>
            </p:input>
            <p:input port="source">
                <p:pipe port="result" step="remove-css-attributes"/>
            </p:input>
        </p:insert>
        <p:documentation>Generate UUID for ZedAI identifier</p:documentation>
        <p:uuid match="/z:document/z:head//z:meta[@property='dc:identifier']/@content"/>
    </p:group>

    <p:documentation>Create a meta element for the MODS file reference and insert it into the head
    of the ZedAI</p:documentation>
    <p:choose>
        <p:when test="$nimas">
            <!-- no MODS file was generated -->
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:identity name="zedai"/>
            <p:sink/>
            <p:string-replace match="//z:meta/@resource | //z:meta/@about" name="mods-ref-meta">
                <p:input port="source">
                    <p:inline>
                        <meta rel="z3998:meta-record" resource="@@" xmlns="http://www.daisy.org/ns/z3998/authoring/">
                            <meta property="z3998:meta-record-type" about="@@" content="z3998:mods" xmlns="http://www.daisy.org/ns/z3998/authoring/"/>
                            <meta property="z3998:meta-record-version" about="@@" content="3.3" xmlns="http://www.daisy.org/ns/z3998/authoring/"/>
                        </meta>
                    </p:inline>
                </p:input>
                <p:with-option name="replace" select="concat('&quot;',$mods-filename,'&quot;')"/>
            </p:string-replace>
            <p:sink/>
            <p:insert match="//z:head" position="first-child">
                <p:input port="source">
                    <p:pipe step="zedai" port="result"/>
                </p:input>
                <p:input port="insertion">
                    <p:pipe step="mods-ref-meta" port="result"/>
                </p:input>
            </p:insert>
        </p:otherwise>
    </p:choose>

    <!-- unwrap the meta list that was wrapped with tmp:wrapper -->
    <p:unwrap name="unwrap-meta-list" match="//z:head/tmp:wrapper"/>

    <!-- add xml:lang if not already present AND if specified by the lang option -->
    <p:documentation>Add the xml:lang attribute</p:documentation>
    <p:choose>
        <p:when test="//z:document/@xml:lang">
            <p:identity/>
        </p:when>
        <p:otherwise>
            <p:choose>
                <p:when test="string-length($lang) > 0">
                    <p:add-attribute match="//z:document">
                        <p:with-option name="attribute-name" select="'xml:lang'"/>
                        <p:with-option name="attribute-value" select="$lang"/>
                    </p:add-attribute>
                </p:when>
                <p:otherwise>
                    <p:identity px:message-severity="WARNING"
                                px:message="required xml:lang attribute not found, and no 'lang' option was passed to the converter."/>
                    <p:identity/>
                </p:otherwise>
            </p:choose>
        </p:otherwise>
    </p:choose>

    <p:documentation>Set new base URI</p:documentation>
    <px:set-base-uri>
        <p:with-option name="base-uri" select="$zedai-file"/>
    </px:set-base-uri>
    <p:add-xml-base name="result.zedai"/>

    <!-- =============================================================== -->
    <!-- VALIDATE FINAL OUTPUT -->
    <!-- =============================================================== -->
    <p:documentation>Validate the final ZedAI output.</p:documentation>
    <p:choose name="validate-zedai" px:progress="2/23">
        <p:when test="$output-validation='abort'" px:message="Validating ZedAI">
            <!-- DTBook is valid, so we expect the resulting ZedAI document to be valid too,
                 otherwise we made a coding error -->
            <p:output port="result" primary="true"/>
            <p:output port="status">
                <p:pipe step="try" port="status"/>
            </p:output>
            <p:output port="report" sequence="true">
                <p:pipe step="try" port="report"/>
            </p:output>
            <p:try px:progress="1" name="try">
                <p:group>
                    <p:output port="result" primary="true"/>
                    <p:output port="status">
                        <p:pipe step="validate" port="validation-status"/>
                    </p:output>
                    <p:output port="report" sequence="true">
                        <p:pipe step="validate" port="html-report"/>
                    </p:output>
                    <px:zedai-validate allow-aural-css-attributes="true" report-method="error" px:progress="1" name="validate"/>
                </p:group>
                <p:catch name="catch">
                    <p:output port="result" primary="true"/>
                    <p:output port="status">
                        <p:inline><irrelevant/></p:inline>
                    </p:output>
                    <p:output port="report" sequence="true">
                        <p:empty/>
                    </p:output>
                    <px:log-error severity="DEBUG">
                        <p:input port="error">
                            <p:pipe step="catch" port="error"/>
                        </p:input>
                    </px:log-error>
                    <px:error code="BUG" message="An unexpected error happened. Please contact maintainer."/>
                </p:catch>
            </p:try>
        </p:when>
        <p:when test="$output-validation='report'" px:message="Validating ZedAI">
            <p:output port="result" primary="true"/>
            <p:output port="status">
                <p:pipe step="validate" port="validation-status"/>
            </p:output>
            <p:output port="report" sequence="true">
                <p:pipe step="validate" port="html-report"/>
            </p:output>
            <px:zedai-validate allow-aural-css-attributes="true" px:progress="1" report-method="port" name="validate"/>
        </p:when>
        <p:otherwise>
            <p:output port="result" primary="true"/>
            <p:output port="status">
                <p:inline><d:validation-status result="ok"/></p:inline>
            </p:output>
            <p:output port="report" sequence="true">
                <p:empty/>
            </p:output>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    <p:sink/>

    <!-- =============================================================== -->
    <!-- COMPILE RESULT FILESET -->
    <!-- =============================================================== -->
    <p:group name="result.fileset" px:progress="1/23">
        <p:output port="result"/>
        <p:variable name="dtbook-base"
            select="replace(//d:file[@media-type = 'application/x-dtbook+xml'][1]/resolve-uri(@href,base-uri(.)),'^(.*/)[^/]*$','$1')">
            <p:pipe step="main" port="source.fileset"/>
        </p:variable>

        <p:documentation>Add the ZedAI document to the fileset.</p:documentation>
        <px:fileset-create>
            <p:with-option name="base" select="$output-dir-with-slash"/>
        </px:fileset-create>
        <px:fileset-add-entry name="result.fileset.zedai">
            <p:with-option name="href" select="$zedai-file"/>
            <p:with-option name="media-type" select="'application/z3998-auth+xml'"/>
        </px:fileset-add-entry>

        <p:choose name="result.fileset.resources">
            <p:when test="$copy-external-resources">
                <p:documentation>Add all the auxiliary resources to the fileset.</p:documentation>
                <p:output port="result" sequence="true"/>
                <px:fileset-create>
                    <p:with-option name="base" select="$dtbook-base"/>
                </px:fileset-create>
                <px:fileset-add-entries name="referenced-from-dtbook">
                    <p:with-option name="href" select="//*[@src]/string(@src)">
                        <p:pipe step="validate-zedai" port="result"/>
                    </p:with-option>
                </px:fileset-add-entries>
                <p:sink/>
                <px:fileset-intersect>
                    <p:input port="source">
                        <p:pipe step="main" port="source.fileset"/>
                        <p:pipe step="referenced-from-dtbook" port="result.fileset"/>
                    </p:input>
                </px:fileset-intersect>
                <px:fileset-rebase>
                    <p:with-option name="new-base" select="$dtbook-base"/>
                </px:fileset-rebase>
                <px:fileset-copy>
                    <p:with-option name="target" select="$output-dir-with-slash"/>
                </px:fileset-copy>
            </p:when>
            <p:otherwise px:message-severity="DEBUG" px:message="NOT copying external resources">
                <p:output port="result" sequence="true"/>
                <p:identity>
                    <p:input port="source"><p:empty/></p:input>
                </p:identity>
            </p:otherwise>
        </p:choose>

        <p:documentation>If CSS was generated: Add it to the fileset.</p:documentation>
        <p:choose name="result.fileset.generated-css">
            <p:xpath-context>
                <p:pipe port="result" step="generate-css"/>
            </p:xpath-context>

            <p:when test="//tmp:wrapper/text()">
                <p:output port="result"/>
                <px:fileset-create>
                    <p:with-option name="base" select="$output-dir-with-slash">
                        <p:empty/><!--required since the XPath context can be a sequence here, causing err:XD0008 -->
                    </p:with-option>
                </px:fileset-create>
                <px:fileset-add-entry>
                    <p:with-option name="href" select="$css-file"/>
                    <p:with-option name="media-type" select="'text/css'"/>
                </px:fileset-add-entry>
            </p:when>
            <p:otherwise>
                <p:output port="result"/>
                <p:identity>
                    <p:input port="source">
                        <p:empty/>
                    </p:input>
                </p:identity>
            </p:otherwise>
        </p:choose>
        <p:sink/>

        <p:documentation>Add the MODS document to the fileset.</p:documentation>
        <p:choose>
            <p:when test="$nimas">
                <!-- no MODS file was generated -->
                <p:identity>
                    <p:input port="source">
                        <p:empty/>
                    </p:input>
                </p:identity>
            </p:when>
            <p:otherwise>
                <px:fileset-create>
                    <p:with-option name="base" select="$output-dir-with-slash"/>
                </px:fileset-create>
                <px:fileset-add-entry>
                    <p:with-option name="href" select="$mods-file"/>
                    <p:with-option name="media-type" select="'application/mods+xml'"/>
                </px:fileset-add-entry>
            </p:otherwise>
        </p:choose>
        <p:identity name="result.fileset.mods"/>
        <p:sink/>

        <px:fileset-join>
            <p:documentation>This normalizes the fileset</p:documentation>
            <p:input port="source">
                <p:pipe port="result.fileset" step="result.fileset.zedai"/>
                <p:pipe port="result" step="result.fileset.resources"/>
                <p:pipe port="result" step="result.fileset.generated-css"/>
                <p:pipe step="result.fileset.mods" port="result"/>
            </p:input>
        </px:fileset-join>
        <p:documentation>Determine the media type of files</p:documentation>
        <px:mediatype-detect/>
    </p:group>

    <px:fileset-filter-in-memory name="result.in-memory">
        <p:input port="source.in-memory">
            <p:pipe step="validate-zedai" port="result"/>
            <p:pipe port="result" step="generate-css"/>
            <p:pipe step="mods-metadata" port="result"/>
        </p:input>
    </px:fileset-filter-in-memory>
    <p:sink/>

</p:declare-step>
