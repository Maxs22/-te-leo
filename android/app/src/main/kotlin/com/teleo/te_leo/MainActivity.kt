package com.teleo.te_leo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VOICE_SETUP_CHANNEL = "com.teleo.te_leo/voice_setup"
    private lateinit var voiceSetupPlugin: VoiceSetupPlugin
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configurar plugin de configuración de voces
        voiceSetupPlugin = VoiceSetupPlugin()
        voiceSetupPlugin.setActivity(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_SETUP_CHANNEL)
            .setMethodCallHandler(voiceSetupPlugin)
    }
    
    override fun onDestroy() {
        voiceSetupPlugin.setActivity(null)
        super.onDestroy()
    }
}
