<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                type="px:zedai-to-epub3" name="main"
                exclude-inline-prefixes="#all">

    <p:documentation> Transforms a ZedAI (DAISY 4 XML) document into an EPUB 3 publication. </p:documentation>

    <p:input port="fileset.in" primary="true"/>
    <p:input port="in-memory.in" sequence="true"/>

    <p:input port="tts-config">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2>Text-To-Speech configuration file</h2>
            <p>Configuration file with voice mappings, PLS lexicons and annotations.</p>
        </p:documentation>
    </p:input>

    <p:option name="stylesheet" select="''">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>CSS user style sheets as space separated list of absolute URIs.</p>
        </p:documentation>
    </p:option>

    <p:output port="fileset.out" primary="true">
        <p:pipe step="html-to-epub3" port="fileset.out"/>
    </p:output>
    <p:output port="in-memory.out" sequence="true">
        <p:pipe step="html-to-epub3" port="in-memory.out"/>
    </p:output>
    <p:output port="status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Status of the TTS step and EPUB validation.</p>
            <p>A <code>result</code> attribute indicates whether both the TTS step and the EPUB
            validation were successful ("ok"), or whether at least one of them failed ("error").</p>
            <p>A <code>tts-success-rate</code> attribute contains the percentage of the input text
            that got successfully converted to speech.</p>
        </p:documentation>
        <p:pipe step="status" port="result"/>
    </p:output>
    <p:output port="temp-audio-files">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2>List of audio files</h2>
            <p>List of audio files generated by the TTS step. May be deleted when the
            result fileset is stored.</p>
        </p:documentation>
        <p:pipe step="html-to-epub3" port="temp-audio-files"/>
    </p:output>
    <p:option name="include-tts-log" select="'false'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Whether or not to make the TTS log available on the "tts-log" port.</p>
        </p:documentation>
    </p:option>
    <p:output port="tts-log" sequence="true">
        <p:pipe step="html-to-epub3" port="tts-log"/>
    </p:output>
  
    <p:option name="output-dir" required="true">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Empty directory dedicated to this conversion.</p>
        </p:documentation>
    </p:option>
    <p:option name="temp-dir" select="''">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Empty directory dedicated to this conversion. May be left empty in which case a
            temporary directory will be automaticall created.</p>
        </p:documentation>
    </p:option>
    <p:option name="output-validation" cx:type="off|report|abort" select="'off'">
        <p:documentation>
            Determines whether to validate the EPUB output and what to do on validation
            errors. Defaults to 'off'.
        </p:documentation>
    </p:option>
    <p:option name="chunk-size" required="false" select="'-1'"/>
    <p:option name="audio" required="false" select="'false'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2>Enable Text-To-Speech</h2>
            <p>Whether to use a speech synthesizer to produce audio files.</p>
        </p:documentation>
    </p:option>
    <p:option name="audio-file-type" select="'audio/mpeg'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>The desired file type of the generated audio files, specified as a MIME type.</p>
            <p>Examples:</p>
            <ul>
                <li>"audio/mpeg"</li>
                <li>"audio/x-wav" (but note that this is not a core media type)</li>
            </ul>
        </p:documentation>
    </p:option>
    <p:option name="process-css" required="false" select="'true'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <p>Set to false to bypass aural CSS processing.</p>
        </p:documentation>
    </p:option>

    <p:import href="zedai-to-opf-metadata.xpl">
        <p:documentation>
            px:zedai-to-opf-metadata
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/zedai-to-html/library.xpl">
        <p:documentation>
            px:zedai-to-html
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/html-to-epub3/library.xpl">
        <p:documentation>
            px:html-to-epub3
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl">
        <p:documentation>
            px:fileset-load
            px:fileset-update
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl">
        <p:documentation>
            px:assert
        </p:documentation>
    </p:import>
    <p:import href="http://www.daisy.org/pipeline/modules/css-utils/library.xpl">
        <p:documentation>
            px:css-speech-cascade
        </p:documentation>
    </p:import>

    <p:variable name="epub-dir" select="concat($output-dir,'epub/')"/>
    <p:variable name="content-dir" select="concat($epub-dir,'EPUB/')"/>

    <!--=========================================================================-->
    <!-- GET ZEDAI FROM FILESET                                                  -->
    <!--=========================================================================-->

    <p:documentation>Retreive the ZedAI document from the input fileset.</p:documentation>
    <px:fileset-load media-types="application/z3998-auth+xml" name="load-zedai">
        <p:input port="in-memory">
            <p:pipe step="main" port="in-memory.in"/>
        </p:input>
    </px:fileset-load>
    <!-- TODO: describe the error on the wiki and insert correct error code -->
    <px:assert message="No XML documents with the ZedAI media type ('application/z3998-auth+xml') found in the fileset."
               test-count-min="1" error-code="PEZE00"/>
    <px:assert message="More than one XML document with the ZedAI media type ('application/z3998-auth+xml') found in the fileset; there can only be one ZedAI document."
               test-count-max="1" error-code="PEZE00"/>
    <p:identity name="zedai"/>

    <!--=========================================================================-->
    <!-- CSS INLINING                                                            -->
    <!--=========================================================================-->
    <p:choose>
        <p:when test="$audio='true' and $process-css='true'">
            <p:sink/>
            <px:css-speech-cascade content-type="application/z3998-auth+xml" name="cascade">
                <p:input port="source.fileset">
                    <p:pipe step="load-zedai" port="result.fileset"/>
                </p:input>
                <p:input port="source.in-memory">
                    <p:pipe step="zedai" port="result"/>
                </p:input>
                <p:with-option name="user-stylesheet" select="$stylesheet"/>
            </px:css-speech-cascade>
            <p:sink/>
            <p:identity>
                <p:input port="source">
                    <p:pipe step="cascade" port="result.in-memory"/>
                </p:input>
            </p:identity>
        </p:when>
        <p:otherwise>
            <p:identity/>
        </p:otherwise>
    </p:choose>
    <p:identity name="zedai-with-css"/>

    <!--=========================================================================-->
    <!-- METADATA                                                                -->
    <!--=========================================================================-->

    <p:documentation>Extract metadata from ZedAI</p:documentation>
    <px:zedai-to-opf-metadata name="metadata"/>
    <p:sink/>

    <!--=========================================================================-->
    <!-- CONVERT TO XHTML                                                        -->
    <!--=========================================================================-->

    <px:fileset-update name="fileset-with-css">
        <p:input port="source.fileset">
            <p:pipe step="main" port="fileset.in"/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="main" port="in-memory.in"/>
        </p:input>
        <p:input port="update.fileset">
            <p:pipe step="load-zedai" port="result.fileset"/>
        </p:input>
        <p:input port="update.in-memory">
            <p:pipe step="zedai-with-css" port="result"/>
        </p:input>
    </px:fileset-update>

    <px:zedai-to-html chunk="true" name="zedai-to-html">
        <p:input port="in-memory.in">
            <p:pipe step="fileset-with-css" port="result.in-memory"/>
        </p:input>
        <p:with-option name="output-dir" select="$content-dir"/>
        <p:with-option name="chunk-size" select="$chunk-size"/>
    </px:zedai-to-html>

    <!--=========================================================================-->
    <!-- CREATE EPUB                                                             -->
    <!--=========================================================================-->

    <px:html-to-epub3 name="html-to-epub3" skip-cleanup="true" process-css="false">
        <p:input port="input.in-memory">
            <p:pipe step="zedai-to-html" port="in-memory.out"/>
        </p:input>
        <p:input port="metadata">
            <p:pipe step="metadata" port="result"/>
        </p:input>
        <p:input port="tts-config">
            <p:pipe step="main" port="tts-config"/>
        </p:input>
        <p:with-option name="audio" select="$audio"/>
        <p:with-option name="audio-file-type" select="$audio-file-type"/>
        <p:with-option name="include-tts-log" select="$include-tts-log"/>
        <p:with-option name="output-dir" select="concat($output-dir,'epub/')"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
        <p:with-option name="output-validation" select="$output-validation"/>
    </px:html-to-epub3>
    <p:sink/>

    <!--=========================================================================-->
    <!-- STATUS                                                                  -->
    <!--=========================================================================-->

    <p:rename match="/*" new-name="d:validation-status" name="status">
        <p:input port="source">
            <p:pipe step="html-to-epub3" port="status"/>
        </p:input>
    </p:rename>
    <p:sink/>

</p:declare-step>
