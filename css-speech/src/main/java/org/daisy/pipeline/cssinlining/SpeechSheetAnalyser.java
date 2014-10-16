package org.daisy.pipeline.cssinlining;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.io.IOUtils;
import org.w3c.dom.Document;

import cz.vutbr.web.css.CSSException;
import cz.vutbr.web.css.CSSFactory;
import cz.vutbr.web.css.StyleSheet;
import cz.vutbr.web.css.SupportedCSS;
import cz.vutbr.web.csskit.antlr.CSSParserFactory;
import cz.vutbr.web.csskit.antlr.CSSParserFactory.SourceType;
import cz.vutbr.web.domassign.Analyzer;
import cz.vutbr.web.domassign.StyleMap;
import cz.vutbr.web.domassign.SupportedCSS21;

public class SpeechSheetAnalyser {
	private static SupportedCSS SupportedCSS;
	private static final String Medium = "speech";
	private static Pattern UrlPattern = Pattern.compile("url\\('?\"?([^)'\"]+)'?\"?\\)");

	private static Pattern AbsoluteUrlPattern = Pattern
	        .compile("([a-zA-Z][-.+a-zA-Z0-9]*://)|/");

	private Analyzer mAnalyzer;

	static {
		SupportedCSS = SupportedCSS21.getInstance();
		CSSFactory.registerSupportedCSS(SupportedCSS);
		CSSFactory.registerDeclarationTransformer(new SpeechDeclarationTransformer());
	}

	public void analyse(Collection<URI> sheetURIs, Collection<String> embeddedCSS,
	        URI embedContainerURI) throws IOException, URISyntaxException, CSSException {
		if (!SupportedCSS.isSupportedMedia(Medium)) {
			throw new IllegalStateException("medium '" + Medium + "' is not supported");
		}

		List<URI> alluris = new ArrayList<URI>();
		List<String> csscode = new ArrayList<String>(embeddedCSS);
		for (int k = 0; k < embeddedCSS.size(); ++k)
			alluris.add(embedContainerURI);

		for (URI uri : sheetURIs) {
			if (uri != null) {
				alluris.add(uri);
				csscode.add(IOUtils.toString(uri.toURL().openStream(), "UTF-8"));
			}
		}

		List<StyleSheet> styleSheets = new ArrayList<StyleSheet>();
		for (int k = 0; k < csscode.size(); ++k) {
			String basePath = new File(alluris.get(k)).getParent();
			String withAbsURL = makeURLabsolute(csscode.get(k), basePath);
			styleSheets.add(CSSParserFactory.parse(withAbsURL, null, SourceType.EMBEDDED,
			        new URL("http://base")));
			//we cannot use CSSFactory.parse(withAbsURL) because it tries to convert the null base URL into String.
		}

		mAnalyzer = new Analyzer(styleSheets);
	}

	public StyleMap evaluateDOM(Document doc) {
		return mAnalyzer.evaluateDOM(doc, Medium, false);
	}

	static String makeURLabsolute(String csscode, String basePath) {
		//This ugly hack is necessary because jStyleParser fails to take into 
		//account the base URI when it parses relative URIs
		Matcher m = UrlPattern.matcher(csscode);
		while (m.find()) {
			String url = m.group(1);
			Matcher m2 = AbsoluteUrlPattern.matcher(url);
			if (!m2.lookingAt()) {
				csscode = csscode.replace(m.group(0), "url('" + Paths.get(basePath, url)
				        + "')");
			}
		}
		return csscode;
	}
}
