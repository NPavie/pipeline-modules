<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:d="http://www.daisy.org/ns/pipeline/data"
    exclude-inline-prefixes="px d"
    type="px:zedai-to-pef" name="zedai-to-pef" version="1.0">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">ZedAI to PEF</h1>
        <p px:role="desc">Transforms a ZedAI (DAISY 4 XML) document into an PEF.</p>
        <dl px:role="author">
            <dt>Name:</dt>
            <dd px:role="name">Bert Frees</dd>
            <dt>Organization:</dt>
            <dd px:role="organization" href="http://www.sbs-online.ch/">SBS</dd>
            <dt>E-mail:</dt>
            <dd><a px:role="contact" href="mailto:bertfrees@gmail.com">bertfrees@gmail.com</a></dd>
        </dl>
    </p:documentation>

    <p:input port="source" primary="true" px:name="source" px:media-type="application/z3998-auth+xml">
        <p:documentation>
            <h2 px:role="name">source</h2>
            <p px:role="desc">Input ZedAI.</p>
        </p:documentation>
    </p:input>
    
    <p:option name="output-dir" required="true" px:output="result" px:sequence="false" px:type="anyDirURI">
        <p:documentation>
            <h2 px:role="name">output-dir</h2>
            <p px:role="desc">Path to output directory for the PEF.</p>
        </p:documentation>
    </p:option>
    
    <p:option name="temp-dir" required="true" px:output="temp" px:sequence="false" px:type="anyDirURI">
        <p:documentation>
            <h2 px:role="name">temp-dir</h2>
            <p px:role="desc">Path to directory for storing temporary files.</p>
        </p:documentation>
    </p:option>
    
    <p:option name="stylesheet" required="false" px:type="string" select="'http://www.daisy.org/pipeline/modules/braille/zedai-to-pef/css/bana.css'">
        <p:documentation>
            <h2 px:role="name">stylesheet</h2>
            <p px:role="desc">The default css stylesheet to apply when there aren't any provided with the input file.</p>
            <pre><code class="example">http://www.daisy.org/pipeline/modules/braille/zedai-to-pef/css/bana.css</code></pre>
        </p:documentation>
    </p:option>
    
    <p:option name="preprocessor" required="false" px:type="string" select="''">
        <p:documentation>
            <h2 px:role="name">preprocessor</h2>
            <p px:role="desc">Identifier (URL) of a custom preprocessor unit (XProc step).</p>
            <pre><code class="example">http://www.sbs.ch/pipeline/modules/braille/sbs-translator/xproc/preprocessor.xpl</code></pre>
        </p:documentation>
    </p:option>
    
    <p:option name="translator" required="false" px:type="string" select="''">
        <p:documentation>
            <h2 px:role="name">translator</h2>
            <p px:role="desc">Identifier (URL) of the translator (XSLT or XProc step or liblouis table) to be used. Defaults to a simple generic liblouis-based translator.</p>
            <pre><code class="example">http://www.sbs.ch/pipeline/modules/braille/sbs-translator/xslt/translator.xsl</code></pre>
        </p:documentation>
    </p:option>
    
    <p:option name="preview" required="false" px:type="boolean" select="'false'">
        <p:documentation>
            <h2 px:role="name">preview</h2>
            <p px:role="desc">Whether or not to include a preview of the PEF in HTML (true or false).</p>
        </p:documentation>
    </p:option>
    
    <p:import href="http://www.daisy.org/pipeline/modules/braille/xml-to-pef/xproc/xml-to-pef.convert.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/pef-to-html/xproc/pef-to-html.convert.xpl"/>

    <!-- ================ -->
    <!-- EXTRACT METADATA -->
    <!-- ================ -->
    
    <p:xslt name="metadata">
        <p:input port="source">
            <p:pipe port="source" step="zedai-to-pef"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/zedai-to-metadata.xsl"/>
        </p:input>
    </p:xslt>
    
    <!-- ============== -->
    <!-- CONVERT TO PEF -->
    <!-- ============== -->

    <px:xml-to-pef.convert name="xml-to-pef">
        <p:input port="source">
            <p:pipe port="source" step="zedai-to-pef"/>
        </p:input>
        <p:input port="metadata">
            <p:pipe port="result" step="metadata"/>
        </p:input>
        <p:with-option name="default-stylesheet" select="$stylesheet">
            <p:empty/>
        </p:with-option>
        <p:with-option name="preprocessor" select="$preprocessor">
            <p:empty/>
        </p:with-option>
        <p:with-option name="translator" select="$translator">
            <p:empty/>
        </p:with-option>
        <p:with-option name="temp-dir" select="$temp-dir">
            <p:empty/>
        </p:with-option>
    </px:xml-to-pef.convert>
    
    <!-- ========= -->
    <!-- STORE PEF -->
    <!-- ========= -->
    
    <p:xslt name="output-dir-uri">
        <p:with-param name="href" select="concat($output-dir,'/')"/>
        <p:input port="source">
            <p:inline>
                <d:file/>
            </p:inline>
        </p:input>
        <p:input port="stylesheet">
            <p:inline>
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://www.daisy.org/ns/pipeline/functions" version="2.0">
                    <xsl:import href="http://www.daisy.org/pipeline/modules/file-utils/xslt/uri-functions.xsl"/>
                    <xsl:param name="href" required="yes"/>
                    <xsl:template match="/*">
                        <xsl:copy>
                            <xsl:attribute name="href" select="pf:file-uri-ify($href)"/>
                        </xsl:copy>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
    </p:xslt>
    <p:sink/>
    
    <p:group>
        
        <p:variable name="input-uri" select="base-uri(/)">
            <p:pipe step="zedai-to-pef" port="source"/>
        </p:variable>
        <p:variable name="output-dir-uri" select="/*/@href">
            <p:pipe step="output-dir-uri" port="result"/>
        </p:variable>
        
        <p:store indent="true" encoding="utf-8" omit-xml-declaration="false" >
            <p:input port="source">
                <p:pipe step="xml-to-pef" port="result"/>
            </p:input>
            <p:with-option name="href" select="concat($output-dir-uri,replace($input-uri,'^.*/([^/]*)\.[^/\.]*$','$1'),'.pef.xml')">
                <p:empty/>
            </p:with-option>
        </p:store>
        
        <!-- ======= -->
        <!-- PREVIEW -->
        <!-- ======= -->
        
        <p:choose>
            <p:when test="$preview='true'">
                
                <px:pef-to-html.convert>
                    <p:input port="source">
                        <p:pipe port="result" step="xml-to-pef"/>
                    </p:input>
                </px:pef-to-html.convert>
                
                <p:store indent="true" encoding="utf-8" method="xhtml" omit-xml-declaration="false"
                    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" >
                    <p:with-option name="href" select="concat($output-dir-uri,replace($input-uri,'^.*/([^/]*)\.[^/\.]*$','$1'),'.pef.html')">
                        <p:empty/>
                    </p:with-option>
                </p:store>
            </p:when>
            <p:otherwise>
                <!-- Do nothing-->
                <p:sink>
                    <p:input port="source">
                        <p:pipe port="result" step="xml-to-pef"/>
                    </p:input>
                </p:sink>
            </p:otherwise>
        </p:choose>
    </p:group>
    
</p:declare-step>
