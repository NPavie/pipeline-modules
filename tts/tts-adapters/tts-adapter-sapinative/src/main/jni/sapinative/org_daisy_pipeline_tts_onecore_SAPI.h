/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class org_daisy_pipeline_tts_onecore_SAPI */

#ifndef _Included_org_daisy_pipeline_tts_onecore_SAPI
#define _Included_org_daisy_pipeline_tts_onecore_SAPI
#ifdef __cplusplus
extern "C" {
#endif


/*
 * Class:     org_daisy_pipeline_tts_onecore_SAPI
 * Method:    getVoices
 * Signature: ()[Lorg/daisy/pipeline/tts/Voice;
 */
JNIEXPORT jobjectArray JNICALL Java_org_daisy_pipeline_tts_onecore_SAPI_getVoices
(JNIEnv*, jclass);

/*
 * Class:     org_daisy_pipeline_tts_onecore_SAPI
 * Method:    speak
 * Signature: (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;IJ)Lorg/daisy/pipeline/tts/onecore/NativeSynthesisResult;
 */
JNIEXPORT jobject JNICALL Java_org_daisy_pipeline_tts_onecore_SAPI_speak
(JNIEnv*, jclass, jstring, jstring, jstring, jint, jshort);


/*
 * Class:     org_daisy_pipeline_tts_onecore_SAPI
 * Method:    initialize
 * Signature: (IS)I
 */
JNIEXPORT jint JNICALL Java_org_daisy_pipeline_tts_onecore_SAPI_initialize
  (JNIEnv *, jclass, jint, jshort);

/*
 * Class:     org_daisy_pipeline_tts_onecore_SAPI
 * Method:    dispose
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_org_daisy_pipeline_tts_onecore_SAPI_dispose
  (JNIEnv *, jclass);

#ifdef __cplusplus
}
#endif
#endif
