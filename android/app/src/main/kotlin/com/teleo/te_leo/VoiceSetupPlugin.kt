package com.teleo.te_leo

import android.content.Intent
import android.provider.Settings
import android.speech.tts.TextToSpeech
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VoiceSetupPlugin : MethodCallHandler {
    private var activity: android.app.Activity? = null
    
    fun setActivity(activity: android.app.Activity?) {
        this.activity = activity
    }
    
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "openTTSSettings" -> {
                openTTSSettings(result)
            }
            "openSettings" -> {
                openGeneralSettings(result)
            }
            "checkTTSEngine" -> {
                checkTTSEngine(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun openTTSSettings(result: Result) {
        try {
            val intent = Intent().apply {
                action = "com.android.settings.TTS_SETTINGS"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            activity?.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            // Fallback: abrir configuración de accesibilidad
            try {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                activity?.startActivity(intent)
                result.success(true)
            } catch (e2: Exception) {
                result.error("TTS_SETTINGS_ERROR", "No se pudo abrir configuración TTS: ${e2.message}", null)
            }
        }
    }
    
    private fun openGeneralSettings(result: Result) {
        try {
            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            activity?.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", "No se pudo abrir configuración: ${e.message}", null)
        }
    }
    
    private fun checkTTSEngine(result: Result) {
        try {
            val intent = Intent().apply {
                action = TextToSpeech.Engine.ACTION_CHECK_TTS_DATA
            }
            activity?.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("TTS_CHECK_ERROR", "No se pudo verificar TTS: ${e.message}", null)
        }
    }
}
