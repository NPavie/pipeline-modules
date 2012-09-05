package org.daisy.pipeline.liblouis;

import org.daisy.pipeline.liblouis.Utilities.VoidFunction;

public interface LiblouisTableRegistry {

	public void addTableSet(LiblouisTableSet tableSet);

	public void removeTableSet(LiblouisTableSet tableSet);

	public String resolveTableURL(String table);

	public void onLouisTablePathUpdate(VoidFunction<String> callback);

}
