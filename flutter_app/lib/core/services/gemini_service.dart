import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

/// Core service for interacting with Google's Gemini AI API
/// Provides both package-based and direct HTTP API approaches
class GeminiService {
  // Use v1beta API with correct model name
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _modelName = 'gemini-2.5-flash';
  
  late final String _apiKey;
  GenerativeModel? _generativeModel;
  
  GeminiService() {
    _initializeService();
  }
  
  void _initializeService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY not found in .env file');
      return;
    }
    
    try {
      // Initialize the Gemini model using the package
      _generativeModel = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
      );
      debugPrint('✅ Gemini service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Gemini service: $e');
    }
  }
  
  /// Generate content using the Gemini API with the package approach
  Future<Map<String, dynamic>?> generateContentWithPackage(String prompt) async {
    if (_generativeModel == null) {
      debugPrint('❌ Gemini model not initialized');
      return null;
    }
    
    try {
      debugPrint('🚀 Generating content with Gemini (Package)...');
      
      final content = [Content.text(prompt)];
      final response = await _generativeModel!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        debugPrint('❌ Empty response from Gemini API');
        return null;
      }
      
      debugPrint('✅ Received response from Gemini');
      return _parseJsonResponse(response.text!);
      
    } catch (e) {
      debugPrint('❌ Error generating content with package: $e');
      return null;
    }
  }
  
  /// Generate content using direct HTTP API calls as fallback
  Future<Map<String, dynamic>?> generateContentWithHttp(String prompt) async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ API key not available for HTTP request');
      return null;
    }
    
    try {
      debugPrint('🚀 Generating content with Gemini (HTTP)...');
      
      // Correct URL format matching official Gemini API
      final url = Uri.parse('$_baseUrl/$_modelName:generateContent');
      
      final requestBody = {
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192,
        }
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        debugPrint('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (responseData['candidates'] == null || 
          (responseData['candidates'] as List).isEmpty) {
        debugPrint('❌ No candidates in response');
        return null;
      }
      
      final candidate = (responseData['candidates'] as List).first;
      if (candidate['content'] == null || 
          candidate['content']['parts'] == null ||
          (candidate['content']['parts'] as List).isEmpty) {
        debugPrint('❌ No content in candidate');
        return null;
      }
      
      final text = candidate['content']['parts'][0]['text'] as String?;
      if (text == null || text.isEmpty) {
        debugPrint('❌ Empty text in response');
        return null;
      }
      
      debugPrint('✅ Received response from Gemini (HTTP)');
      return _parseJsonResponse(text);
      
    } catch (e) {
      debugPrint('❌ Error generating content with HTTP: $e');
      return null;
    }
  }
  
  /// Main method to generate content - tries package first, then HTTP as fallback
  Future<Map<String, dynamic>?> generateContent(String prompt) async {
    // Try package approach first
    Map<String, dynamic>? result = await generateContentWithPackage(prompt);
    
    if (result != null) {
      return result;
    }
    
    debugPrint('📡 Package approach failed, trying HTTP fallback...');
    
    // Fallback to HTTP approach
    result = await generateContentWithHttp(prompt);
    
    if (result != null) {
      return result;
    }
    
    debugPrint('❌ Both package and HTTP approaches failed');
    return null;
  }
  
  /// Parse JSON response from Gemini, handling various response formats
  Map<String, dynamic>? _parseJsonResponse(String responseText) {
    try {
      // Clean the response text
      String cleanedText = responseText.trim();
      
      // Remove markdown code blocks if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.replaceFirst('```json', '').trim();
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.replaceFirst('```', '').trim();
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3).trim();
      }
      
      // Find JSON object boundaries
      int startIndex = cleanedText.indexOf('{');
      int endIndex = cleanedText.lastIndexOf('}');
      
      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        debugPrint('❌ No valid JSON object found in response');
        return null;
      }
      
      String jsonString = cleanedText.substring(startIndex, endIndex + 1);
      
      // Parse JSON
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      
      debugPrint('✅ Successfully parsed JSON response');
      return parsed;
      
    } catch (e) {
      debugPrint('❌ Error parsing JSON response: $e');
      debugPrint('Response text: $responseText');
      return null;
    }
  }
  
  /// Check if the service is properly initialized
  bool get isInitialized => _apiKey.isNotEmpty;
  
  /// Get API key status (for debugging)
  String get apiKeyStatus {
    if (_apiKey.isEmpty) return 'Missing';
    return 'Present (${_apiKey.length} chars)';
  }
}