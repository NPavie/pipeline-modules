package org.daisy.pipeline.braille.common;

import java.util.ArrayList;
import static java.util.Collections.singleton;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.daisy.braille.css.SimpleInlineStyle;
import static org.daisy.pipeline.braille.common.util.Strings.extractHyphens;
import org.daisy.pipeline.braille.css.CSSStyledText;

import org.junit.Test;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class DefaultLineBreakerTest {
	
	@Test
	public void testNonStandardLineBreaking() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		assertEquals(
			"BUS\n" +
			"STOP\n" +
			"P",
			fillLines(translator.lineBreakingFromStyledText().transform(text("busstopp")), 4));
		assertEquals(
			"BUSS-\n" +
			"STOPP",
			fillLines(translator.lineBreakingFromStyledText().transform(text("busstopp")), 5));
		assertEquals(
			"BUSS-\n" +
			"STOPP",
			fillLines(translator.lineBreakingFromStyledText().transform(text("busstopp")), 6));
		assertEquals(
			"BUSS-\n" +
			"STOPP",
			fillLines(translator.lineBreakingFromStyledText().transform(text("busstopp")), 7));
	}
	
	@Test
	public void testFullLine() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		assertEquals(
			"ABCDEF",
			fillLines(translator.lineBreakingFromStyledText().transform(text("abcdef")), 6));
		assertEquals(
			"ABCDE ",
			fillLines(translator.lineBreakingFromStyledText().transform(text("abcde  ")), 6));
		assertEquals(
			"ABCDEF",
			fillLines(translator.lineBreakingFromStyledText().transform(text("abcdef ")), 6));
		assertEquals(
			"ABCDEF",
			fillLines(translator.lineBreakingFromStyledText().transform(text("abcdef ")), 6));
		{
				BrailleTranslator.LineIterator lines = translator.lineBreakingFromStyledText().transform(text("abcdef"));
				assertEquals("", lines.nextTranslatedRow(3, false));
				assertEquals("ABCDEF", lines.nextTranslatedRow(100, false));
		}
		{
				BrailleTranslator.LineIterator lines = translator.lineBreakingFromStyledText().transform(text("abcdef"));
				assertEquals("", lines.nextTranslatedRow(0, false));
				assertEquals("ABCDEF", lines.nextTranslatedRow(100, false));
		}
	}
	
	@Test
	public void testEmpty() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		assertEquals(
			" ",
			fillLines(translator.lineBreakingFromStyledText().transform(text("   ")), 10));
		assertEquals(
			"",
			fillLines(translator.lineBreakingFromStyledText().transform(text("\u200B")), 10));
		assertEquals(
			"XXX⠀XXX",
			fillLines(
				new AbstractBrailleTranslator() {
					public BrailleTranslator.FromStyledTextToBraille fromStyledTextToBraille() {
						return new BrailleTranslator.FromStyledTextToBraille() {
							public Iterable<String> transform(Iterable<CSSStyledText> styledText, int from, int to) {
								if (from < 0 || (to >= 0 && from > to))
									throw new IndexOutOfBoundsException();
								List<String> transformed = new ArrayList<>();
								int i = 0;
								for (CSSStyledText t : styledText) {
									if (to >= 0 && i >= to)
										break;
									if (i >= from)
										transformed.add(t.getText().toUpperCase());
									i++;
								}
								return transformed;
							}
						};
					}
				}.lineBreakingFromStyledText().transform(
					text("xxx",
					     " ",
					     " ",
					     " ",
					     "xxx")),
				10));
	}
	
	@Test
	public void testNoBreakSpace() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		assertEquals(
			"ABC\n" +
			"DEF GHIJ",
			fillLines(translator.lineBreakingFromStyledText().transform(text("abc def ghij")), 10));
	}

	@Test
	public void testHardLineBreak() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		assertEquals(
			" \n" +
			"ABC\n" +
			" \n" +
			"DEF",
			fillLines(translator.lineBreakingFromStyledText().transform(text("\u2028abc\u2028\u2028def")), 10));
	}
	
	@Test
	public void testDisallowHyphenation() {
		TestHyphenator hyphenator = new TestHyphenator();
		TestTranslator translator = new TestTranslator(hyphenator);
		BrailleTranslator.LineIterator i
			= translator.lineBreakingFromStyledText().transform(text("abc­def abc­def abc­def abc­def"));
		assertEquals("ABCDEF ABC-", i.nextTranslatedRow(12, true, false));
		assertEquals("DEF",         i.nextTranslatedRow(6,  true, false));
		assertEquals("ABCDEF",      i.nextTranslatedRow(12, true, true)); // wholeWordsOnly = true
		assertEquals("ABC-",        i.nextTranslatedRow(5,  true, false));
		assertEquals("DEF",         i.nextTranslatedRow(5,  true, false));
		assertFalse(i.hasNext());
	}
	
	@Test
	public void testKeepSegmentsTogether() {
		assertEquals(
			"xxx abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcdef",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx\n" +
			"abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcdefg",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx\n" +
			"abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcdef­g",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcde­fg",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcde-\u200Bfg",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx ab-",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx ab­cdefg",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx\n" +
			"abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abcdefg h",
					0, 7, ' ', '-', 1),
				10));
		assertEquals(
			"xxx\n" +
			"abc",
			fillLines(
				new AbstractBrailleTranslator.util.DefaultLineBreaker.LineIterator(
					"xxx abc defg",
					0, 7, ' ', '-', 1),
				10));
	}
	
	private static class TestHyphenator extends AbstractHyphenator {
		
		@Override
		public FullHyphenator asFullHyphenator() {
			return fullHyphenator;
		}
		
		private static final FullHyphenator fullHyphenator = new AbstractHyphenator.util.DefaultFullHyphenator() {

			private final static char SHY = '\u00AD';
			private final static char ZWSP = '\u200B';

			protected boolean isCodePointAware() { return false; }
			protected boolean isLanguageAdaptive() { return false; }
		
			protected byte[] getHyphenationOpportunities(String text, Locale language) throws RuntimeException {
				if (text.contains("busstopp"))
					throw new RuntimeException("text contains non-standard break points");
				else
					return extractHyphens(text, false, SHY, ZWSP)._2;
			}
		};
		
		@Override
		public LineBreaker asLineBreaker() {
			return lineBreaker;
		}
		
		private final LineBreaker lineBreaker = new AbstractHyphenator.util.DefaultLineBreaker() {
			protected Break breakWord(String word, Locale language, int limit, boolean force) {
				if (limit >= 4 && word.equals("busstopp"))
					return new Break("bussstopp", 4, true);
				else if (limit >= word.length())
					return new Break(word, word.length(), false);
				else if (force)
					return new Break(word, limit, false);
				else
					return new Break(word, 0, false);
			}
		};
	}
	
	private static class TestTranslator extends AbstractBrailleTranslator {
		
		private final Hyphenator hyphenator;
		
		private TestTranslator(Hyphenator hyphenator) {
			this.hyphenator = hyphenator;
		}
		
		public TestTranslator _withHyphenator(Hyphenator hyphenator) {
			return new TestTranslator(hyphenator);
		}
		
		private final static Pattern WORD_SPLITTER = Pattern.compile("[\\x20\t\\n\\r\\u2800\\xA0]+");
		private final static SimpleInlineStyle HYPHENS_AUTO = new SimpleInlineStyle("hyphens: auto");
		
		private final LineBreakingFromStyledText lineBreaker = new AbstractBrailleTranslator.util.DefaultLineBreaker(' ', '-', null) {
			protected BrailleStream translateAndHyphenate(final Iterable<CSSStyledText> styledText, int from, int to) {
				if (from != 0 && to >= 0)
					throw new UnsupportedOperationException();
				return new BrailleStream() {
					int pos = 0;
					String text; {
						text = "";
						for (CSSStyledText t : styledText)
							text += t.getText();
						if (text.replaceAll("[\u00ad\u200b]","").isEmpty())
							text = "";
					}
					public boolean hasNext() {
						return pos < text.length();
					}
					public String next(int limit, boolean force, boolean allowHyphens) {
						String next = "";
						int start = pos;
						int end = text.length();
						int available = limit;
						if (end - start <= available) {
							next = text.substring(start);
							pos = end; }
						else {
							try {
								next = hyphenator.asFullHyphenator().transform(
									singleton(new CSSStyledText(text.substring(pos), HYPHENS_AUTO))).iterator().next().getText();
								pos = end; }
							catch (Exception e) {
								Matcher m = WORD_SPLITTER.matcher(text.substring(pos));
								boolean foundSpace;
								while ((foundSpace = m.find()) || pos < end) {
									int wordStart = pos;
									int wordEnd = foundSpace ? start + m.start() : end;
									if (wordEnd > wordStart) {
										String word = text.substring(wordStart, wordEnd);
										if (word.length() <= available) {
											next += word;
											available -= word.length();
											pos += word.length(); }
										else if (available <= 0)
											break;
										else {
											Hyphenator.LineIterator lines = hyphenator.asLineBreaker().transform(word, null);
											String line = lines.nextLine(available, force, allowHyphens);
											if (line.length() == available && lines.lineHasHyphen()) {
												lines.reset();
												line = lines.nextLine(available - 1, force, allowHyphens); }
											if (line.length() > 0) {
												next += line;
												if (lines.lineHasHyphen())
													next += "\u00ad";
												pos += line.length();
												text = text.substring(0, pos) + lines.remainder(); }
											break; }}
									if (foundSpace) {
										String space = text.substring(pos, start + m.end());
										next += space;
										available -= space.length();
										pos = space.length(); }}}}
						return translate(next);
					}
					public Character peek() {
						return text.charAt(pos);
					}
					public String remainder() {
						return translate(text.substring(pos));
					}
					public boolean hasPrecedingSpace() {
						return false;
					}
					@Override
					public Object clone() {
						try {
							return super.clone();
						} catch (CloneNotSupportedException e) {
							throw new InternalError("coding error");
						}
					}
					private String translate(String s) {
						return s.toUpperCase();
					}
				};
			}
		};
		
		@Override
		public LineBreakingFromStyledText lineBreakingFromStyledText() {
			return lineBreaker;
		}
	}
	
	private Iterable<CSSStyledText> text(String... text) {
		List<CSSStyledText> styledText = new ArrayList<CSSStyledText>();
		for (String t : text)
			styledText.add(new CSSStyledText(t, ""));
		return styledText;
	}
	
	private static String fillLines(BrailleTranslator.LineIterator lines, int width) {
		StringBuilder sb = new StringBuilder();
		while (lines.hasNext()) {
			sb.append(lines.nextTranslatedRow(width, true));
			if (lines.hasNext())
				sb.append('\n'); }
		return sb.toString();
	}
}
