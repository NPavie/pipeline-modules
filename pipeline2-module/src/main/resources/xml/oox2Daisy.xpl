<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" version="1.0"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
				xmlns:xs="http://www.w3.org/2001/XMLSchema"
                type="px:oox2Daisy" name="main">

	<p:option name="source" required="true"/>
	<p:option name="document-output-dir" required="true"/>
	<p:option name="document-output-file" select="concat(
		$document-output-dir,
		replace(replace($source,'^.*/([^/]*?)(\.[^/\.]*)?$','$1.xml'),',','_')
	)"/>
	<p:option name="document-output-test" select="concat(
		$document-output-dir,
		replace(replace($source,'^.*/([^/]*?)(\.[^/\.]*)?$','$1_test.xml'),',','_')
	)"/>
	<p:option name="tempSource" select="$source"/>
	<p:option name="pipeline-output-dir" select="$document-output-dir"/>
	<p:option name="Title" select="''"/>
	<p:option name="Creator" select="''"/>
	<p:option name="Publisher" select="''"/>
	<p:option name="UID" select="''"/>
	<p:option name="Subject" select="''"/>
	<p:option name="prmTRACK" select="'NoTrack'"/>
	<p:option name="Version" select="'14'"/>

	<!-- discarding math type equations preprocessing
	<p:option name="MathML" select="map{'wdTextFrameStory':[],
	                                    'wdFootnotesStory':[],
	                                    'wdMainTextStory':[]
	                                    }" />-->
	<!-- cx:as="map(xs:string,xs:string*)" -->
	<p:option name="MasterSub" select="false()" cx:as="xs:boolean" />
	<!-- from settings  -->
	<p:option name="Custom" select="''"/>
	<p:option name="ImageSizeOption" select="'original'"/>
	<p:option name="DPI" select="96" cx:as="xs:integer"/>
	<p:option name="CharacterStyles" select="false()" cx:as="xs:boolean"/>
	<p:option name="FootnotesPosition" select="'end'"/>
	<p:option name="FootnotesLevel" select="0" cx:as="xs:integer" />
	<p:option name="FootnotesNumbering" cx:as="xs:string" select="'none'"  />
	<p:option name="FootnotesStartValue" cx:as="xs:integer" select="1" />
	<p:option name="FootnotesNumberingPrefix" cx:as="xs:string?" select="''"/>
	<p:option name="FootnotesNumberingSuffix" cx:as="xs:string?" select="''"/>

	<p:output port="result" sequence="true"/>

	<p:xslt template-name="main" name="convert-to-dtbook" cx:serialize="true">
		<p:input port="source">
			<p:empty/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="oox2Daisy.xsl"/>
		</p:input>
		<p:with-param name="OriginalInputFile" select="$source"/>
		<p:with-param name="InputFile" select="$tempSource"/>
		<p:with-param name="OutputDir" select="$document-output-dir"/>
		<p:with-param name="FinalOutputDir" select="$pipeline-output-dir"/>
		<p:with-param name="Title" select="$Title"/>
		<p:with-param name="Creator" select="$Creator"/>
		<p:with-param name="Publisher" select="$Publisher"/>
		<p:with-param name="UID" select="$UID"/>
		<p:with-param name="Subject" select="$Subject"/>
		<p:with-param name="prmTRACK" select="$prmTRACK"/>
		<p:with-param name="Version" select="$Version"/>
		<p:with-param name="Custom" select="$Custom"/>
		<p:with-param name="MasterSub" select="$MasterSub"/>
		<p:with-param name="ImageSizeOption" select="$ImageSizeOption"/>
		<p:with-param name="DPI" select="$DPI"/>
		<p:with-param name="CharacterStyles" select="$CharacterStyles"/>
		<p:with-param name="MathML" select="$MathML"/>
		<p:with-param name="FootnotesPosition" select="$FootnotesPosition"/>
		<p:with-param name="FootnotesLevel" select="$FootnotesLevel"/>
		<p:with-param name="FootnotesNumbering" select="$FootnotesNumbering"/>
		<p:with-param name="FootnotesStartValue" select="$FootnotesStartValue"/>
		<p:with-param name="FootnotesNumberingPrefix" select="$FootnotesNumberingPrefix"/>
		<p:with-param name="FootnotesNumberingSuffix" select="$FootnotesNumberingSuffix"/>
		<p:with-param name="ApplyDtbookFixRoutine" select="$ApplyDtbookFixRoutine"/>
		<p:with-param name="ApplySentenceDetection" select="$ApplySentenceDetection"/>
	</p:xslt>
	<p:store name="store-xml">
		<p:with-option name="href" select="$document-output-file"/>
	</p:store>
	<p:load cx:depends-on="store-xml">
		<p:with-option name="href" select="$document-output-file"/>
	</p:load>


</p:declare-step>
