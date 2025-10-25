import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'llm_service.dart';

/// Hybrid LLM service that uses Gemini API when online, Gemma when offline
class ChatbotLlmService {
  final LlmService _gemmaService;
  GenerativeModel? _geminiModel;
  bool _isOnline = false;
  
  ChatbotLlmService(this._gemmaService) {
    _initializeGemini();
  }

  /// Initialize Gemini model if API key is available
  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 500,
        ),
      );
      print('✅ Gemini API initialized');
    } else {
      print('⚠️ Gemini API key not found, will use offline mode only');
    }
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) || 
             connectivityResult.contains(ConnectivityResult.wifi) ||
             connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Get current LLM status (online/offline)
  Future<LlmStatus> getStatus() async {
    _isOnline = await _checkConnectivity();
    
    if (_isOnline && _geminiModel != null) {
      return LlmStatus.geminiOnline;
    } else if (!_isOnline) {
      return LlmStatus.gemmaOffline;
    } else {
      return LlmStatus.gemmaFallback; // No API key but has internet
    }
  }

  /// Generate response using hybrid approach
  /// - Online: Use Gemini with full context and detailed prompts
  /// - Offline: Use Gemma with simplified context
  Future<ChatbotResponse> generateResponse({
    required String userQuery,
    required String landmarkInfo,
    String? landmarkName,
  }) async {
    final status = await getStatus();
    
    print('🤖 LLM Status: $status');
    
    if (status == LlmStatus.geminiOnline) {
      return await _generateGeminiResponse(
        userQuery: userQuery,
        landmarkInfo: landmarkInfo,
        landmarkName: landmarkName,
      );
    } else {
      // Fallback to Gemma (offline or no API key)
      return await _generateGemmaResponse(
        userQuery: userQuery,
        landmarkInfo: landmarkInfo,
        landmarkName: landmarkName,
      );
    }
  }

  /// Generate response using Gemini API (online mode)
  Future<ChatbotResponse> _generateGeminiResponse({
    required String userQuery,
    required String landmarkInfo,
    String? landmarkName,
  }) async {
    try {
      print('🌐 Using Gemini API (online mode)');
      
      // Create comprehensive prompt for Gemini
      final prompt = _buildGeminiPrompt(
        userQuery: userQuery,
        landmarkInfo: landmarkInfo,
        landmarkName: landmarkName,
      );

      // Generate response with timeout
      final content = [Content.text(prompt)];
      final response = await _geminiModel!.generateContent(content)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Gemini API timeout - likely no internet connection');
            },
          );
      
      final responseText = response.text ?? '';
      
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      print('✅ Gemini response received (${responseText.length} chars)');
      
      return ChatbotResponse(
        text: responseText,
        source: LlmSource.gemini,
        success: true,
      );
      
    } catch (e) {
      print('❌ Gemini API failed: $e');
      print('🔄 Falling back to offline Gemma model');
      
      // Update online status since Gemini failed
      _isOnline = false;
      
      // Fallback to Gemma if Gemini fails
      return await _generateGemmaResponse(
        userQuery: userQuery,
        landmarkInfo: landmarkInfo,
        landmarkName: landmarkName,
      );
    }
  }

  /// Generate response using Gemma model (offline mode)
  Future<ChatbotResponse> _generateGemmaResponse({
    required String userQuery,
    required String landmarkInfo,
    String? landmarkName,
  }) async {
    try {
      print('📱 Using Gemma model (offline mode)');
      
      // Note: The RAG pipeline (classification, context extraction) 
      // will be handled by the calling page for Gemma
      // This method just calls the LLM with the prepared prompt
      
      return ChatbotResponse(
        text: '', // Will be filled by the calling page's RAG pipeline
        source: LlmSource.gemma,
        success: true,
        useRagPipeline: true, // Signal to use RAG pipeline
      );
      
    } catch (e) {
      print('❌ Gemma model failed: $e');
      return ChatbotResponse(
        text: 'I apologize, but I encountered an error processing your request. Please try again.',
        source: LlmSource.gemma,
        success: false,
      );
    }
  }

  /// Build comprehensive prompt for Gemini API
  String _buildGeminiPrompt({
    required String userQuery,
    required String landmarkInfo,
    String? landmarkName,
  }) {
    final landmarkContext = landmarkName != null 
        ? 'You are a knowledgeable travel guide assistant helping tourists learn about "$landmarkName".'
        : 'You are a knowledgeable travel guide assistant helping tourists.';

    return '''
$landmarkContext

LANDMARK BACKGROUND NOTES:
$landmarkInfo

USER QUESTION: $userQuery

CRITICAL RULES - YOU MUST FOLLOW THESE:
1. NEVER use these phrases or similar ones:
   ❌ "the provided information"
   ❌ "the information doesn't mention"
   ❌ "based on the information"
   ❌ "the details don't include"
   ❌ "the database"
   ❌ "the data"
   ❌ "loaded information"
   ❌ "available information"
   ❌ "my knowledge base"
   ❌ "according to the information"
   
2. Instead, respond naturally like a human guide:
   ✅ "I'm not sure about specific..."
   ✅ "I don't have details on..."
   ✅ "You'll typically find..."
   ✅ "Most visitors notice..."
   ✅ "From what I know..."
   ✅ "Generally speaking..."

INSTRUCTIONS:
1. Answer the user's question in a helpful, friendly, and informative manner
2. Use the background notes above when relevant, but NEVER reference them directly
3. For questions requiring information beyond what you know:
   - Use your knowledge to provide helpful general guidance
   - For practical questions (food, facilities, activities):
     * Share typical tourist experiences
     * Mention common options found in similar locations
     * Provide useful general advice
   - If you're not certain about specifics, simply say "I'm not sure about that specific detail"
4. Keep responses concise but comprehensive (2-4 sentences typically)
5. Be conversational and engaging, like a knowledgeable local guide
6. For location/directions: Provide general guidance and suggest using maps for precise navigation
7. Never make up specific facts about historical dates, architecture details, or statistics
8. If asked about something completely unrelated to travel or tourism:
   - Politely acknowledge the question
   - Briefly answer if it's general knowledge
   - Gently redirect to how you can help with their visit

RESPONSE STYLE:
- Direct and to the point
- Warm and helpful tone
- Avoid asterisks, special formatting, or bullet points
- Write in natural, flowing sentences
- Start directly with the answer (no "Based on..." or "According to...")
- NEVER reference technical terms like "database", "system", "loaded", "available data", etc.
- Sound like a friendly human guide who has broad knowledge, not a computer system
- When providing general information, phrase it naturally (e.g., "You'll typically find...", "Most visitors enjoy...", "The area usually has...")

Answer the question now:
''';
  }

  /// Call Gemma service directly (used by RAG pipeline)
  Future<String> callGemmaModel(String prompt, int maxTokens) async {
    final response = await _gemmaService.generateText(
      prompt: prompt,
      maxTokens: maxTokens,
    );
    return response ?? '';
  }
}

/// LLM status enum
enum LlmStatus {
  geminiOnline,    // Online with Gemini API
  gemmaOffline,    // Offline, using Gemma
  gemmaFallback,   // Online but no API key, using Gemma
}

/// LLM source enum
enum LlmSource {
  gemini,  // Gemini API (online)
  gemma,   // Gemma on-device (offline)
}

/// Response from chatbot LLM
class ChatbotResponse {
  final String text;
  final LlmSource source;
  final bool success;
  final bool useRagPipeline;

  ChatbotResponse({
    required this.text,
    required this.source,
    required this.success,
    this.useRagPipeline = false,
  });
}
