import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/landmark_recognition/data/services/llm_service.dart';

/// Service to handle app startup tasks including AI model initialization
class StartupService {
  static final StartupService _instance = StartupService._internal();
  factory StartupService() => _instance;
  StartupService._internal();

  static const String _keyModelDownloadAttempted = 'model_download_attempted';
  static const String _keyModelDownloadCompleted = 'model_download_completed';
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize app on first launch - downloads model if not present
  /// Returns true if model is ready, false if download failed/skipped
  Future<bool> initializeOnFirstLaunch({
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    if (_isInitialized) {
      return await LlmService().isModelDownloaded();
    }

    final prefs = await SharedPreferences.getInstance();
    final llmService = LlmService();
    
    // Check if model already exists
    onStatusUpdate?.call('Checking AI model...');
    final modelExists = await llmService.isModelDownloaded();
    
    if (modelExists) {
      if (kDebugMode) {
        print('✅ AI model already downloaded');
      }
      _isInitialized = true;
      await prefs.setBool(_keyModelDownloadCompleted, true);
      return true;
    }
    
    // Check if we've already attempted download in a previous session
    final downloadAttempted = prefs.getBool(_keyModelDownloadAttempted) ?? false;
    
    if (downloadAttempted) {
      // Don't auto-download again if user previously skipped
      if (kDebugMode) {
        print('ℹ️ Model download was previously attempted, skipping auto-download');
      }
      _isInitialized = true;
      return false;
    }
    
    // First launch - attempt to download model
    if (kDebugMode) {
      print('📥 First launch: Downloading AI model...');
    }
    
    onStatusUpdate?.call('Downloading AI model (524 MB)...');
    await prefs.setBool(_keyModelDownloadAttempted, true);
    
    final success = await llmService.downloadModel(
      onProgress: (progress) {
        onProgress?.call(progress);
      },
    );
    
    if (success) {
      await prefs.setBool(_keyModelDownloadCompleted, true);
      onStatusUpdate?.call('AI model ready!');
      
      // Initialize the model
      await llmService.initializeModel();
    } else {
      onStatusUpdate?.call('Download failed - using fallback mode');
    }
    
    _isInitialized = true;
    return success;
  }
  
  /// Check if model download should be offered to user
  Future<bool> shouldOfferModelDownload() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_keyModelDownloadCompleted) ?? false;
    
    if (completed) {
      // Already downloaded, verify it still exists
      return !(await LlmService().isModelDownloaded());
    }
    
    // Not completed, check if model exists anyway
    return !(await LlmService().isModelDownloaded());
  }
  
  /// Reset download status (for testing)
  Future<void> resetDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyModelDownloadAttempted);
    await prefs.remove(_keyModelDownloadCompleted);
    _isInitialized = false;
  }
}
