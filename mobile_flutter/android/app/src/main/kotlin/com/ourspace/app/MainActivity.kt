package com.ourspace.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.ourspace.app/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // CRITICAL FIX for jvm.cc:81 SIGABRT crash:
        //
        // WebRTC's network_thread calls NetworkMonitorAutoDetect via JNI shortly
        // after createPeerConnection(). For this JNI callback to succeed, the native
        // libjingle library must have its JavaVM* registered via JNI_OnLoad — which
        // only happens after System.loadLibrary("jingle_peerconnection_so") is called.
        //
        // PeerConnectionFactory.initialize() triggers the native library load AND
        // registers the application Context with WebRTC. It MUST run synchronously
        // on the main thread before any WebRTC threads are spawned.
        //
        // We use reflection because org.webrtc is a runtime-only dependency provided
        // by the flutter_webrtc plugin — not available at app compile time.
        initializeWebRtcNative()
    }

    private fun initializeWebRtcNative() {
        try {
            // Load the native library so JNI_OnLoad registers the JavaVM*
            System.loadLibrary("jingle_peerconnection_so")
        } catch (_: Throwable) {
            // May already be loaded or have a different name — proceed to initialize
        }

        try {
            val pcfClass = Class.forName("org.webrtc.PeerConnectionFactory")
            val initOptionsClass = Class.forName("org.webrtc.PeerConnectionFactory\$InitializationOptions")
            val builderClass = Class.forName("org.webrtc.PeerConnectionFactory\$InitializationOptions\$Builder")

            // Build InitializationOptions via builder pattern
            val builderMethod = initOptionsClass.getMethod("builder", android.content.Context::class.java)
            val builder = builderMethod.invoke(null, applicationContext)

            // Disable tracer to reduce overhead
            val setTracerMethod = builderClass.getMethod("setEnableInternalTracer", Boolean::class.java)
            setTracerMethod.invoke(builder, false)

            val buildMethod = builderClass.getMethod("createInitializationOptions")
            val initOptions = buildMethod.invoke(builder)

            // Call PeerConnectionFactory.initialize(initOptions) — registers JavaVM*
            val initMethod = pcfClass.getMethod("initialize", initOptionsClass)
            initMethod.invoke(null, initOptions)
        } catch (_: Throwable) {
            // If reflection fails, flutter_webrtc will initialize on first use
            // The System.loadLibrary above is still the most important part
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel handlers for dynamic screen protection (Chat, Video Call, Audio Call)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableFlagSecure" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disableFlagSecure" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
