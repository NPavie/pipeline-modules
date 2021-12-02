package org.daisy.pipeline.css;

import java.io.InputStream;
import java.io.IOException;
import java.net.URL;
import java.net.URI;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.function.Function;

import javax.xml.namespace.QName;
import javax.xml.stream.XMLStreamException;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.URIResolver;

import com.google.common.collect.Iterables;

import cz.vutbr.web.css.CSSFactory;
import cz.vutbr.web.css.Declaration;
import cz.vutbr.web.css.MediaSpec;
import cz.vutbr.web.css.NetworkProcessor;
import cz.vutbr.web.css.NodeData;
import cz.vutbr.web.css.RuleFactory;
import cz.vutbr.web.css.Selector.PseudoElement;
import cz.vutbr.web.css.SourceLocator;
import cz.vutbr.web.css.StyleSheet;
import cz.vutbr.web.css.SupportedCSS;
import cz.vutbr.web.css.Term;
import cz.vutbr.web.css.TermIdent;
import cz.vutbr.web.css.TermInteger;
import cz.vutbr.web.css.TermString;
import cz.vutbr.web.csskit.antlr.CSSParserFactory;
import cz.vutbr.web.csskit.antlr.CSSSource;
import cz.vutbr.web.csskit.antlr.CSSSourceReader;
import cz.vutbr.web.csskit.antlr.DefaultCSSSourceReader;
import cz.vutbr.web.csskit.antlr.SourceMap;
import cz.vutbr.web.csskit.DefaultNetworkProcessor;
import cz.vutbr.web.csskit.RuleXslt;
import cz.vutbr.web.domassign.Analyzer;
import cz.vutbr.web.domassign.DeclarationTransformer;
import cz.vutbr.web.domassign.StyleMap;
import net.sf.saxon.dom.NodeOverNodeInfo;
import net.sf.saxon.om.NodeInfo;

import org.apache.commons.io.input.BOMInputStream;

import org.daisy.common.file.URLs;
import org.daisy.common.stax.BaseURIAwareXMLStreamWriter;
import static org.daisy.common.stax.XMLStreamWriterHelper.writeAttribute;
import static org.daisy.common.stax.XMLStreamWriterHelper.writeCharacters;
import static org.daisy.common.stax.XMLStreamWriterHelper.writeComment;
import static org.daisy.common.stax.XMLStreamWriterHelper.writeProcessingInstruction;
import static org.daisy.common.stax.XMLStreamWriterHelper.writeStartElement;
import org.daisy.common.transform.InputValue;
import org.daisy.common.transform.Mult;
import org.daisy.common.transform.SingleInSingleOutXMLTransformer;
import org.daisy.common.transform.TransformerException;
import org.daisy.common.transform.XMLInputValue;
import org.daisy.common.transform.XMLOutputValue;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

public abstract class JStyleParserCssCascader extends SingleInSingleOutXMLTransformer {

	private final String defaultStyleSheets;
	private final MediaSpec medium;
	private final QName attributeName;
	private final CSSParserFactory parserFactory;
	private final RuleFactory ruleFactory;
	private final SupportedCSS supportedCSS;
	private final DeclarationTransformer declarationTransformer;
	private final CSSSourceReader cssReader;
	private final XsltProcessor xsltProcessor;

	private static final Logger logger = LoggerFactory.getLogger(JStyleParserCssCascader.class);

	public JStyleParserCssCascader(URIResolver uriResolver,
	                               CssPreProcessor preProcessor,
	                               XsltProcessor xsltProcessor,
	                               String defaultStyleSheets,
	                               Medium medium,
	                               QName attributeName,
	                               CSSParserFactory parserFactory,
	                               RuleFactory ruleFactory,
	                               SupportedCSS supportedCSS,
	                               DeclarationTransformer declarationTransformer) {
		this.defaultStyleSheets = defaultStyleSheets;
		this.medium = medium.asMediaSpec();
		this.attributeName = attributeName;
		this.parserFactory = parserFactory;
		this.ruleFactory = ruleFactory;
		this.supportedCSS = supportedCSS;
		this.declarationTransformer = declarationTransformer;
		this.xsltProcessor = xsltProcessor;
		NetworkProcessor network = new DefaultNetworkProcessor() {
				@Override
				public InputStream fetch(URL url) throws IOException {
					InputStream is;
					logger.debug("Fetching style sheet: " + url);
					Source resolved; {
						try {
							resolved = uriResolver.resolve(URLs.asURI(url).toASCIIString(), ""); }
						catch (javax.xml.transform.TransformerException e) {
							throw new IOException(e); }}
					if (resolved != null && resolved instanceof StreamSource)
						is = ((StreamSource)resolved).getInputStream();
					else {
						if (resolved != null)
							url = new URL(resolved.getSystemId());
						is = super.fetch(url);
					}
					// skip BOM
					is = new BOMInputStream(is);
					return is;
				}
			};
		/*
		 * CSSSourceReader that handles media types supported by preProcessor. Throws a
		 * IOException if something goes wrong when resolving the source or if the
		 * pre-processing fails.
		 */
		this.cssReader = new DefaultCSSSourceReader(network) {
				@Override
				public boolean supportsMediaType(String mediaType, URL url) {
					if ("text/css".equals(mediaType))
						return true;
					else if (mediaType == null && (url == null || url.toString().endsWith(".css")))
						return true;
					else if (preProcessor == null)
						return false;
					else
						return preProcessor.supportsMediaType(mediaType, url);
				}
				@Override
				public CSSInputStream read(CSSSource source) throws IOException {
					if (source.type == CSSSource.SourceType.URL) {
						try {
							Source resolved = uriResolver.resolve(URLs.asURI((URL)source.source).toASCIIString(), "");
							if (resolved != null)
								source = new CSSSource(new URL(resolved.getSystemId()), source.encoding, source.mediaType);
						} catch (javax.xml.transform.TransformerException e) {
							throw new IOException(e);
						}
					}
					CSSInputStream stream = super.read(source);
					if (!("text/css".equals(source.mediaType)
					      || source.mediaType == null && (source.type != CSSSource.SourceType.URL
					                                      || ((URL)source.source).toString().endsWith(".css")))) {
						// preProcessor must be non-null
						try {
							CssPreProcessor.PreProcessingResult result
								= preProcessor.compile(stream.stream, stream.base, stream.encoding);
							SourceMap sourceMap; {
								if (result.sourceMap != null) {
									SourceMap m = SourceMapReader.read(result.sourceMap, result.base);
									if (stream.sourceMap != null) {
										sourceMap = new SourceMap() {
											public SourceLocator get(int line, int column) {
												SourceLocator loc = m.get(line, column);
												if (loc != null && loc.getURL().equals(stream.base))
													loc = stream.sourceMap.get(loc.getLineNumber(), loc.getColumnNumber());
												return loc;
											}
											public SourceLocator floor(int line, int column) {
												SourceLocator loc = m.floor(line, column);
												if (loc != null && loc.getURL().equals(stream.base))
													loc = stream.sourceMap.floor(loc.getLineNumber(), loc.getColumnNumber());
												return loc;
											}
											public SourceLocator ceiling(int line, int column) {
												SourceLocator loc = m.ceiling(line, column);
												if (loc != null && loc.getURL().equals(stream.base))
													loc = stream.sourceMap.ceiling(loc.getLineNumber(), loc.getColumnNumber());
												return loc;
											}
										};
									} else
										sourceMap = m;
								} else
									sourceMap = stream.sourceMap;
							}
							return new CSSInputStream(result.stream, stream.encoding, stream.base, sourceMap);
						} catch (RuntimeException e) {
							throw new IOException(
								(source.mediaType != null ? (source.mediaType + " p") : "P")
								+ "re-processing failed: " + e.getMessage(), e);
						}
					} else
						return stream;
				}
			};
	}

	private StyleSheet styleSheet = null;

	public Runnable transform(XMLInputValue<?> source, XMLOutputValue<?> result, InputValue<?> params) throws TransformerException {
		if (source == null || result == null)
			throw new TransformerException(new IllegalArgumentException());
		return () -> transform(source.ensureSingleItem().mult(2), result.asXMLStreamWriter());
	}

	private void transform(Mult<? extends XMLInputValue<?>> source, BaseURIAwareXMLStreamWriter output) throws TransformerException {
		Node node = source.get().asNodeIterator().next();
		if (!(node instanceof Document))
			throw new TransformerException(new IllegalArgumentException());
		Document document = (Document)node;
		BaseURIAwareXMLStreamWriter writer = output;
		try {
			URI baseURI = new URI(document.getBaseURI());
			Function<Node,SourceLocator> nodeLocator = n -> {
				if (n instanceof NodeOverNodeInfo) {
					NodeInfo info = ((NodeOverNodeInfo)n).getUnderlyingNodeInfo();
					return new SourceLocator() {
						public URL getURL() {
							return URLs.asURL(URI.create(info.getBaseURI()));
						}
						public int getLineNumber() {
							return info.getLineNumber();
						}
						public int getColumnNumber() {
							return info.getColumnNumber();
						}
					};
				} else {
					return new SourceLocator() {
						public URL getURL() {
							return URLs.asURL(URI.create(n.getBaseURI()));
						}
						public int getLineNumber() {
							return 0;
						}
						public int getColumnNumber() {
							return 0;
						}
					};
				}
			};
			StyleMap styleMap;
			synchronized(JStyleParserCssCascader.class) {
				// CSSParserFactory injected in CSSAssignTraversal.<init> in CSSFactory.getUsedStyles
				CSSFactory.registerCSSParserFactory(parserFactory);
				// RuleFactory injected in
				// - SimplePreparator.<init> in CSSParserFactory.append in CSSFactory.getUsedStyles
				// - CSSTreeParser.<init> in CSSParserFactory.append in CSSFactory.getUsedStyles
				CSSFactory.registerRuleFactory(ruleFactory);
				// DeclarationTransformer injected in SingleMapNodeData.<init> in CSSFactory.createNodeData in Analyzer.evaluateDOM
				CSSFactory.registerDeclarationTransformer(declarationTransformer);
				// SupportedCSS injected in
				// - SingleMapNodeData.<init> in CSSFactory.createNodeData in Analyzer.evaluateDOM
				// - Repeater.assignDefaults in DeclarationTransformer.parseDeclaration in SingleMapNodeData.push in Analyzer.evaluateDOM
				// - Variator.assignDefaults in DeclarationTransformer.parseDeclaration in SingleMapNodeData.push in Analyzer.evaluateDOM
				CSSFactory.registerSupportedCSS(supportedCSS);
				StyleSheet defaultStyleSheet = (StyleSheet)ruleFactory.createStyleSheet().unlock();
				if (defaultStyleSheets != null) {
					StringTokenizer t = new StringTokenizer(defaultStyleSheets);
					while (t.hasMoreTokens()) {
						URL u = URLs.asURL(URLs.resolve(baseURI, URLs.asURI(t.nextToken())));
						if (!cssReader.supportsMediaType(null, u))
							logger.warn("Style sheet type not supported: " + u);
						else
							defaultStyleSheet
								= parserFactory.append(new CSSSource(u, (Charset)null, (String)null), cssReader, defaultStyleSheet);
					}
				}
				styleSheet = (StyleSheet)ruleFactory.createStyleSheet().unlock();
				styleSheet.addAll(defaultStyleSheet);
				styleSheet = CSSFactory.getUsedStyles(document, null, nodeLocator, medium, cssReader, styleSheet);
				XMLInputValue<?> transformed = null;
				for (RuleXslt r : Iterables.filter(styleSheet, RuleXslt.class)) {
					Map<String,String> params = new HashMap<>();
					for (Declaration d : r) {
						StringBuilder val = new StringBuilder();
						boolean invalid = false;
						for (Term<?> t : d) {
							if (t instanceof TermIdent || t instanceof TermString) {
								if (val.length() > 0) val.append(' ');
								val.append(((Term<String>)t).getValue());
							} else if (t instanceof TermInteger) {
								if (val.length() > 0) val.append(' ');
								val.append(""+((TermInteger)t).getIntValue());
							} else {
								logger.warn("@xslt parameter value must be a sequence of string, ident or integer, but got " + d);
								invalid = true;
								break;
							}
						}
						if (!invalid)
							params.put(d.getProperty(), val.toString());
					}
					transformed = xsltProcessor.transform(
						URLs.resolve(URLs.asURI(r.base), URLs.asURI(r.uri)),
						transformed != null ? transformed : source.get(),
						params);
				}
				if (transformed != null) {
					node = transformed.ensureSingleItem().asNodeIterator().next();
					if (!(node instanceof Document))
						throw new TransformerException(
							new RuntimeException("XsltProcessor must return a (single) document"));
					document = (Document)node;
					// We assume that base URI did not change.
					// We need to recompute the stylesheet because of any possible inline styles, which
					// are attached to an element in the original document.
					styleSheet = (StyleSheet)ruleFactory.createStyleSheet().unlock();
					styleSheet.addAll(defaultStyleSheet);
					styleSheet = CSSFactory.getUsedStyles(document, null, nodeLocator, medium, cssReader, styleSheet);
				}
				styleMap = new Analyzer(styleSheet).evaluateDOM(document, medium, false);
			}
			writer.setBaseURI(baseURI);
			writer.writeStartDocument();
			traverse(document.getDocumentElement(), styleMap, writer);
			writer.writeEndDocument();
		} catch (TransformerException e) {
			throw e;
		} catch (Exception e) {
			throw new TransformerException(e);
		} finally {
			styleSheet = null;
		}
	}

	protected abstract String serializeStyle(NodeData mainStyle, Map<PseudoElement,NodeData> pseudoStyles, Element context);

	protected StyleSheet getParsedStyleSheet() {
		if (styleSheet == null)
			throw new UnsupportedOperationException();
		return styleSheet;
	}

	private void traverse(Node node, StyleMap styleMap, BaseURIAwareXMLStreamWriter writer) throws XMLStreamException {
		if (node.getNodeType() == Node.ELEMENT_NODE) {
			Element elem = (Element)node;
			writeStartElement(writer, elem);
			NamedNodeMap attributes = node.getAttributes();
			for (int i = 0; i < attributes.getLength(); i++) {
				Node attr = attributes.item(i);
				if (!(attr.getPrefix() == null && "style".equals(attr.getLocalName())))
					writeAttribute(writer, attr); }
			Map<PseudoElement,NodeData> pseudoStyles = new java.util.HashMap<>(); {
				for (PseudoElement pseudo : styleMap.pseudoSet(elem))
					pseudoStyles.put(pseudo, styleMap.get(elem, pseudo)); }
			String style = serializeStyle(
				styleMap.get(elem),
				pseudoStyles,
				elem);
			if (style != null)
				writeAttribute(writer, attributeName, style);
			for (Node child = node.getFirstChild(); child != null; child = child.getNextSibling())
				traverse(child, styleMap, writer);
			writer.writeEndElement(); }
		else if (node.getNodeType() == Node.COMMENT_NODE)
			writeComment(writer, node);
		else if (node.getNodeType() == Node.TEXT_NODE)
			writeCharacters(writer, node);
		else if (node.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE)
			writeProcessingInstruction(writer, node);
		else
			throw new UnsupportedOperationException("Unexpected node type");
	}
}
