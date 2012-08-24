package org.daisy.pipeline.liblouis;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Enumeration;
import java.util.Map;

import org.osgi.framework.Bundle;
import org.osgi.service.component.ComponentContext;

public class LiblouisTableSet {

	private static final String IDENTIFIER = "identifier";
	private static final String DIRECTORY = "directory";
	private static final String MANIFEST = "manifest";

	private String identifier = null;
	private File path = null;
	private URL manifest = null;

	public String getIdentifier() {
		return identifier;
	}

	public File getPath() {
		return path;
	}

	public URL getManifest() {
		return manifest;
	}

	@SuppressWarnings("unchecked")
	public void activate(ComponentContext context, Map<?, ?> properties) throws Exception {
		if (properties.get(IDENTIFIER) == null
				|| properties.get(IDENTIFIER).toString().isEmpty()) {
			throw new IllegalArgumentException(IDENTIFIER + " property must not be empty");
		}
		
		if (properties.get(DIRECTORY) == null
				|| properties.get(DIRECTORY).toString().isEmpty()) {
			throw new IllegalArgumentException(DIRECTORY + " property must not be empty");
		}
		identifier = properties.get(IDENTIFIER).toString();
		try {
			new URL(identifier);
		} catch (MalformedURLException e1) {
			throw new IllegalArgumentException(IDENTIFIER + " could not be parsed into a URL");
		}
		String directory = properties.get(DIRECTORY).toString();
		path = context.getBundleContext().getDataFile("tables");
		Bundle bundle = context.getBundleContext().getBundle();
		if (!path.exists()) {
			path.mkdir();
			if (bundle.getEntry(directory) == null) {
				throw new IllegalArgumentException("Table directory at location " + directory + " could not be found");
			}
			Enumeration<String> tablePaths = bundle.getEntryPaths(directory);
			if (tablePaths != null) {
				System.out.println("Unpacking liblouis tables...");
				while (tablePaths.hasMoreElements()) {
					URL tableURL = bundle.getEntry(tablePaths.nextElement());
					String url = tableURL.toExternalForm();
					String fileName = url.substring(url.lastIndexOf('/')+1, url.length());
					File file = new File(path.getAbsolutePath() + File.separator + fileName);
					unpack(tableURL, file);
					System.out.println(" --> " + fileName);
				}
			}
		}
		if (properties.get(MANIFEST) != null) {
			String manifestPath = properties.get(MANIFEST).toString();
			manifest = bundle.getEntry(manifestPath);
			if (manifest == null) {
				throw new IllegalArgumentException("Manifest at location " + manifestPath + " could not be found");
			}
		}
	}

	private static void unpack(URL url, File file) throws Exception {
		file.createNewFile();
		FileOutputStream writer = new FileOutputStream(file);
		url.openConnection();
		InputStream reader = url.openStream();
		byte[] buffer = new byte[153600];
		int bytesRead = 0;
		while ((bytesRead = reader.read(buffer)) > 0) {
			writer.write(buffer, 0, bytesRead);
			buffer = new byte[153600];
		}
		writer.close();
		reader.close();
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int hash = 1;
		hash = prime * hash + ((identifier == null) ? 0 : identifier.hashCode());
		hash = prime * hash + ((manifest == null) ? 0 : manifest.hashCode());
		hash = prime * hash + ((path == null) ? 0 : path.hashCode());
		return hash;
	}

	@Override
	public boolean equals(Object object) {
		if (this == object)
			return true;
		if (object == null)
			return false;
		if (getClass() != object.getClass())
			return false;
		LiblouisTableSet that = (LiblouisTableSet)object;
		if (!this.identifier.equals(that.identifier))
			return false;
		if (!this.path.equals(that.path))
			return false;
		if (manifest == null) {
			if (that.manifest != null)
				return false;
		} else if (!manifest.equals(that.manifest))
			return false;
		return true;
	}
}
