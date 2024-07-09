package org.daisy.pipeline.tts.acapela.impl;
import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;
/**
 * <i>native declaration : nscube_forjna.h</i><br>
 * This file was autogenerated by <a href="http://jnaerator.googlecode.com/">JNAerator</a>,<br>
 * a tool written by <a href="http://ochafik.com/">Olivier Chafik</a> that <a href="http://code.google.com/p/jnaerator/wiki/CreditsAndLicense">uses a few opensource projects.</a>.<br>
 * For help, please visit <a href="http://nativelibs4java.googlecode.com/">NativeLibs4Java</a> , <a href="http://rococoa.dev.java.net/">Rococoa</a>, or <a href="http://jna.dev.java.net/">JNA</a>.
 */
public class NSC_EVENT_DATA extends Structure {
	public int uiSize;
	/** C type : unsigned char[1] */
	public byte[] bData = new byte[1];
	public NSC_EVENT_DATA() {
		super();
	}
	protected List<? > getFieldOrder() {
		return Arrays.asList("uiSize", "bData");
	}
	/** @param bData C type : unsigned char[1] */
	public NSC_EVENT_DATA(int uiSize, byte bData[]) {
		super();
		this.uiSize = uiSize;
		if ((bData.length != this.bData.length)) 
			throw new IllegalArgumentException("Wrong array size !");
		this.bData = bData;
	}
	public NSC_EVENT_DATA(Pointer peer) {
		super(peer);
	}
	public static class ByReference extends NSC_EVENT_DATA implements Structure.ByReference {
		
	};
	public static class ByValue extends NSC_EVENT_DATA implements Structure.ByValue {
		
	};
}
