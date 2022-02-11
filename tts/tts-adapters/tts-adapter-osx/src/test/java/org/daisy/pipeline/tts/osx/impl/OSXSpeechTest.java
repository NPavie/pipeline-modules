package org.daisy.pipeline.tts.osx.impl;

import java.io.StringReader;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import javax.xml.transform.sax.SAXSource;

import org.daisy.common.shell.BinaryFinder;
import org.daisy.pipeline.tts.AudioBuffer;
import org.daisy.pipeline.tts.AudioBufferAllocator;
import org.daisy.pipeline.tts.AudioBufferAllocator.MemoryException;
import org.daisy.pipeline.tts.StraightBufferAllocator;
import org.daisy.pipeline.tts.TTSRegistry.TTSResource;
import org.daisy.pipeline.tts.TTSService.SynthesisException;
import org.daisy.pipeline.tts.Voice;

import org.junit.Assert;
import org.junit.Assume;
import org.junit.Test;
import org.xml.sax.InputSource;

import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmNode;

public class OSXSpeechTest {

	static AudioBufferAllocator BufferAllocator = new StraightBufferAllocator();

	private static int getSize(Collection<AudioBuffer> buffers) {
		int res = 0;
		for (AudioBuffer buf : buffers) {
			res += buf.size;
		}
		return res;
	}

	private static OSXSpeechEngine allocateEngine() throws Throwable {
		Assume.assumeTrue("Test can not be run because not on Mac OS X",
		                  System.getProperty("os.name").toLowerCase().startsWith("mac os x"));
		Assume.assumeTrue("Test can not be run because say not present",
		                  BinaryFinder.find("say").isPresent());
		OSXSpeechService s = new OSXSpeechService();
		return (OSXSpeechEngine) s.newEngine(new HashMap<String, String>());
	}

	private static Voice getAnyVoice(OSXSpeechEngine engine) throws SynthesisException,
	        InterruptedException {
		return engine.getAvailableVoices().iterator().next();
	}

	@Test
	public void getVoiceInfo() throws Throwable {
		Collection<Voice> voices = allocateEngine().getAvailableVoices();
		Assert.assertTrue(voices.size() > 5);
	}

	@Test
	public void speakEasy() throws Throwable {
		OSXSpeechEngine engine = allocateEngine();
		Voice voice = getAnyVoice(engine);

		TTSResource resource = engine.allocateThreadResources();
		Collection<AudioBuffer> li = engine.synthesize(
			parseSSML("<s xmlns=\"http://www.w3.org/2001/10/synthesis\">this is a test</s>"),
			voice, resource, null, BufferAllocator);
		engine.releaseThreadResources(resource);

		Assert.assertTrue(getSize(li) > 2000);
	}

	@Test
	public void speakWithVoices() throws Throwable {
		OSXSpeechEngine engine = allocateEngine();
		TTSResource resource = engine.allocateThreadResources();

		Set<Integer> sizes = new HashSet<Integer>();
		int totalVoices = 0;
		Iterator<Voice> ite = engine.getAvailableVoices().iterator();
		while (ite.hasNext()) {
			Voice v = ite.next();
			Collection<AudioBuffer> li = engine.synthesize(
				parseSSML("<s xmlns=\"http://www.w3.org/2001/10/synthesis\">small test</s>"),
				v, resource, null, BufferAllocator);

			sizes.add(getSize(li) / 4); //div 4 helps being more robust to tiny differences
			totalVoices++;
		}
		engine.releaseThreadResources(resource);

		//this number will be very low if the voice names are not properly retrieved
		float diversity = Float.valueOf(sizes.size()) / totalVoices;

		Assert.assertTrue(diversity > 0.4);
	}

	@Test
	public void speakUnicode() throws Throwable {
		OSXSpeechEngine engine = allocateEngine();
		TTSResource resource = engine.allocateThreadResources();
		Voice voice = getAnyVoice(engine);
		Collection<AudioBuffer> li = engine.synthesize(
			parseSSML("<s xmlns=\"http://www.w3.org/2001/10/synthesis\">"
			          + "𝄞𝄞𝄞𝄞 水水水水水 𝄞水𝄞水𝄞水𝄞水 test 国aØ家Ť标准 ĜæŘ ß ŒÞ ๕</s>"),
			voice, resource, null, BufferAllocator);
		engine.releaseThreadResources(resource);

		Assert.assertTrue(getSize(li) > 2000);
	}

	@Test
	public void multiSpeak() throws Throwable {
		final OSXSpeechEngine engine = allocateEngine();

		final Voice voice = getAnyVoice(engine);

		final int[] sizes = new int[16];
		Thread[] threads = new Thread[sizes.length];
		for (int i = 0; i < threads.length; ++i) {
			final int j = i;
			threads[i] = new Thread() {
				public void run() {
					TTSResource resource = null;
					try {
						resource = engine.allocateThreadResources();
					} catch (SynthesisException | InterruptedException e) {
						return;
					}

					Collection<AudioBuffer> li = null;
					for (int k = 0; k < 16; ++k) {
						try {
							li = engine.synthesize(
								parseSSML("<s xmlns=\"http://www.w3.org/2001/10/synthesis\">small test</s>"),
								voice, resource, null, BufferAllocator);

						} catch (SaxonApiException | SynthesisException | InterruptedException | MemoryException e) {
							e.printStackTrace();
							break;
						}
						sizes[j] += getSize(li);
					}
					try {
						engine.releaseThreadResources(resource);
					} catch (SynthesisException | InterruptedException e) {
					}
				}
			};
		}

		for (Thread th : threads)
			th.start();

		for (Thread th : threads)
			th.join();

		for (int size : sizes) {
			Assert.assertEquals(sizes[0], size);
		}
	}

	private static final Processor proc = new Processor(false);

	private static XdmNode parseSSML(String ssml) throws SaxonApiException {
		return proc.newDocumentBuilder().build(new SAXSource(new InputSource(new StringReader(ssml))));
	}
}
