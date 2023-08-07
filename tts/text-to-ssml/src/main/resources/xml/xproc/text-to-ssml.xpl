<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="px:text-to-ssml" version="1.0" name="main"
		xmlns:p="http://www.w3.org/ns/xproc"
		xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
		xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
		xmlns:ssml="http://www.w3.org/2001/10/synthesis"
		xmlns:tts="http://www.daisy.org/ns/pipeline/tts"
		xmlns:m="http://www.w3.org/1998/Math/MathML"
		exclude-inline-prefixes="#all">

  <p:documentation>
    Generate the TTS input, as SSML snippets.
  </p:documentation>

  <p:input port="fileset.in" sequence="false"/>
  <p:input port="content.in"  sequence="false" primary="true">
    <p:documentation>The content documents (e.g. a Zedai document, a DTBook)</p:documentation>
  </p:input>
  <p:input port="sentence-ids" sequence="false">
    <p:documentation>The list of the sentence ids, as a document with <code>id</code> attributes.</p:documentation>
  </p:input>
  <p:input port="skippable-ids">
    <p:documentation>The optional list of skippable elements, as a document with <code>id</code>
    attributes. Skippable elements are extracted from the normal flow and SSML marks are inserted at
    their original position.</p:documentation>
    <p:inline>
      <ssml:skippables/>
    </p:inline>
  </p:input>
  <p:input port="user-lexicons">
    <p:documentation>Lexicons from the config file</p:documentation>
  </p:input>
  <p:input port="annotations" sequence="true">
    <p:documentation>XSLT Stylesheets to annotate the content</p:documentation>
    <p:empty/>
  </p:input>

  <p:output port="result" sequence="true" primary="true">
    <p:documentation>The SSML output. SSML documents have the same base URI as the
    <code>content.in</code> document.</p:documentation>
  </p:output>

  <p:option name="word-element" required="true">
    <p:documentation>Element used to identify words within sentences,
    together with its attribute 'word-attr'.</p:documentation>
  </p:option>
  <p:option name="word-attr" required="false" select="''"/>
  <p:option name="word-attr-val" required="false" select="''"/>

  <p:option name="lang" required="false" select="'en'">
    <p:documentation>Default language.</p:documentation>
  </p:option>

  <p:import href="http://www.daisy.org/pipeline/modules/mathml-to-ssml/library.xpl">
    <p:documentation>
      px:mathml-to-ssml
    </p:documentation>
  </p:import>
  <p:import href="annotate.xpl">
    <p:documentation>
      pxi:annotate
    </p:documentation>
  </p:import>
  <p:import href="css-to-ssml.xpl">
    <p:documentation>
      pxi:css-to-ssml
    </p:documentation>
  </p:import>
  <p:import href="apply-lexicons.xpl">
    <p:documentation>
      pxi:apply-lexicons
    </p:documentation>
  </p:import>
  <p:import href="extract-skippable.xpl">
    <p:documentation>
      pxi:extract-skippable
    </p:documentation>
  </p:import>
  <p:import href="extract-mathml.xpl">
    <p:documentation>
      pxi:extract-mathml
    </p:documentation>
  </p:import>
  <p:import href="reorder-sentences.xpl">
    <p:documentation>
      pxi:reorder-sentences
    </p:documentation>
  </p:import>

  <p:variable name="style-ns" select="'http://www.daisy.org/ns/pipeline/tts'"/>


  <!-- Description: insert text before and/or after particular nodes. Requirements: (1)
       the document must have been kept intact as much as possible, because annotations
       are authored by end-users according to their expectations of the output and its
       format (e.g. DTBook, HTML). This is why annotating should be performed first. -->
  <pxi:annotate name="annotate">
    <p:input port="annotations">
      <p:pipe port="annotations" step="main"/>
    </p:input>
    <p:input port="sentence-ids">
      <p:pipe port="sentence-ids" step="main"/>
    </p:input>
  </pxi:annotate>

  <!-- Replace sentences and words with their SSML counterparts so that it will be much
       simpler and faster to apply transformations later.  -->
  <p:xslt name="normalize">
    <p:with-param name="word-element" select="$word-element"/>
    <p:with-param name="word-attr" select="$word-attr"/>
    <p:with-param name="word-attr-val" select="$word-attr-val"/>
    <p:input port="source">
      <p:pipe port="result" step="annotate"/>
      <p:pipe port="sentence-ids" step="main"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xslt/normalize.xsl"/>
    </p:input>
  </p:xslt>

  <!-- Description: flatten the document structure by keeping only the sentences, taking
       CSS into consideration. Requirements : (1) sentences have been transformed into
       SSML <s>, (2) it keeps intact the structure inside sentences so as to keep inner
       CSS properties and skippable @ids. -->
  <p:xslt name="flatten">
    <p:with-param name="lang" select="$lang"/>
    <p:with-param name="style-ns" select="$style-ns"/>
    <p:input port="stylesheet">
      <p:document href="../xslt/flatten-structure.xsl"/>
    </p:input>
  </p:xslt>

  <!-- Description: replace skippable elements with SSML marks and move them to a separate
       document (including MathML). Requirements: (1) it keeps intact the structure inside
       sentences so as to keep inner CSS properties. -->
  <pxi:extract-skippable name="separate-skippable">
    <p:input port="sentence-ids">
      <p:pipe port="sentence-ids" step="main"/>
    </p:input>
    <p:input port="skippable-ids">
      <p:pipe port="skippable-ids" step="main"/>
    </p:input>
  </pxi:extract-skippable>

  <pxi:extract-mathml name="main-doc-separate-math">
    <p:input port="math-ids">
      <p:pipe port="content.in" step="main"/>
    </p:input>
  </pxi:extract-mathml>

  <!-- Description: convert CSS inside the sentences of the skippable-free
       document. Requirements: (1) structure inside sentences still there. -->
  <pxi:css-to-ssml/>

  <!-- Description: replace some SSML tokens with other tokens or a phonetic
       translation. Requirements: (1) clean input with all words wrapped into SSML
       tokens. -->
  <pxi:apply-lexicons>
    <p:input port="user-lexicons">
      <p:pipe port="user-lexicons" step="main"/>
    </p:input>
    <p:input port="fileset">
      <p:pipe port="fileset.in" step="main"/>
    </p:input>
    <p:with-option name="lang" select="$lang"/>
  </pxi:apply-lexicons>

  <!-- Description: remove unsolicited chars from the skippable-free
       document. Requirements: (1) All words wrapped into SSML tokens (2) Cannot be
       applied on MathML because of the 1st requirement. -->
  <p:xslt name="clean-doc">
    <p:input port="stylesheet">
      <p:document href="../xslt/filter-chars.xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
  </p:xslt>

  <!-- =================================================== -->
  <!-- ========= SKIPPABLE ELEMENTS PROCESSING =========== -->


  <pxi:extract-mathml name="skippable-doc-separate-math">
    <p:input port="source">
      <p:pipe port="skippable-only" step="separate-skippable"/>
    </p:input>
    <p:input port="math-ids">
      <p:pipe port="content.in" step="main"/>
    </p:input>
  </pxi:extract-mathml>

  <!-- Description: generate the SSML document dedicated to skippable elements. The
       document will group together elements that share the same CSS
       properties. Everything is converted but the content of the skippable-elements (in
       most cases they are mere numbers).-->
  <p:xslt>
    <p:with-param name="style-ns" select="$style-ns"/>
    <p:with-param name="lang" select="$lang"/>
    <p:input port="stylesheet">
      <p:document href="../xslt/skippable-to-ssml.xsl"/>
    </p:input>
  </p:xslt>

  <pxi:css-to-ssml name="ssml-of-skippable"/>

  <!-- =================================================== -->
  <!-- ===================== MATHML ====================== -->

  <px:mathml-to-ssml>
    <p:input port="source">
      <p:pipe port="mathml-only" step="main-doc-separate-math"/>
      <p:pipe port="mathml-only" step="skippable-doc-separate-math"/>
    </p:input>
  </px:mathml-to-ssml>
  <pxi:css-to-ssml name="ssml-of-math"/>

  <!-- put everything back in order -->
  <pxi:reorder-sentences>
    <p:input port="source">
      <p:pipe port="result" step="clean-doc"/>
      <p:pipe port="result" step="ssml-of-skippable"/>
      <p:pipe port="result" step="ssml-of-math"/>
    </p:input>
    <p:with-option name="ids-in-order" select="distinct-values(//ssml:s/descendant-or-self::*/@id/string(.))">
      <p:pipe step="normalize" port="result"/>
    </p:with-option>
  </pxi:reorder-sentences>

</p:declare-step>
