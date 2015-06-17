package org.daisy.pipeline.braille.dotify.transform;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import javax.xml.namespace.QName;

import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import org.daisy.pipeline.braille.common.Memoizing;
import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.css.Query.serializeQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.CSSStyledDocumentTransform;
import static org.daisy.pipeline.braille.common.Provider.util.memoize;
import org.daisy.pipeline.braille.common.Transform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import org.daisy.pipeline.braille.common.XProcTransform;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

import org.slf4j.Logger;

public interface DotifyCSSStyledDocumentTransform extends XProcTransform, CSSStyledDocumentTransform {
	
	@Component(
		name = "org.daisy.pipeline.braille.dotify.transform.DotifyCSSStyledDocumentTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSStyledDocumentTransform.Provider.class
		}
	)
	public class Provider implements XProcTransform.Provider<DotifyCSSStyledDocumentTransform>,
	                                 CSSStyledDocumentTransform.Provider<DotifyCSSStyledDocumentTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/transform/dotify-transform.xpl"));
		}
		
		public Transform.Provider<DotifyCSSStyledDocumentTransform> withContext(Logger context) {
			return this;
		}
		
		/**
		 * Recognized features:
		 *
		 * - formatter: Will only match if the value is `dotify'.
		 *
		 * Other features are used for finding sub-transformers of type CSSBlockTransform.
		 */
		public Iterable<DotifyCSSStyledDocumentTransform> get(String query) {
			return Optional.<DotifyCSSStyledDocumentTransform>fromNullable(transforms.apply(query)).asSet();
		}
		
		private Memoizing<String,DotifyCSSStyledDocumentTransform> transforms
		= new Memoizing<String,DotifyCSSStyledDocumentTransform>() {
			public DotifyCSSStyledDocumentTransform _apply(String query) {
				final URI href = Provider.this.href;
				Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
				Optional<String> o;
				if ((o = q.remove("formatter")) != null)
					if (!o.get().equals("dotify"))
						return null;
				String newQuery = serializeQuery(q);
				if (!cssBlockTransformProvider.get(newQuery).iterator().hasNext())
					return null;
				final Map<String,String> options = ImmutableMap.<String,String>of("query", newQuery);
				return new DotifyCSSStyledDocumentTransform() {
					public Tuple3<URI,QName,Map<String,String>> asXProc() {
						return new Tuple3<URI,QName,Map<String,String>>(href, null, options); }};
			}
		};
		
		@Reference(
			name = "CSSBlockTransformProvider",
			unbind = "unbindCSSBlockTransformProvider",
			service = CSSBlockTransform.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		@SuppressWarnings(
			"unchecked" // safe cast to Transform.Provider<CSSBlockTransform>
		)
		public void bindCSSBlockTransformProvider(CSSBlockTransform.Provider<?> provider) {
			if (provider instanceof XProcTransform.Provider)
				cssBlockTransformProviders.add((Transform.Provider<CSSBlockTransform>)provider);
		}
		
		public void unbindCSSBlockTransformProvider(CSSBlockTransform.Provider<?> provider) {
			cssBlockTransformProviders.remove(provider);
			cssBlockTransformProvider.invalidateCache();
		}
	
		private List<Transform.Provider<CSSBlockTransform>> cssBlockTransformProviders
		= new ArrayList<Transform.Provider<CSSBlockTransform>>();
		
		private org.daisy.pipeline.braille.common.Provider.MemoizingProvider<String,CSSBlockTransform> cssBlockTransformProvider
		= memoize(dispatch(cssBlockTransformProviders));
		
	}
}
