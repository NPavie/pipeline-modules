import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;

import net.sf.saxon.s9api.XdmNode;

import org.daisy.common.file.URLs;
import org.daisy.pipeline.tts.AudioBuffer;
import org.daisy.pipeline.tts.AudioBufferAllocator;
import org.daisy.pipeline.tts.AudioBufferAllocator.MemoryException;
import org.daisy.pipeline.tts.TTSEngine;
import org.daisy.pipeline.tts.TTSRegistry.TTSResource;
import org.daisy.pipeline.tts.TTSService;
import org.daisy.pipeline.tts.Voice;

import org.ops4j.pax.exam.util.PathUtils;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;

@Component(
	name = "mock-tts",
	service = { TTSService.class }
)
public class MockTTS implements TTSService {
	
	final static File shortWaveOut = new File(PathUtils.getBaseDir(), "src/test/resources/mock-tts/mock_short.wav");
	final static File longWaveOut = new File(PathUtils.getBaseDir(), "src/test/resources/mock-tts/mock_long.wav");
	URL ssmlTransformer;
	
	@Activate
	protected void activate() {
		ssmlTransformer = URLs.getResourceFromJAR("/mock-tts/transform-ssml.xsl", MockTTS.class);
	}
	
	@Override
	public TTSEngine newEngine(Map<String,String> params) throws Throwable {
		return new TTSEngine(MockTTS.this) {
			
			AudioFormat audioFormat;
			
			@Override
			public Collection<AudioBuffer> synthesize(XdmNode ssml, Voice voice,
			                                          TTSResource threadResources, List<Mark> marks,
			                                          List<String> expectedMarks,
			                                          AudioBufferAllocator bufferAllocator)
					throws SynthesisException, InterruptedException, MemoryException {
				if (!"mock-en".equals(voice.name)) {
					throw new SynthesisException("Voice " + voice.name + " not supported");
				}
				try {
					String sentence = transformSsmlNodeToString(ssml, ssmlTransformer, new TreeMap<String,Object>());
					File waveOut = sentence.length() < 50 ? MockTTS.shortWaveOut : MockTTS.longWaveOut;
					Collection<AudioBuffer> result = new ArrayList<AudioBuffer>();
					BufferedInputStream in = new BufferedInputStream(new FileInputStream(waveOut));
					AudioInputStream fi = AudioSystem.getAudioInputStream(in);
					if (audioFormat == null)
						audioFormat = fi.getFormat();
					while (true) {
						AudioBuffer b = bufferAllocator.allocateBuffer(2048 + fi.available());
						int ret = fi.read(b.data, 0, b.size);
						if (ret == -1) {
							bufferAllocator.releaseBuffer(b);
							break; }
						b.size = ret;
						result.add(b); }
					fi.close();
					return result; }
				catch (Exception e) {
					throw new SynthesisException(e); }
			}
			
			@Override
			public AudioFormat getAudioOutputFormat() {
				return audioFormat;
			}
			
			@Override
			public Collection<Voice> getAvailableVoices() throws SynthesisException, InterruptedException {
				List<Voice> voices = new ArrayList<Voice>();
				voices.add(new Voice(getProvider().getName(), "mock-en"));
				voices.add(new Voice(getProvider().getName(), "mock-nl")); // don't put this first in the list because
				                                                           // the first item is used to test the engine
				return voices;
			}
			
			@Override
			public int getOverallPriority() {
				return 2;
			}
		};
	}
	
	@Override
	public String getName() {
		return "mock-tts";
	}
}
