import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Service for using Gemma-3 LLM model via MediaPipe on Android
/// Uses native Android MediaPipe LLM Inference API through method channels
class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  static const MethodChannel _channel = MethodChannel('com.vistaguide/llm');
  bool _isModelLoaded = false;
  
  // Model download URL - GitHub Releases (.task format for MediaPipe)
  static const String modelUrl = 'https://github.com/HiOmkarrr/VistaGuide/releases/download/model-v1.0/gemma-3-270m-it-int8.task';
  
  // Model filename
  static const String modelFileName = 'gemma-3-270m-it-int8.task';

  /// Initialize the Gemma LLM model via MediaPipe (Android native)
  /// Downloads .task model on first launch, loads from storage on subsequent launches
  Future<bool> initializeModel() async {
    if (_isModelLoaded) return true;

    try {
      if (kDebugMode) {
        print('🔄 Loading Gemma 270M LLM model via MediaPipe (Android)...');
        print('📦 Model: $modelFileName (303MB .task format)');
      }

      // Get the model file path in app storage
      final modelFile = await _getModelFile();
      
      // Check if model exists, if not it will be downloaded by ModelInitializationPage
      if (!await modelFile.exists()) {
        if (kDebugMode) {
          print('❌ Model not found at: ${modelFile.path}');
          print('💡 Model needs to be downloaded first');
        }
        return false;
      }

      // Call native Android code to initialize Gemma with MediaPipe
      // Use absolute path (not asset path) since model is downloaded to storage
      final result = await _channel.invokeMethod<bool>('initializeGemma', {
        'modelPath': modelFile.absolute.path,  // Absolute file path
        'maxTokens': 512,
      });

      _isModelLoaded = result ?? false;

      if (_isModelLoaded) {
        if (kDebugMode) {
          print('✅ Gemma LLM model loaded successfully via MediaPipe');
          print('💡 AI-powered chatbot is now available');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Failed to load Gemma model (insufficient device memory)');
          print('💡 Your device needs at least 1GB free RAM to run the 524MB AI model');
          print('💡 Smart text extraction will be used instead');
          print('💡 Consider using a smaller model variant (e.g., gemma-2B-it-int8) for lower-end devices');
        }
      }

      return _isModelLoaded;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ Platform error loading Gemma: ${e.message}');
        
        // Check for specific error types
        if (e.message?.contains('incompatible') == true || 
            e.message?.contains('prefill') == true ||
            e.message?.contains('decode') == true) {
          print('💡 Model format incompatibility detected!');
          print('💡 The .task file may not be a proper MediaPipe LLM model');
          print('💡 Please ensure you\'re using an official MediaPipe Gemma .task file');
          print('💡 See MEDIAPIPE_TASK_RESEARCH.md for details');
        } else if (e.message?.contains('memory') == true || 
                   e.message?.contains('Insufficient') == true) {
          print('💡 Device RAM insufficient for ${modelFileName}');
          print('💡 Recommendation: Use a smaller quantized model');
        } else if (e.message?.contains('corrupted') == true) {
          print('💡 Model file may be corrupted - try re-downloading');
        }
        
        print('💡 Falling back to smart text extraction + Gemini API');
      }
      _isModelLoaded = false;
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Gemma LLM model: $e');
        print('💡 Falling back to smart text extraction');
      }
      _isModelLoaded = false;
      return false;
    }
  }
  
  /// Get the local file path for the model
  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return File('${modelDir.path}/$modelFileName');
  }
  
  /// Check if the model is already downloaded
  Future<bool> isModelDownloaded() async {
    try {
      final modelFile = await _getModelFile();
      final exists = await modelFile.exists();
      
      if (exists) {
        final size = await modelFile.length();
        if (kDebugMode) {
          print('✅ Model found: ${modelFile.path} (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
        }
        // Check if file is complete (should be around 524MB)
        return size > 500 * 1024 * 1024; // At least 500MB
      }
      
      if (kDebugMode) {
        print('❌ Model not found at: ${modelFile.path}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking model: $e');
      }
      return false;
    }
  }
  
  /// Download the model file from GitHub Releases
  /// GitHub provides reliable direct downloads with proper content-length headers
  Future<bool> downloadModel({Function(double)? onProgress}) async {
    try {
      final modelFile = await _getModelFile();
      
      if (await modelFile.exists()) {
        final size = await modelFile.length();
        // Check if file is complete (should be around 289MB for .task model)
        if (size > 280 * 1024 * 1024) {
          if (kDebugMode) {
            print('✅ Model already downloaded (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)');
          }
          return true;
        } else {
          // Partial download, delete and re-download
          if (kDebugMode) {
            print('⚠️ Incomplete model file found (${(size / (1024 * 1024)).toStringAsFixed(1)} MB), re-downloading...');
          }
          await modelFile.delete();
        }
      }
      
      if (kDebugMode) {
        print('📥 Downloading Gemma model from GitHub Releases (289MB)...');
        print('🔗 This may take 3-5 minutes depending on your connection');
        print('🔗 URL: $modelUrl');
      }
      
      // Simple direct download from GitHub Releases
      final client = http.Client();
      final response = await client.send(http.Request('GET', Uri.parse(modelUrl)));
      
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('❌ Download failed: HTTP ${response.statusCode}');
          if (response.statusCode == 404) {
            print('💡 Model not found. Please ensure GitHub Release is published.');
          }
        }
        client.close();
        return false;
      }
      
      // GitHub provides accurate content-length
      final totalBytes = response.contentLength ?? 303763456; // 289 MB fallback
      var downloadedBytes = 0;
      
      if (kDebugMode) {
        print('📦 Expected size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB');
      }
      
      final sink = modelFile.openWrite();
      var lastProgressUpdate = DateTime.now();
      var lastLoggedMB = 0;
      
      try {
        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          
          // Update progress
          final progress = totalBytes > 0 && totalBytes > downloadedBytes
              ? downloadedBytes / totalBytes
              : downloadedBytes / 303763456; // Use known size (289 MB)
          
          // Call progress callback (throttle to once per second)
          final now = DateTime.now();
          if (now.difference(lastProgressUpdate).inMilliseconds > 1000) {
            onProgress?.call(progress.clamp(0.0, 1.0));
            lastProgressUpdate = now;
          }
          
          // Log progress every 50MB
          final currentMB = downloadedBytes ~/ (50 * 1024 * 1024);
          if (kDebugMode && currentMB > lastLoggedMB) {
            print('📥 Downloaded ${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB...');
            lastLoggedMB = currentMB;
          }
        }
      } finally {
        await sink.close();
        client.close();
      }
      
      // Verify download
      final finalSize = await modelFile.length();
      
      if (kDebugMode) {
        print('📦 Download complete: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      }
      
      // Check if we got HTML error page instead of file
      if (finalSize < 1024 * 1024) { // Less than 1MB is suspicious
        if (kDebugMode) {
          print('❌ Downloaded file too small (${(finalSize / 1024).toStringAsFixed(1)} KB)');
          print('💡 Google Drive download blocked. Alternative solutions:');
          print('   1. Use Firebase Storage instead of Google Drive');
          print('   2. Use Dropbox or OneDrive with direct download link');
          print('   3. Host on GitHub Releases');
          print('   4. Use a CDN service');
        }
        await modelFile.delete();
        return false;
      }
      
      if (finalSize < 280 * 1024 * 1024) {
        if (kDebugMode) {
          print('❌ Download incomplete: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB (expected ~289 MB)');
        }
        await modelFile.delete();
        return false;
      }
      
      if (kDebugMode) {
        print('✅ Model downloaded successfully: ${modelFile.path}');
        print('📦 Final size: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      }
      
      // Final progress update
      onProgress?.call(1.0);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error downloading model: $e');
      }
      
      // Clean up partial download
      try {
        final modelFile = await _getModelFile();
        if (await modelFile.exists()) {
          await modelFile.delete();
        }
      } catch (_) {}
      
      return false;
    }
  }

  /// Generate text response using Gemma LLM via MediaPipe
  /// Returns null if generation fails, allowing fallback to rule-based responses
  Future<String?> generateText({
    required String prompt,
    int maxTokens = 256,
  }) async {
    if (!_isModelLoaded) {
      if (kDebugMode) {
        print('⚠️ LLM model not loaded, using fallback responses');
      }
      return null; // Trigger fallback
    }

    try {
      if (kDebugMode) {
        print('🤖 Generating response with Gemma via MediaPipe...');
        print('📝 Prompt length: ${prompt.length} characters');
      }

      // Call native Android code to generate text
      final response = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
        'maxTokens': maxTokens,
      });

      if (response == null || response.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Empty response from LLM');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Generated ${response.length} characters');
      }

      return response.trim();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ Platform error generating text: ${e.message}');
        
        // Check if this is a model incompatibility error
        if (e.message?.contains('signature') == true ||
            e.message?.contains('Calculator') == true ||
            e.message?.contains('prefill') == true) {
          print('💡 CRITICAL: Model format incompatibility detected during generation!');
          print('💡 The .task file loaded successfully but cannot generate text');
          print('💡 This confirms the model is NOT a proper MediaPipe LLM .task file');
          print('💡 Marking model as failed to prevent future attempts');
          
          // Mark model as not loaded to prevent future attempts
          _isModelLoaded = false;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating text: $e');
      }
      return null; // Trigger fallback
    }
  }

  /// Format landmark info using LLM or fallback
  Future<String> formatLandmarkInfo(String rawInfo, String landmarkName) async {
    if (!_isModelLoaded) {
      return _cleanupRawInfo(rawInfo);
    }

    try {
      final prompt = '''Format this landmark information clearly and concisely (max 150 words):

Landmark: $landmarkName

Information: $rawInfo

Formatted:''';

      final result = await generateText(prompt: prompt, maxTokens: 200);

      if (result == null || result.isEmpty) {
        return _cleanupRawInfo(rawInfo);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error formatting with LLM: $e');
      }
      return _cleanupRawInfo(rawInfo);
    }
  }

  /// Generate landmark info using LLM or fallback
  Future<String> generateLandmarkInfo(String landmarkName) async {
    if (!_isModelLoaded) {
      return 'Information about $landmarkName. This landmark is located in India and is a notable site of historical or cultural significance.';
    }

    try {
      final prompt = '''Provide a brief description of this Indian landmark (max 120 words):

Landmark: $landmarkName

Include: location, historical significance, key features.

Description:''';

      final result = await generateText(prompt: prompt, maxTokens: 180);

      if (result == null || result.isEmpty) {
        return 'Information about $landmarkName. Please try again or search online for more details.';
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating with LLM: $e');
      }
      return 'Information about $landmarkName is currently unavailable.';
    }
  }

  /// Cleanup raw landmark info (fallback when LLM not available)
  String _cleanupRawInfo(String rawInfo) {
    if (rawInfo.isEmpty) return '';
    String cleaned = rawInfo.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length > 500) cleaned = cleaned.substring(0, 497) + '...';
    final sentences = cleaned.split(RegExp(r'[.!?]\s+'));
    if (sentences.length > 4) cleaned = sentences.take(4).join('. ') + '.';
    return cleaned;
  }

  bool get isModelLoaded => _isModelLoaded;

  void dispose() {
    if (_isModelLoaded) {
      _channel.invokeMethod('disposeGemma');
    }
    _isModelLoaded = false;

    if (kDebugMode) {
      print('🗑️ LLM service disposed');
    }
  }
}

