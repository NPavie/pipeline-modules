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
public class NSC_SRVSTATUS_DATAEX extends Structure {
	/** C type : char[4096] */
	public byte[] szData = new byte[4096];
	public int nData1;
	public int nData2;
	public NSC_SRVSTATUS_DATAEX() {
		super();
	}
	protected List<? > getFieldOrder() {
		return Arrays.asList("szData", "nData1", "nData2");
	}
	/** @param szData C type : char[4096] */
	public NSC_SRVSTATUS_DATAEX(byte szData[], int nData1, int nData2) {
		super();
		if ((szData.length != this.szData.length)) 
			throw new IllegalArgumentException("Wrong array size !");
		this.szData = szData;
		this.nData1 = nData1;
		this.nData2 = nData2;
	}
	public NSC_SRVSTATUS_DATAEX(Pointer peer) {
		super(peer);
	}
	public static class ByReference extends NSC_SRVSTATUS_DATAEX implements Structure.ByReference {
		
	};
	public static class ByValue extends NSC_SRVSTATUS_DATAEX implements Structure.ByValue {
		
	};
}
