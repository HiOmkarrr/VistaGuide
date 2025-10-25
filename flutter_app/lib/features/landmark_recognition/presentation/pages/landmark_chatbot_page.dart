import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/landmark_recognition.dart';
import '../../data/services/landmark_csv_service.dart';
import '../../data/services/llm_service.dart';
import '../../data/services/chatbot_llm_service.dart';

/// Question classification types for RAG pipeline (used for Gemma offline mode)
enum QuestionType {
  location,
  history,
  festivals,
  activities,
  visitingInfo,
  significance,
  facilities,
  architecture,
  crowdInfo,
  general,
}

/// Chatbot page for learning more about a recognized landmark
/// Uses Gemini API when online, falls back to Gemma LLM when offline
class LandmarkChatbotPage extends StatefulWidget {
  final LandmarkRecognition recognition;
  final int landmarkId;

  const LandmarkChatbotPage({
    super.key,
    required this.recognition,
    required this.landmarkId,
  });

  @override
  State<LandmarkChatbotPage> createState() => _LandmarkChatbotPageState();
}

class _LandmarkChatbotPageState extends State<LandmarkChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final LandmarkCsvService _csvService = LandmarkCsvService();
  late final ChatbotLlmService _chatbotLlmService;
  
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _landmarkInfo;
  String? _landmarkName;
  LlmStatus _currentLlmStatus = LlmStatus.gemmaOffline;

  @override
  void initState() {
    super.initState();
    _chatbotLlmService = ChatbotLlmService(LlmService());
    _initializeChatbot();
  }

  Future<void> _initializeChatbot() async {
    setState(() => _isInitializing = true);

    try {
      if (kDebugMode) {
        print('🤖 Initializing chatbot for landmark ID: ${widget.landmarkId}');
      }

      // Check LLM status (online/offline)
      _currentLlmStatus = await _chatbotLlmService.getStatus();
      if (kDebugMode) {
        print('🌐 LLM Status: $_currentLlmStatus');
      }

      // Load landmark information from CSV
      final landmark = await _csvService.getLandmarkById(widget.landmarkId);
      
      if (landmark != null) {
        _landmarkInfo = landmark.landmarkInfo;
        _landmarkName = landmark.landmarkName.replaceAll('_', ' ');
        
        if (kDebugMode) {
          print('✅ Landmark found: $_landmarkName');
          print('📝 Info available: ${_landmarkInfo?.isNotEmpty ?? false}');
          if (_landmarkInfo != null && _landmarkInfo!.isNotEmpty) {
            print('📄 Info length: ${_landmarkInfo!.length} characters');
            print('📄 Info preview: ${_landmarkInfo!.substring(0, _landmarkInfo!.length > 100 ? 100 : _landmarkInfo!.length)}...');
          }
        }
      } else {
        _landmarkInfo = null;
        _landmarkName = widget.recognition.landmarkName.replaceAll('_', ' ');
        
        if (kDebugMode) {
          print('⚠️ Landmark not found in CSV, using recognition name: $_landmarkName');
        }
      }

      // Add welcome message
      _addBotMessage(
        _landmarkInfo != null && _landmarkInfo!.isNotEmpty
            ? 'Hello! I\'m here to help you learn more about $_landmarkName. Ask me anything about this landmark!'
            : 'Hello! I can help answer your questions about $_landmarkName, though detailed information is limited. Feel free to ask!',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing chatbot: $e');
      }
      _addBotMessage(
        'Hi! I\'m ready to answer your questions about ${widget.recognition.landmarkName.replaceAll('_', ' ')}.',
      );
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    if (kDebugMode) {
      print('💬 User message: $message');
    }

    _messageController.clear();
    _addUserMessage(message);

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('🔄 Generating response...');
      }

      // Generate response using RAG approach
      final response = await _generateResponse(message);
      
      if (kDebugMode) {
        print('✅ Bot response: $response');
      }
      
      _addBotMessage(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating response: $e');
      }
      _addBotMessage(
        'I apologize, but I encountered an error processing your question. Please try rephrasing it.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _generateResponse(String userQuery) async {
    // HYBRID LLM APPROACH:
    // - Online: Use Gemini API with full context and comprehensive prompts
    // - Offline: Use Gemma with RAG pipeline (classification → extraction → focused prompt)

    if (kDebugMode) {
      print('🔍 Generating response for: "$userQuery"');
    }

    // Detect if user is just acknowledging or saying thanks
    final lowerQuery = userQuery.toLowerCase().trim();
    final isAcknowledgment = lowerQuery.length < 15 && (
      lowerQuery.contains('ok') || 
      lowerQuery.contains('thanks') || 
      lowerQuery.contains('thank you') ||
      lowerQuery.contains('got it') ||
      lowerQuery.contains('alright') ||
      lowerQuery.contains('cool') ||
      lowerQuery.contains('nice')
    );
    
    // For acknowledgments, give a simple friendly response
    if (isAcknowledgment) {
      final responses = [
        'You\'re welcome! Feel free to ask if you have more questions about $_landmarkName.',
        'Happy to help! Let me know if you need anything else.',
        'Glad I could help! Ask away if you have more questions.',
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }

    try {
      // Check current connectivity status
      final previousStatus = _currentLlmStatus;
      _currentLlmStatus = await _chatbotLlmService.getStatus();
      
      // If status changed from online to offline, trigger UI update
      if (previousStatus == LlmStatus.geminiOnline && 
          _currentLlmStatus == LlmStatus.gemmaOffline) {
        setState(() {}); // Update UI to show offline banner
      }
      
      // Try to generate response using hybrid service
      final response = await _chatbotLlmService.generateResponse(
        userQuery: userQuery,
        landmarkInfo: _landmarkInfo ?? '',
        landmarkName: _landmarkName,
      );

      if (response.success) {
        if (response.useRagPipeline) {
          // Offline mode: Use RAG pipeline with Gemma
          final gemmaResponse = await _generateGemmaResponse(userQuery);
          
          // Update status after Gemma attempt (might have failed)
          _currentLlmStatus = await _chatbotLlmService.getStatus();
          if (previousStatus != _currentLlmStatus) {
            setState(() {}); // Update UI if status changed
          }
          
          return gemmaResponse;
        } else {
          // Online mode: Gemini already provided response
          if (kDebugMode) {
            print('✅ Gemini response (${response.text.length} chars)');
          }
          return response.text;
        }
      } else {
        // Error occurred
        return 'I apologize, but I encountered an error. Please try again.';
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hybrid LLM error: $e');
      }
      
      // Update status and UI
      _currentLlmStatus = await _chatbotLlmService.getStatus();
      setState(() {}); // Update UI to show offline banner if needed
      
      // Fallback to offline Gemma
      return await _generateGemmaResponse(userQuery);
    }
  }

  /// Generate response using Gemma with RAG pipeline (offline mode)
  Future<String> _generateGemmaResponse(String userQuery) async {
    // RAG Pipeline for Gemma:
    // 1. Classify question type using rule-based system
    // 2. Extract ONLY relevant context for that question type
    // 3. Generate response using focused context

    final lowerQuery = userQuery.toLowerCase().trim();

    // Step 1: Classify question type
    final questionType = _classifyQuestion(lowerQuery);
    
    if (kDebugMode) {
      print('📊 Question classified as: $questionType');
    }

    // Step 2: Extract relevant context based on question type
    final relevantContext = _extractRelevantContext(questionType, lowerQuery);
    
    if (kDebugMode) {
      if (relevantContext != null) {
        print('✂️ Extracted context: ${relevantContext.substring(0, relevantContext.length > 100 ? 100 : relevantContext.length)}...');
      } else {
        print('❌ No relevant context found for this question type');
      }
    }

    // Step 3: Build focused prompt with extracted context only
    final prompt = _buildFocusedPrompt(userQuery, relevantContext);

    // Try to use Gemma LLM for response generation
    try {
      if (kDebugMode) {
        print('🤖 Attempting Gemma LLM generation...');
      }

      final llmResponse = await _chatbotLlmService.callGemmaModel(
        prompt,
        80, // Increased to allow proper 2-sentence responses (50-60 words)
      );

      if (llmResponse.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Gemma response received (${llmResponse.length} chars): ${llmResponse.substring(0, llmResponse.length > 100 ? 100 : llmResponse.length)}...');
        }
        
        // Clean and sanitize LLM response
        final cleaned = _cleanLLMResponse(llmResponse);
        
        if (kDebugMode) {
          print('📏 Final response length: ${cleaned.length} chars');
        }
        
        return cleaned;
      }
      
      if (kDebugMode) {
        print('⚠️ Gemma returned empty, using intelligent fallback');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemma generation failed: $e');
      }
    }
    
    // Intelligent fallback: Try to provide a helpful response based on context
    if (relevantContext != null && relevantContext.isNotEmpty) {
      // If we have relevant context, provide it naturally
      return relevantContext;
    }
    
    // If no relevant context, provide a helpful offline message
    return 'I\'m currently in offline mode and don\'t have specific information about that. Try reconnecting to the internet for more detailed answers, or ask me something else about $_landmarkName.';
  }

  /// Comprehensive LLM response cleaning and sanitization
  String _cleanLLMResponse(String response) {
    var cleaned = response.trim();
    
    // FIRST: Remove escape sequences (do this BEFORE other cleaning)
    // This prevents \n from becoming 'n' when backslash is removed
    cleaned = cleaned.replaceAll(r'\n', ' ');  // \n → space
    cleaned = cleaned.replaceAll(r'\r', ' ');  // \r → space
    cleaned = cleaned.replaceAll(r'\t', ' ');  // \t → space
    cleaned = cleaned.replaceAll('\\', '');     // Any remaining backslashes
    
    // Remove actual newline characters (if any)
    cleaned = cleaned.replaceAll('\n', ' ');
    cleaned = cleaned.replaceAll('\r', ' ');
    cleaned = cleaned.replaceAll('\t', ' ');
    
    // Remove common LLM prefixes
    cleaned = cleaned.replaceFirst(RegExp(r'^\s*'), '');  // Leading whitespace
    cleaned = cleaned.replaceFirst(RegExp(r'^(Answer|A):\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^The answer is:?\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^Response:?\s*', caseSensitive: false), '');
    
    // Remove asterisks (markdown bold/italic markers)
    cleaned = cleaned.replaceAll('*', '');
    
    // Clean up forward slashes if they appear redundantly (but keep normal ones)
    // Only remove if they appear multiple times consecutively
    cleaned = cleaned.replaceAll(RegExp(r'/+'), '/');
    
    // Remove multiple spaces (normalize whitespace)
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove markdown headers (#, ##, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s*'), '');
    
    // Remove markdown list markers (-, *, •)
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*•]\s*'), '');
    
    // Remove quotes at the beginning and end if present
    cleaned = cleaned.replaceFirst(RegExp(r'^"'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'"$'), '');
    cleaned = cleaned.replaceFirst(RegExp(r"^'"), '');
    cleaned = cleaned.replaceFirst(RegExp(r"'$"), '');
    
    // Remove any HTML-like tags if present
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    
    // Remove special unicode characters that might cause issues
    cleaned = cleaned.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), ''); // Zero-width chars
    
    // Remove trailing punctuation if duplicated (e.g., ".." -> ".")
    cleaned = cleaned.replaceAll(RegExp(r'\.\.+'), '.');
    cleaned = cleaned.replaceAll(RegExp(r'\?\?+'), '?');
    cleaned = cleaned.replaceAll(RegExp(r'!!+'), '!');
    
    // Final trim to remove any remaining whitespace
    cleaned = cleaned.trim();
    
    // Ensure sentence starts with capital letter
    if (cleaned.isNotEmpty && cleaned[0] == cleaned[0].toLowerCase()) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    if (kDebugMode) {
      print('🧹 Cleaned response: $cleaned');
    }
    
    return cleaned;
  }

  /// Robust rule-based question classifier with improved pattern matching
  QuestionType _classifyQuestion(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Location-related questions (most specific first)
    if (RegExp(r'\b(where|location|located|situated|position|address|place|area|city|state|region|distance|far|away|near|nearby|close|reach|get to|go to|directions|how to reach|route|map|coordinates)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('which city') ||
        lowerQuery.contains('which state') ||
        lowerQuery.contains('which district') ||
        lowerQuery.contains('find this')) {
      return QuestionType.location;
    }
    
    // History-related questions
    if (RegExp(r'\b(history|historical|historic|built|constructed|established|founded|created|made|when was|who built|who made|who created|age|how old|ancient|origin|heritage|background|past|year|century|era|period|dynasty|empire|emperor|king|queen|ruler|reign)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('how long ago') ||
        lowerQuery.contains('years old') ||
        lowerQuery.contains('time period')) {
      return QuestionType.history;
    }
    
    // Festival/Events questions
    if (RegExp(r'\b(festival|event|celebration|ceremony|ritual|worship|prayer|gathering|fair|mela|function|occasion|celebrate|observed|held|organized|cultural event|religious event|annual event)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('what happens') ||
        lowerQuery.contains('special day') ||
        lowerQuery.contains('celebrate here')) {
      return QuestionType.festivals;
    }
    
    // Activities/Things to do (high priority)
    if (RegExp(r'\b(do here|do there|things to do|activities|activity|visit|enjoy|experience|explore|can i|what can|may i|allowed|permitted|try|sports|recreation|recreational|boating|boat|swim|swimming|trek|trekking|hiking|walk|walking|photography|picnic|play)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('what to do') ||
        lowerQuery.contains('can we') ||
        lowerQuery.contains('is it possible')) {
      return QuestionType.activities;
    }
    
    // Visiting info (timings, fees, etc.)
    if (RegExp(r'\b(timing|timings|schedule|hours|time|open|opens|close|closes|closed|entry|entries|ticket|tickets|pass|fee|fees|price|prices|cost|costs|charge|charges|admission|visiting hours|visit time|opening time|closing time|when can|available)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('how much') ||
        lowerQuery.contains('free entry') ||
        lowerQuery.contains('entry fee')) {
      return QuestionType.visitingInfo;
    }
    
    // Significance/Fame questions
    if (RegExp(r'\b(famous|well known|known for|significance|important|why|popular|special|unique|notable|renowned|celebrated|distinguished|outstanding|remarkable|exceptional|main attraction|highlight)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('why is it') ||
        lowerQuery.contains('what makes') ||
        lowerQuery.contains('stands out')) {
      return QuestionType.significance;
    }
    
    // Facilities/Amenities (food, parking, etc.)
    if (RegExp(r'\b(food|foods|eat|eating|restaurant|restaurants|cafe|cafes|dining|snack|snacks|meal|meals|hotel|hotels|lodge|lodging|accommodation|stay|staying|parking|park|toilet|toilets|washroom|washrooms|restroom|restrooms|facilities|facility|amenities|amenity|shop|shops|shopping|store|stores|vendor|vendors|stall|stalls|market|available|sell|selling)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('where can i') ||
        lowerQuery.contains('is there a') ||
        lowerQuery.contains('are there any') ||
        lowerQuery.contains('can i find') ||
        lowerQuery.contains('fast food') ||
        lowerQuery.contains('street food')) {
      return QuestionType.facilities;
    }
    
    // Architecture/Features
    if (RegExp(r'\b(architecture|architectural|design|designed|structure|structural|built|construction|style|pattern|feature|features|column|columns|pillar|pillars|dome|domes|tower|towers|gate|gates|wall|walls|carving|carvings|sculpture|sculptures|statue|statues|monument|material|materials|stone|marble|granite)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('made of') ||
        lowerQuery.contains('looks like') ||
        lowerQuery.contains('what type')) {
      return QuestionType.architecture;
    }
    
    // Crowd/Tourism (when to visit, how busy)
    if (RegExp(r'\b(crowd|crowded|crowding|busy|busiest|rush|rushed|tourist|tourists|tourism|visitor|visitors|people|peaceful|quiet|calm|best time|good time|ideal time|recommended time|peak|off peak|weekend|weekday|season|seasonal)\b').hasMatch(lowerQuery) ||
        lowerQuery.contains('how many people') ||
        lowerQuery.contains('lots of') ||
        lowerQuery.contains('when should') ||
        lowerQuery.contains('when to visit')) {
      return QuestionType.crowdInfo;
    }
    
    // General information (catch-all for overview questions)
    if (RegExp(r'\b(what|about|tell me|describe|explain|info|information|detail|details|overview|summary|general|know|learn|understand)\b').hasMatch(lowerQuery)) {
      return QuestionType.general;
    }
    
    // Default to general if no pattern matches
    return QuestionType.general;
  }

  /// Extract ONLY relevant context for the question type
  String? _extractRelevantContext(QuestionType type, String query) {
    if (_landmarkInfo == null || _landmarkInfo!.isEmpty) {
      return null; // No context available
    }

    final cleanInfo = _landmarkInfo!
        .replaceAll(RegExp(r'\[\s*\d+\s*\]'), '') // Remove citations
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Split into sentences for extraction
    final sentences = cleanInfo.split(RegExp(r'[.!?]+\s*'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    List<String> relevantSentences = [];

    switch (type) {
      case QuestionType.location:
        // Extract sentences with location keywords
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('located') ||
              lower.contains('situated') ||
              lower.contains('state') ||
              lower.contains('city') ||
              lower.contains('district') ||
              lower.contains('near') ||
              lower.contains('area') ||
              lower.contains('region');
        }).take(2).toList();
        break;

      case QuestionType.history:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('built') ||
              lower.contains('constructed') ||
              lower.contains('established') ||
              lower.contains('founded') ||
              lower.contains('century') ||
              lower.contains('dynasty') ||
              lower.contains('emperor') ||
              lower.contains('king') ||
              RegExp(r'\b\d{4}\b').hasMatch(s); // Years
        }).take(3).toList();
        break;

      case QuestionType.festivals:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('festival') ||
              lower.contains('celebration') ||
              lower.contains('ceremony') ||
              lower.contains('event') ||
              lower.contains('ritual') ||
              lower.contains('fair');
        }).take(2).toList();
        break;

      case QuestionType.activities:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('boating') ||
              lower.contains('swimming') ||
              lower.contains('trek') ||
              lower.contains('visit') ||
              lower.contains('enjoy') ||
              lower.contains('experience') ||
              lower.contains('activity') ||
              lower.contains('sports');
        }).take(2).toList();
        break;

      case QuestionType.visitingInfo:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('timing') ||
              lower.contains('hours') ||
              lower.contains('open') ||
              lower.contains('close') ||
              lower.contains('entry') ||
              lower.contains('ticket') ||
              lower.contains('fee');
        }).take(2).toList();
        break;

      case QuestionType.significance:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('famous') ||
              lower.contains('known') ||
              lower.contains('important') ||
              lower.contains('significant') ||
              lower.contains('popular') ||
              lower.contains('special');
        }).take(2).toList();
        break;

      case QuestionType.facilities:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('food') ||
              lower.contains('restaurant') ||
              lower.contains('hotel') ||
              lower.contains('parking') ||
              lower.contains('facilities') ||
              lower.contains('amenities') ||
              lower.contains('vendor') ||
              lower.contains('shop');
        }).take(2).toList();
        break;

      case QuestionType.architecture:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('architecture') ||
              lower.contains('design') ||
              lower.contains('structure') ||
              lower.contains('style') ||
              lower.contains('built') ||
              lower.contains('carving') ||
              lower.contains('dome') ||
              lower.contains('tower');
        }).take(3).toList();
        break;

      case QuestionType.crowdInfo:
        relevantSentences = sentences.where((s) {
          final lower = s.toLowerCase();
          return lower.contains('crowd') ||
              lower.contains('busy') ||
              lower.contains('tourist') ||
              lower.contains('visitor') ||
              lower.contains('people') ||
              lower.contains('popular');
        }).take(2).toList();
        break;

      case QuestionType.general:
        // For general questions, take first 2-3 sentences
        relevantSentences = sentences.take(2).toList();
        break;
    }

    if (relevantSentences.isEmpty) {
      return null; // No relevant context found
    }

    return relevantSentences.join('. ') + '.';
  }

  /// Build focused prompt with extracted context only
  String _buildFocusedPrompt(String question, String? context) {
    if (context == null || context.isEmpty) {
      // No relevant context - ask LLM to politely decline
      return '''Question about $_landmarkName: $question

You don't have specific information to answer this question.

Politely tell the user you're not sure about this particular detail, but you can help with other questions about $_landmarkName.

Answer:''';
    }

    // Focused context available - use it
    return '''Question about $_landmarkName: $question

Relevant information: $context

Answer the question using ONLY the relevant information above. Keep it to 1-2 sentences.

Answer:''';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Learn More'),
            Text(
              _landmarkName ?? widget.recognition.landmarkName.replaceAll('_', ' '),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Offline mode banner (only shown when offline)
          if (_currentLlmStatus == LlmStatus.gemmaOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connect to internet for better responses and performance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat messages area
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Message input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Chat bubble widget
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
