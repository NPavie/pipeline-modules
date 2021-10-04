package org.daisy.pipeline.braille.common;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import cz.vutbr.web.css.CSSProperty;
import cz.vutbr.web.css.TermInteger;
import cz.vutbr.web.css.TermString;

import org.daisy.dotify.api.table.BrailleConverter;

import org.daisy.braille.css.SimpleInlineStyle;
import org.daisy.braille.css.BrailleCSSProperty.BrailleCharset;
import org.daisy.braille.css.BrailleCSSProperty.HyphenateCharacter;
import org.daisy.braille.css.BrailleCSSProperty.Hyphens;
import org.daisy.braille.css.BrailleCSSProperty.WhiteSpace;
import org.daisy.braille.css.BrailleCSSProperty.WordSpacing;
import org.daisy.pipeline.braille.common.AbstractBrailleTranslator;
import org.daisy.pipeline.braille.common.AbstractBrailleTranslator.util.DefaultLineBreaker;
import org.daisy.pipeline.braille.common.CSSStyledText;
import static org.daisy.pipeline.braille.common.util.Strings.join;
import static org.daisy.pipeline.braille.common.util.Strings.splitInclDelimiter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * {@link org.daisy.pipeline.braille.common.BrailleTranslator} that assumes input text exists of
 * only braille and white space characters. Supports CSS properties "word-spacing", "hyphens",
 * "hyphenate-character", "white-space", and "braille-charset".
 */
public  class UnityBrailleTranslator extends AbstractBrailleTranslator implements BrailleTranslator {

	private static final Pattern SPECIAL_CHARS = Pattern.compile("[\\x20\t\\n\\r\\u2800\\xA0\u00AD\u200B\u2028]+");

	private final BrailleConverter brailleCharset;
	private final boolean useBrailleCharsetForInput;

	/**
	 * @param brailleCharset            The character set of the output braille, and of the input in
	 *                                  case it is styled as <code>braille-charset: custom</code> or if
	 *                                  <code>useBrailleCharsetForInput</code> is <code>true</code>.
	 *                                  <code>null</code> means Unicode braille.
	 * @param useBrailleCharsetForInput Whether <code>brailleCharset</code> by default also applies to
	 *                                  the input (if it does not have a <code>braille-charset</code>
	 *                                  style).
	 */
	public UnityBrailleTranslator(BrailleConverter brailleCharset, boolean useBrailleCharsetForInput) {
		this.brailleCharset = brailleCharset;
		this.useBrailleCharsetForInput = useBrailleCharsetForInput;
	}

	private FromStyledTextToBraille fromStyledTextToBraille = null;

	public FromStyledTextToBraille fromStyledTextToBraille() {
		if (fromStyledTextToBraille == null)
			fromStyledTextToBraille = new FromStyledTextToBraille() {
					public Iterable<String> transform(Iterable<CSSStyledText> input, int from, int to) {
						List<String> braille = new ArrayList<>(); {
							int i = 0;
							for (CSSStyledText styledText : input) {
								if (i >= from && (to < 0 || i < to)) {
									SimpleInlineStyle style = styledText.getStyle();
									String text = styledText.getText();
									boolean unicodeBraille = brailleCharset == null || !useBrailleCharsetForInput;
									if (style != null) {
										CSSProperty val = style.getProperty("hyphens");
										if (val == Hyphens.MANUAL || val == Hyphens.NONE) {
											if (val == Hyphens.NONE)
												text = text.replaceAll("[\u00AD\u200B]","");
											style.removeProperty("hyphens"); }
										val = style.getProperty("white-space");
										if (val != null)
											style.removeProperty("white-space");
										val = style.getProperty("braille-charset");
										if (val != null) {
											if (val == BrailleCharset.CUSTOM)
												unicodeBraille = false;
											else if (val == BrailleCharset.UNICODE)
												unicodeBraille = true;
											style.removeProperty("braille-charset"); }
										for (String prop : style.getPropertyNames()) {
											logger.warn("'{}: {}' not supported in combination with 'text-transform: none'",
											            prop, style.get(prop));
											logger.debug("(text was: '" + text + "')"); }}
									Map<String,String> attrs = styledText.getTextAttributes();
									if (attrs != null)
										for (String k : attrs.keySet())
											logger.warn("Text attribute \"{}:{}\" ignored", k, attrs.get(k));
									if (unicodeBraille && brailleCharset != null) {
										StringBuilder b; {
											b = new StringBuilder();
											boolean special = false;
											for (String s : splitInclDelimiter(text, SPECIAL_CHARS)) {
												if (!s.isEmpty())
													b.append(special ? s : brailleCharset.toText(s));
												special = !special;
											}
										}
										braille.add(b.toString());
									} else
										braille.add(text);
								}
								i++;
							}
						}
						return braille;
					}
				};
		return fromStyledTextToBraille;
	}

	private LineBreakingFromStyledText lineBreakingFromStyledText = null;

	public LineBreakingFromStyledText lineBreakingFromStyledText() {
		if (lineBreakingFromStyledText == null)
			lineBreakingFromStyledText = new LineBreakingFromStyledText() {
					public LineIterator transform(java.lang.Iterable<CSSStyledText> input, int from, int to) {
						List<String> braille = new ArrayList<>();
						Character blankChar = brailleCharset == null
							? '\u2800'
							: brailleCharset.toText("\u2800").toCharArray()[0];
						List<Character> hyphenChars = new ArrayList<>();
						int wordSpacing; {
							wordSpacing = -1;
							int i = 0;
							for (CSSStyledText styledText : input) {
								String text = styledText.getText();
								if (i >= from && (to < 0 || i < to)) {
									SimpleInlineStyle style = styledText.getStyle();
									int spacing = 1;
									boolean unicodeBraille = brailleCharset == null || !useBrailleCharsetForInput;
									char hyphenChar = '\u2824'; // dots 36
									if (style != null) {
										CSSProperty val = style.getProperty("word-spacing");
										if (val != null) {
											if (val == WordSpacing.length) {
												spacing = style.getValue(TermInteger.class, "word-spacing").getIntValue();
												if (spacing < 0) {
													if (logger != null)
														logger.warn("word-spacing: {} not supported, must be non-negative", val);
													spacing = 1; }}
											style.removeProperty("word-spacing"); }
										if (style.getProperty("hyphens") == Hyphens.NONE) {
											text = text.replaceAll("[\u00AD\u200B]","");
											style.removeProperty("hyphens"); }
										val = style.getProperty("hyphenate-character");
										if (val != null) {
											if (val == HyphenateCharacter.braille_string) {
												String s = style.getValue(TermString.class, "hyphenate-character").getValue();
												if (s.length() == 1)
													hyphenChar = s.charAt(0);
												else
													logger.warn("The 'hyphenate-character' property must be a single character, "
													            + "but got {}", s); }
											style.removeProperty("hyphenate-character"); }
										val = style.getProperty("white-space");
										if (val != null) {
											if (val == WhiteSpace.PRE_WRAP)
												text = text.replaceAll("[\\x20\t\\u2800]+", "$0\u200B") // ZERO WIDTH SPACE
												           .replaceAll("[\\x20\t\\u2800]", "\u00A0"); // NO-BREAK SPACE
											if (val == WhiteSpace.PRE_WRAP || val == WhiteSpace.PRE_LINE)
												text = text.replaceAll("[\\n\\r]", "\u2028"); // LINE SEPARATOR
											style.removeProperty("white-space"); }
										val = style.getProperty("braille-charset");
										if (val != null) {
											if (val == BrailleCharset.CUSTOM)
												unicodeBraille = false;
											else if (val == BrailleCharset.UNICODE)
												unicodeBraille = true;
											style.removeProperty("braille-charset"); }
										for (String prop : style.getPropertyNames()) {
											logger.warn("'{}: {}' not supported in combination with 'text-transform: none'",
											            prop, style.get(prop));
											logger.debug("(text was: '" + text + "')"); }}
									if (wordSpacing < 0)
										wordSpacing = spacing;
									else if (wordSpacing != spacing)
										throw new RuntimeException("word-spacing must be constant, but both "
										                           + wordSpacing + " and " + spacing + " specified");
									Map<String,String> attrs = styledText.getTextAttributes();
									if (attrs != null)
										for (String k : attrs.keySet())
											logger.warn("Text attribute \"{}:{}\" ignored", k, attrs.get(k));
									if (unicodeBraille && brailleCharset != null) {
										StringBuilder b; {
											b = new StringBuilder();
											boolean special = false;
											for (String s : splitInclDelimiter(text, SPECIAL_CHARS)) {
												if (!s.isEmpty())
													b.append(special ? s : brailleCharset.toText(s));
												special = !special;
											}
										}
										braille.add(b.toString());
									} else
										braille.add(text);
									hyphenChars.add(hyphenChar);
								} else {
									// not converting to braille character set because not part of final output and we're not even
									// sure that it is braille
									// FIXME: may not even be useful to pass it as context to DefaultLineBreaker.LineIterator
									braille.add(text);
								}
								i++;
							}
							if (wordSpacing < 0) wordSpacing = 1;
						}
						List<BrailleTranslator.LineIterator> lineIterators = new ArrayList<>();
						String joinedBraille = join(braille);
						Character hyphenChar = null;
						Integer fromChar = null;
						int toChar = 0;
						int i = 0;
						for (String s : braille) {
							if (to-- == 0)
								break;
							if (from-- == 0)
								fromChar = toChar;
							if (from < 0) {
								Character nextHyphenChar = hyphenChars.get(i++);
								if (hyphenChar != nextHyphenChar) {
									if (toChar > fromChar) {
										lineIterators.add(
											new DefaultLineBreaker.LineIterator(
												joinedBraille,
												fromChar,
												toChar,
												blankChar,
												brailleCharset == null
													? hyphenChar
													: brailleCharset.toText("" + hyphenChar).toCharArray()[0],
												wordSpacing));
										fromChar = toChar;
									}
									hyphenChar = nextHyphenChar;
								}
							}
							toChar += s.length();
						}
						if (fromChar != null && toChar > fromChar)
							lineIterators.add(
								new DefaultLineBreaker.LineIterator(
									joinedBraille,
									fromChar,
									toChar,
									blankChar,
									brailleCharset == null
										? hyphenChar
										: brailleCharset.toText("" + hyphenChar).toCharArray()[0],
									wordSpacing));
						return CompoundBrailleTranslator.concatLineIterators(lineIterators);
					}
				};
		return lineBreakingFromStyledText;
	}

	private static final Logger logger = LoggerFactory.getLogger(UnityBrailleTranslator.class);
}