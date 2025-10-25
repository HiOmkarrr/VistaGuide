package com.example.vistaguide

import android.content.Context
import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.RandomAccessFile

class GemmaHandler(private val context: Context) {
    private var llmInference: LlmInference? = null
    private val TAG = "GemmaHandler"
    private val scope = CoroutineScope(Dispatchers.IO)
    
    /**
     * Validate if the file is a proper .task file for MediaPipe
     * .task files should have specific headers/structure
     */
    private fun validateTaskFile(file: File): Boolean {
        try {
            if (!file.name.endsWith(".task", ignoreCase = true)) {
                return true // Not a .task file, skip validation
            }
            
            // Basic validation: check file size and readability
            if (file.length() < 1024 * 1024) {
                Log.e(TAG, "⚠️ .task file unusually small (${file.length()} bytes)")
                return false
            }
            
            // Try to read first few bytes to ensure file is accessible
            RandomAccessFile(file, "r").use { raf ->
                val header = ByteArray(16)
                raf.read(header)
                Log.d(TAG, "✅ .task file validation passed - file is readable")
            }
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "❌ .task file validation failed: ${e.message}")
            return false
        }
    }

    /**
     * Initialize the Gemma model using MediaPipe LLM Inference
     * @param modelPath Absolute file path to the model (not asset path)
     */
    fun initialize(modelPath: String, maxTokens: Int, callback: (Boolean, String?) -> Unit) {
        scope.launch {
            var modelSizeMB: Long = 0 // Declare outside try block so it's accessible in catch
            
            try {
                Log.d(TAG, "🔄 Loading Gemma model from: $modelPath")
                
                // Check if path is an asset path or absolute file path
                val modelFile = if (modelPath.startsWith("/")) {
                    // Absolute path - use directly
                    File(modelPath)
                } else {
                    // Asset path - copy from assets to cache
                    copyAssetToCache(modelPath)
                }
                
                if (modelFile == null || !modelFile.exists()) {
                    val error = if (modelPath.startsWith("/")) {
                        "Model file not found at: $modelPath"
                    } else {
                        "Model file not found in assets: $modelPath"
                    }
                    Log.e(TAG, "❌ $error")
                    withContext(Dispatchers.Main) {
                        callback(false, error)
                    }
                    return@launch
                }

                modelSizeMB = modelFile.length() / (1024 * 1024)
                Log.d(TAG, "📦 Model file size: $modelSizeMB MB")
                Log.d(TAG, "📍 Model file path: ${modelFile.absolutePath}")
                Log.d(TAG, "📄 Model file extension: ${modelFile.extension}")
                
                // Verify file is readable and has valid size
                if (modelSizeMB < 1) {
                    val error = "Model file too small (${modelSizeMB}MB) - may be corrupted"
                    Log.e(TAG, "❌ $error")
                    withContext(Dispatchers.Main) {
                        callback(false, error)
                    }
                    return@launch
                }
                
                // Check if it's a .task file (MediaPipe-optimized format)
                val isTaskFile = modelFile.name.endsWith(".task", ignoreCase = true)
                if (isTaskFile) {
                    Log.d(TAG, "✅ Detected .task file - MediaPipe-optimized format with built-in chat templates")
                    Log.d(TAG, "💡 .task files include: tokenizer + chat templates + prefill/decode runners")
                    
                    // Validate .task file format
                    if (!validateTaskFile(modelFile)) {
                        val error = ".task file validation failed - file may be corrupted or incomplete"
                        Log.e(TAG, "❌ $error")
                        withContext(Dispatchers.Main) {
                            callback(false, error)
                        }
                        return@launch
                    }
                } else {
                    Log.d(TAG, "📋 Standard TFLite format detected - may require manual chat template setup")
                }

                // Check available memory before loading large model
                val runtime = Runtime.getRuntime()
                val maxMemory = runtime.maxMemory() / (1024 * 1024) // MB
                val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
                val availableMemory = maxMemory - usedMemory
                
                Log.d(TAG, "📊 App Heap: Available=${availableMemory}MB, Max=${maxMemory}MB, Used=${usedMemory}MB")
                Log.d(TAG, "💡 Model Size: ${modelSizeMB}MB")
                
                // MediaPipe uses memory-mapped files, so the model doesn't fully load into heap
                // We need enough heap for inference operations (~200-300MB) but not the full model
                // Only warn if we have very little heap available
                if (maxMemory < 256) {
                    val error = "App heap too small (${maxMemory}MB). Device may not support large models."
                    Log.e(TAG, "❌ $error")
                    withContext(Dispatchers.Main) {
                        callback(false, error)
                    }
                    return@launch
                }
                
                if (modelSizeMB > 300 && availableMemory < 200) {
                    Log.w(TAG, "⚠️ Low heap memory (${availableMemory}MB available). Model loading may fail.")
                    Log.w(TAG, "💡 Try closing other apps to free up memory")
                }
                
                Log.d(TAG, "✅ Memory check passed. Attempting to load model...")
                Log.d(TAG, "💡 Note: MediaPipe uses memory-mapped I/O, so full model won't load into heap")

                // Configure LLM Inference options for .task files
                // MediaPipe 0.10.18+ has minimalist API - only essential parameters
                val options = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(modelFile.absolutePath)
                    .setMaxTokens(maxTokens)
                    .build()

                Log.d(TAG, "🔄 Creating LlmInference instance...")
                Log.d(TAG, "📦 Model type: ${if (modelFile.name.endsWith(".task")) ".task (MediaPipe-optimized)" else "standard TFLite"}")
                Log.d(TAG, " This may take 30-60 seconds for large models")
                
                // Create LLM Inference instance with detailed error handling
                // For .task files: MediaPipe handles tokenization and chat templates internally
                // For .tflite files: Requires manual chat template formatting
                try {
                    llmInference = LlmInference.createFromOptions(context, options)
                    Log.d(TAG, "✅ LlmInference instance created successfully")
                } catch (e: IllegalStateException) {
                    // Rethrow with more context
                    Log.e(TAG, "❌ IllegalStateException during LlmInference creation")
                    Log.e(TAG, "💡 This usually means the .task file is incompatible with MediaPipe LLM Inference")
                    Log.e(TAG, "💡 The .task file may be from TFLite Task Library instead of MediaPipe LLM")
                    throw IllegalStateException(
                        "Failed to create LlmInference: ${e.message}. " +
                        "The .task file appears to be incompatible with MediaPipe LLM Inference. " +
                        "Please ensure you're using an official MediaPipe Gemma .task model.",
                        e
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Unexpected exception during LlmInference creation: ${e.javaClass.name}")
                    Log.e(TAG, "💡 Error: ${e.message}")
                    throw e
                }
                
                Log.d(TAG, "✅ Gemma model loaded successfully!")
                Log.d(TAG, "🎉 AI-powered chatbot is now available")
                
                withContext(Dispatchers.Main) {
                    callback(true, null)
                }
            } catch (e: OutOfMemoryError) {
                Log.e(TAG, "❌ Out of memory loading model", e)
                withContext(Dispatchers.Main) {
                    callback(false, "Out of memory: Device cannot run this ${modelSizeMB}MB model. Try a smaller model variant.")
                }
            } catch (e: IllegalStateException) {
                // Common for .task file initialization issues
                Log.e(TAG, "❌ IllegalStateException during model loading", e)
                Log.e(TAG, "🔍 Error details: ${e.message}")
                Log.e(TAG, "🔍 Stack trace: ${e.stackTraceToString()}")
                
                val errorMsg = when {
                    e.message?.contains("prefill", ignoreCase = true) == true ||
                    e.message?.contains("decode", ignoreCase = true) == true -> {
                        Log.e(TAG, "💡 This appears to be a model format issue")
                        Log.e(TAG, "💡 The .task file may not have the correct MediaPipe LLM structure")
                        Log.e(TAG, "💡 Try: 1) Re-download the model, 2) Verify it's a MediaPipe Gemma .task file")
                        "Model initialization failed: .task file missing required components (prefill/decode runners). " +
                        "Please ensure you're using an official MediaPipe Gemma .task model."
                    }
                    e.message?.contains("Calculator", ignoreCase = true) == true -> {
                        Log.e(TAG, "💡 MediaPipe calculator graph failed to initialize")
                        Log.e(TAG, "💡 This could indicate: 1) Corrupted .task file, 2) Incompatible model version")
                        "MediaPipe calculator graph error: The .task file may be corrupted or incompatible with this MediaPipe version."
                    }
                    else -> {
                        "Model initialization failed: ${e.message}"
                    }
                }
                
                withContext(Dispatchers.Main) {
                    callback(false, errorMsg)
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error loading Gemma model", e)
                Log.e(TAG, "🔍 Exception type: ${e.javaClass.name}")
                Log.e(TAG, "🔍 Error message: ${e.message}")
                
                val errorMsg = when {
                    e.message?.contains("insufficient memory", ignoreCase = true) == true -> 
                        "Insufficient memory for ${modelSizeMB}MB model"
                    e.message?.contains("SIGSEGV", ignoreCase = true) == true -> 
                        "Native crash - model too large for device"
                    e.javaClass.name.contains("UnsatisfiedLinkError") -> 
                        "Native library error - MediaPipe may not be properly installed"
                    else -> "Failed to load model: ${e.message}"
                }
                withContext(Dispatchers.Main) {
                    callback(false, errorMsg)
                }
            }
        }
    }

    /**
     * Generate text using the Gemma model
     */
    fun generateText(prompt: String, maxTokens: Int, callback: (String?, String?) -> Unit) {
        scope.launch {
            try {
                if (llmInference == null) {
                    withContext(Dispatchers.Main) {
                        callback(null, "Model not initialized")
                    }
                    return@launch
                }

                Log.d(TAG, "🤖 Generating text for prompt (${prompt.length} chars)")
                
                // Use generateResponseAsync for .task files - better compatibility
                // The async method returns a completable future, need to await it
                val response: String? = try {
                    Log.d(TAG, "💡 Attempting async generation (recommended for .task files)...")
                    val asyncResult = llmInference!!.generateResponseAsync(prompt)
                    // Wait for the result
                    asyncResult.get()
                } catch (e: NoSuchMethodError) {
                    // Fallback to sync method if async not available
                    Log.w(TAG, "⚠️ Async method not available, using sync generateResponse()")
                    llmInference!!.generateResponse(prompt)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error during async generation: ${e.message}")
                    throw e
                }
                
                Log.d(TAG, "✅ Generated ${response?.length ?: 0} characters")
                
                withContext(Dispatchers.Main) {
                    if (response != null && response.isNotEmpty()) {
                        callback(response, null)
                    } else {
                        callback(null, "Empty response from model")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error generating text", e)
                withContext(Dispatchers.Main) {
                    callback(null, "Generation failed: ${e.message}")
                }
            }
        }
    }

    /**
     * Generate text asynchronously (streaming would go here)
     */
    suspend fun generateTextAsync(prompt: String): String? {
        return withContext(Dispatchers.IO) {
            try {
                if (llmInference == null) {
                    Log.w(TAG, "⚠️ Model not initialized")
                    return@withContext null
                }

                // Use async method for better .task file compatibility
                val result: String? = try {
                    val asyncResult = llmInference!!.generateResponseAsync(prompt)
                    asyncResult.get()
                } catch (e: NoSuchMethodError) {
                    // Fallback to sync if async not available
                    llmInference!!.generateResponse(prompt)
                }
                result
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error in async generation", e)
                null
            }
        }
    }

    /**
     * Copy model file from assets to cache directory
     * Tries both flutter_assets/ prefix and direct path
     */
    private fun copyAssetToCache(assetPath: String): File? {
        return try {
            val fileName = assetPath.substringAfterLast("/")
            val cacheFile = File(context.cacheDir, fileName)
            
            // Check if already copied
            if (cacheFile.exists()) {
                Log.d(TAG, "📁 Model already in cache: ${cacheFile.absolutePath} (${cacheFile.length()} bytes)")
                return cacheFile
            }

            Log.d(TAG, "📋 Copying model from assets to cache...")
            
            // Try Flutter asset path first (flutter_assets/...)
            val flutterAssetPath = "flutter_assets/$assetPath"
            Log.d(TAG, "🔍 Trying path: $flutterAssetPath")
            
            val inputStream = try {
                context.assets.open(flutterAssetPath)
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Flutter asset path failed, trying direct: $assetPath")
                context.assets.open(assetPath)
            }
            
            // Copy from assets to cache with progress logging
            inputStream.use { input ->
                cacheFile.outputStream().use { output ->
                    val buffer = ByteArray(8192)
                    var bytes: Long = 0
                    var read: Int
                    while (input.read(buffer).also { read = it } != -1) {
                        output.write(buffer, 0, read)
                        bytes += read
                        // Log progress every 10MB for large files
                        if (bytes % (10 * 1024 * 1024) == 0L) {
                            Log.d(TAG, "📥 Copied ${bytes / (1024 * 1024)} MB...")
                        }
                    }
                    Log.d(TAG, "📦 Total copied: ${bytes / (1024 * 1024)} MB")
                }
            }
            
            Log.d(TAG, "✅ Model copied to cache: ${cacheFile.absolutePath} (${cacheFile.length()} bytes)")
            cacheFile
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error copying model from assets: ${e.message}", e)
            null
        }
    }

    /**
     * Dispose of the model and free resources
     */
    fun dispose() {
        try {
            llmInference?.close()
            llmInference = null
            Log.d(TAG, "🗑️ Gemma model disposed")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error disposing model", e)
        }
    }

    /**
     * Check if model is loaded
     */
    fun isLoaded(): Boolean {
        return llmInference != null
    }
}
