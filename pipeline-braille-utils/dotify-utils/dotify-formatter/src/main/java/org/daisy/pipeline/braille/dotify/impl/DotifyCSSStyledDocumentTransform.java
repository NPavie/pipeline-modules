package org.daisy.pipeline.braille.dotify.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.net.URI;

import com.google.common.base.Objects;
import com.google.common.base.Objects.ToStringHelper;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;

import org.daisy.pipeline.braille.common.AbstractTransform;
import org.daisy.pipeline.braille.common.AbstractTransformProvider;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logSelect;
import org.daisy.pipeline.braille.common.BrailleTranslator;
import org.daisy.pipeline.braille.common.BrailleTranslatorProvider;
import org.daisy.pipeline.braille.common.Query;
import org.daisy.pipeline.braille.common.Query.Feature;
import org.daisy.pipeline.braille.common.Query.MutableQuery;
import static org.daisy.pipeline.braille.common.Query.util.mutableQuery;
import org.daisy.pipeline.braille.common.Transform;
import org.daisy.pipeline.braille.common.TransformProvider;
import static org.daisy.pipeline.braille.common.TransformProvider.util.dispatch;
import static org.daisy.pipeline.braille.common.TransformProvider.util.memoize;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

public interface DotifyCSSStyledDocumentTransform {
	
	@Component(
		name = "org.daisy.pipeline.braille.dotify.impl.DotifyCSSStyledDocumentTransform.Provider",
		service = {
			TransformProvider.class
		}
	)
	public class Provider extends AbstractTransformProvider<Transform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/transform/dotify-transform.xpl"));
		}
		
		private final static Iterable<Transform> empty = Iterables.<Transform>empty();
		
		private final static List<String> supportedOutput = ImmutableList.of("braille","pef");
		
		/**
		 * Recognized features:
		 *
		 * - formatter: Will only match if the value is `dotify'.
		 *
		 * Other features are used for finding sub-transformers of type BrailleTranslator.
		 */
		protected Iterable<Transform> _get(Query query) {
			final MutableQuery q = mutableQuery(query);
			try {
				if ("css".equals(q.removeOnly("input").getValue().get())) {
					for (Feature f : q.removeAll("output"))
						if (!supportedOutput.contains(f.getValue().get()))
							return empty;
					if (q.containsKey("formatter"))
						if (!"dotify".equals(q.removeOnly("formatter").getValue().get()))
							return empty;
					final Query blockTransformQuery = mutableQuery(q).add("input", "css").add("output", "css");
					final Query textTransformQuery = mutableQuery(q).add("input", "text-css").add("output", "braille");
					Iterable<BrailleTranslator> blockTransforms = logSelect(blockTransformQuery, brailleTranslatorProvider);
					return transform(
						blockTransforms,
						new Function<BrailleTranslator,Transform>() {
							public Transform _apply(BrailleTranslator blockTransform) {
								return __apply(
									logCreate(new TransformImpl(blockTransformQuery.toString(),
									                            blockTransform,
									                            textTransformQuery.toString()))); }}); }}
			catch (IllegalStateException e) {}
			return empty;
		}
		
		private class TransformImpl extends AbstractTransform {
			
			private final BrailleTranslator blockTransform;
			private final XProc xproc;
			
			private TransformImpl(String blockTransformQuery, BrailleTranslator blockTransform, String textTransformQuery) {
				Map<String,String> options = ImmutableMap.of(
					"css-block-transform", blockTransformQuery,
					"text-transform", textTransformQuery);
				xproc = new XProc(href, null, options);
				this.blockTransform = blockTransform;
			}
			
			@Override
			public XProc asXProc() {
				return xproc;
			}
			
			@Override
			public ToStringHelper toStringHelper() {
				return Objects.toStringHelper("o.d.p.b.dotify.impl.DotifyCSSStyledDocumentTransform$Provider$TransformImpl")
					.add("blockTransform", blockTransform);
			}
		}
		
		@Reference(
			name = "BrailleTranslatorProvider",
			unbind = "unbindBrailleTranslatorProvider",
			service = BrailleTranslatorProvider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		@SuppressWarnings(
			"unchecked" // safe cast to BrailleTranslatorProvider<BrailleTranslator>
		)
		public void bindBrailleTranslatorProvider(BrailleTranslatorProvider<?> provider) {
			brailleTranslatorProviders.add((BrailleTranslatorProvider<BrailleTranslator>)provider);
		}
		
		public void unbindBrailleTranslatorProvider(BrailleTranslatorProvider<?> provider) {
			brailleTranslatorProviders.remove(provider);
			brailleTranslatorProvider.invalidateCache();
		}
	
		private List<BrailleTranslatorProvider<BrailleTranslator>> brailleTranslatorProviders
		= new ArrayList<BrailleTranslatorProvider<BrailleTranslator>>();
		
		private TransformProvider.util.MemoizingProvider<BrailleTranslator> brailleTranslatorProvider
		= memoize(dispatch(brailleTranslatorProviders));
		
	}
}
