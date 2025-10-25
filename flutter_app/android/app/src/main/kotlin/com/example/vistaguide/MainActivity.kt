package com.example.vistaguide

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vistaguide/llm"
    private lateinit var gemmaHandler: GemmaHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        gemmaHandler = GemmaHandler(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeGemma" -> {
                    val modelPath = call.argument<String>("modelPath") ?: "models/gemma3-1B-it-int4.tflite"
                    val maxTokens = call.argument<Int>("maxTokens") ?: 512

                    gemmaHandler.initialize(modelPath, maxTokens) { success, error ->
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("INITIALIZATION_ERROR", error, null)
                        }
                    }
                }
                "generateText" -> {
                    val prompt = call.argument<String>("prompt")
                    val maxTokens = call.argument<Int>("maxTokens") ?: 256

                    if (prompt == null) {
                        result.error("INVALID_ARGUMENT", "Prompt cannot be null", null)
                        return@setMethodCallHandler
                    }

                    gemmaHandler.generateText(prompt, maxTokens) { response, error ->
                        if (response != null) {
                            result.success(response)
                        } else {
                            result.error("GENERATION_ERROR", error, null)
                        }
                    }
                }
                "disposeGemma" -> {
                    gemmaHandler.dispose()
                    result.success(true)
                }
                "isModelLoaded" -> {
                    result.success(gemmaHandler.isLoaded())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        gemmaHandler.dispose()
    }
}
