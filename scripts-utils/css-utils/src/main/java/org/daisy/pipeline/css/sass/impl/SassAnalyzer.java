package org.daisy.pipeline.css.sass.impl;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamSource;

import com.google.common.io.CharStreams;

import cz.vutbr.web.css.NetworkProcessor;
import cz.vutbr.web.csskit.DefaultNetworkProcessor;
import cz.vutbr.web.csskit.antlr.CSSSource;
import cz.vutbr.web.csskit.antlr.CSSSourceReader;
import cz.vutbr.web.csskit.antlr.DefaultCSSSourceReader;
import cz.vutbr.web.domassign.GenericTreeWalker;
import cz.vutbr.web.csskit.antlr.CSSSourceReader.CSSInputStream;

import org.antlr.runtime.ANTLRReaderStream;
import org.antlr.runtime.CharStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

import org.daisy.common.file.URLs;
import org.daisy.pipeline.css.Medium;
import org.daisy.pipeline.datatypes.DatatypeRegistry;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.w3c.dom.Attr;
import org.w3c.dom.CharacterData;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.traversal.DocumentTraversal;
import org.w3c.dom.traversal.NodeFilter;
import org.w3c.dom.traversal.TreeWalker;

import org.xml.sax.SAXException;

public class SassAnalyzer {

	private static final Logger logger = LoggerFactory.getLogger(SassAnalyzer.class.getName());

	private final Medium medium;
	private final CSSSourceReader cssReader;
	final DatatypeRegistry datatypes; // also used in SassDocumentationParser

	public SassAnalyzer(Medium medium, URIResolver uriResolver, DatatypeRegistry datatypes) {
		this.medium = medium;
		this.datatypes = datatypes;
		NetworkProcessor network = new DefaultNetworkProcessor() {
				@Override
				public Reader fetch(URL url, Charset encoding, boolean forceEncoding, boolean assertEncoding)
					throws IOException {

					logger.debug("Fetching style sheet: " + url);
					if (uriResolver != null) {
						Source resolved; {
							try {
								resolved = uriResolver.resolve(URLs.asURI(url).toASCIIString(), ""); }
							catch (TransformerException e) {
								throw new IOException(e); }}
						if (resolved != null) {
							if (resolved instanceof StreamSource) {
								InputStreamReader r = detectEncodingAndSkipBOM(
									((StreamSource)resolved).getInputStream(), null, encoding, forceEncoding);
								if (assertEncoding) {
									if (encoding == null)
										throw new IllegalArgumentException("encoding must not be null");
									if (!encoding.equals(getEncoding(r)))
										throw new IOException("Failed to read URL as " + encoding + ": " + url);
								}
								return r;
							} else {
								url = new URL(resolved.getSystemId());
							}
						}
					}
					return super.fetch(url, encoding, forceEncoding, assertEncoding);
				}
			};
		cssReader = new DefaultCSSSourceReader(network) {
				@Override
				public boolean supportsMediaType(String mediaType, URL url) {
					if ("text/css".equals(mediaType) || "text/x-scss".equals(mediaType))
						return true;
					else if (mediaType == null
					         && (url == null || url.toString().endsWith(".css") || url.toString().endsWith(".scss")))
						return true;
					else
						return false;
				}
				// the returned CSSInputStream contains the original (unprocessed) file
				@Override
				public CSSInputStream read(CSSSource source) throws IOException {
					if (source.type == CSSSource.SourceType.URL) {
						URL url = (URL)source.source;
						if (url != null && !url.toString().endsWith(".css") && !url.toString().endsWith(".scss"))
							// check whether the resource exists when ".scss" is added
							try {
								return read(new CSSSource(new URL(url.toString() + ".scss"), source.encoding, source.mediaType));
							} catch (IOException e) {
								// ... or ".css" is added
								try {
									return read(new CSSSource(new URL(url.toString() + ".css"), source.encoding, source.mediaType));
								} catch (IOException ee) {
								}
								// ... or "_" and ".scss" are added
								try {
									String fileName = url.toString();
									fileName = fileName.substring(fileName.lastIndexOf('/') + 1, fileName.length());
									return read(new CSSSource(URLs.asURL(URLs.asURI(url).resolve("_" + fileName + ".scss")),
									                          source.encoding,
									                          source.mediaType));
								} catch (IOException ee) {
								}
								// ... or "_index.scss" is added
								try {
									return read(new CSSSource(new URL(url.toString() + "/_index.scss"), source.encoding, source.mediaType));
								} catch (IOException ee) {
								}
								// otherwise fail
								throw e;
							}
						if (uriResolver != null) {
							try {
								// NetworkProcessor.fetch() also does resolve() but we need an additional resolve() to give
								// CSSInputStream the correct base URL
								Source resolved = uriResolver.resolve(URLs.asURI(url).toASCIIString(), "");
								if (resolved != null)
									source = new CSSSource(new URL(resolved.getSystemId()), source.encoding, source.mediaType);
							} catch (TransformerException e) {
								throw new IOException(e);
							}
						}
					}
					return super.read(source);
				}
		};
	}

	public Collection<SassVariable> getVariableDeclarations(Iterable<Source> userStylesheets, Source sourceDocument)
			throws IOException {

		List<CSSSource> stylesheets = new ArrayList<>();
		for (Source s : userStylesheets) {
			URL base; {
				String systemId = s.getSystemId();
				if (systemId == null || "".equals(systemId))
					base = null;
				else {
					URI baseURI = URLs.asURI(systemId);
					if (baseURI.isOpaque() || !baseURI.isAbsolute())
						throw new IllegalArgumentException("not an absolute hierarchical base URI: " + baseURI);
					base = URLs.asURL(baseURI);
				}
			}
			if (s instanceof StreamSource) {
				StreamSource ss = (StreamSource)s;
				Reader r = ss.getReader();
				if (r == null)
					r = new InputStreamReader(ss.getInputStream(), StandardCharsets.UTF_8);
				stylesheets.add(new CSSSource(CharStreams.toString(r), null, base, 0, 0));
			} else {
				if (base == null)
					throw new IllegalArgumentException("empty base URI");
				stylesheets.add(new CSSSource(base, StandardCharsets.UTF_8, null));
			}
		}
		if (sourceDocument != null) {
			try {
				URL base; {
					String systemId = sourceDocument.getSystemId();
					if (systemId == null || "".equals(systemId))
						base = null;
					else {
						URI baseURI = URLs.asURI(systemId);
						if (baseURI.isOpaque() || !baseURI.isAbsolute())
							throw new IllegalArgumentException("not an absolute hierarchical base URI: " + baseURI);
						base = URLs.asURL(baseURI);
					}
				}
				DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
				factory.setNamespaceAware(true);
				Document doc = factory.newDocumentBuilder().parse(SAXSource.sourceToInputSource(sourceDocument));
				new Traversal(doc) {
					@Override
					protected void processElement(Element e) {
						if ("style".equalsIgnoreCase(e.getNodeName())) {
							Attr media = e.getAttributeNode("media");
							if (media != null ? medium.matches(media.getValue()) : medium.asMediaSpec().matchesEmpty()) {
								Attr type = e.getAttributeNode("type");
								String mediaType = type != null ? type.getValue().toLowerCase() : null;
								if (cssReader.supportsMediaType(mediaType, null))
									stylesheets.add(new CSSSource(extractElementText(e), mediaType, base, -1, -1));
							}
						} else if ("link".equalsIgnoreCase(e.getNodeName())) {
							Attr rel = e.getAttributeNode("rel");
							if (rel != null && rel.getValue().toLowerCase().contains("stylesheet")) {
								Attr href = e.getAttributeNode("href");
								if (href != null) {
									Attr media = e.getAttributeNode("media");
									if (media != null ? medium.matches(media.getValue()) : medium.asMediaSpec().matchesEmpty()) {
										URL url; {
											try {
												URI uri = URLs.asURI(href.getValue());
												if (base != null)
													uri = URLs.resolve(URLs.asURI(base), uri);
												url = URLs.asURL(uri);
											} catch (RuntimeException ex) {
												throw new UncheckedIOException(new IOException(ex));
											}
										}
										Attr type = e.getAttributeNode("type");
										String mediaType = type != null ? type.getValue().toLowerCase() : null;
										if (cssReader.supportsMediaType(mediaType, url))
											stylesheets.add(new CSSSource(url, null, mediaType));
									}
								}
							}
						}
					}
				}.traverse();
			} catch (UncheckedIOException e) {
				throw e.getCause();
			} catch (SAXException|ParserConfigurationException e) {
				throw new IOException(e);
			}
		}
		return getVariableDeclarations(stylesheets.toArray(new CSSSource[stylesheets.size()]));
	}

	Collection<SassVariable> getVariableDeclarations(CSSSource... stylesheets) throws IOException {
		List<SassVariable> vars = new ArrayList<>();
		try {
			for (CSSSource source : stylesheets) {
				CSSInputStream s = cssReader.read(source);
				CharStream input = new ANTLRReaderStream(s.stream);
				SassDocumentationLexer lexer = new SassDocumentationLexer(input);
				CommonTokenStream tokens = new CommonTokenStream(lexer);
				SassDocumentationParser parser = new SassDocumentationParser(tokens).init(
					"text/x-scss".equals(source.mediaType) || (s.base != null && s.base.toString().endsWith(".scss")),
					s.base != null ? URLs.asURI(s.base) : null,
					this);
				vars.addAll(parser.variables());
			}
		} catch (RecognitionException e) {
			throw new RuntimeException("Error happened while parsing the SCSS", e);
		}
		return vars;
	}

	private static abstract class Traversal {
		private final TreeWalker walker;
		protected Traversal(Document doc) {
			if (doc instanceof DocumentTraversal)
				walker = ((DocumentTraversal)doc).createTreeWalker(doc.getDocumentElement(), NodeFilter.SHOW_ELEMENT, null, false);
			else
				walker = new GenericTreeWalker(doc.getDocumentElement(), NodeFilter.SHOW_ELEMENT);
		}
		protected abstract void processElement(Element element);
		public void traverse() {
			Node current, checkpoint = null;
			current = walker.getCurrentNode();
			while (current != null) {
				checkpoint = walker.getCurrentNode();
				processElement((Element)current);
				walker.setCurrentNode(checkpoint);
				current = walker.nextNode();
			}
		}
	}

	private static String extractElementText(Element e) {
		StringBuilder s = new StringBuilder();
		NodeList children = e.getChildNodes();
		for (int i = 0; i < children.getLength(); i++) {
			Node child = children.item(i);
			if (child.getNodeType() == Node.TEXT_NODE || child.getNodeType() == Node.CDATA_SECTION_NODE)
				s.append(((CharacterData)child).getData());
			else if (child.getNodeType() == Node.COMMENT_NODE)
				s.append("<!--").append(((CharacterData)child).getData()).append("-->");
		}
		return s.toString();
	}
}
