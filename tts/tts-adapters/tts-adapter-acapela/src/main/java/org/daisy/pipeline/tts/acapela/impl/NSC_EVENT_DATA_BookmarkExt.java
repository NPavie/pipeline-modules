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
public class NSC_EVENT_DATA_BookmarkExt extends Structure {
	public int uiSize;
	/** C type : void* */
	public Pointer pUserData;
	/**
	 * bookmark value<br>
	 * C type : char[50]
	 */
	public byte[] szVal = new byte[50];
	/** position in bytes in whole audio signal */
	public int uiByteCount;
	public NSC_EVENT_DATA_BookmarkExt() {
		super();
	}
	protected List<? > getFieldOrder() {
		return Arrays.asList("uiSize", "pUserData", "szVal", "uiByteCount");
	}
	/**
	 * @param pUserData C type : void*<br>
	 * @param szVal bookmark value<br>
	 * C type : char[50]<br>
	 * @param uiByteCount position in bytes in whole audio signal
	 */
	public NSC_EVENT_DATA_BookmarkExt(int uiSize, Pointer pUserData, byte szVal[], int uiByteCount) {
		super();
		this.uiSize = uiSize;
		this.pUserData = pUserData;
		if ((szVal.length != this.szVal.length)) 
			throw new IllegalArgumentException("Wrong array size !");
		this.szVal = szVal;
		this.uiByteCount = uiByteCount;
	}
	public NSC_EVENT_DATA_BookmarkExt(Pointer peer) {
		super(peer);
	}
	public static class ByReference extends NSC_EVENT_DATA_BookmarkExt implements Structure.ByReference {
		
	};
	public static class ByValue extends NSC_EVENT_DATA_BookmarkExt implements Structure.ByValue {
		
	};
}
