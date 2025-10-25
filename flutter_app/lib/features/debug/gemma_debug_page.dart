import 'package:flutter/material.dart';
import '../landmark_recognition/data/services/llm_service.dart';

/// Debug page to test Gemma LLM generation directly
/// Bypasses camera/recognition flow to verify model works
class GemmaDebugPage extends StatefulWidget {
  const GemmaDebugPage({super.key});

  @override
  State<GemmaDebugPage> createState() => _GemmaDebugPageState();
}

class _GemmaDebugPageState extends State<GemmaDebugPage> {
  final LlmService _llmService = LlmService();
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  bool _modelInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _promptController.text = 'Tell me about the Taj Mahal in 2-3 sentences.';
  }

  Future<void> _initializeModel() async {
    setState(() => _isLoading = true);
    try {
      final initialized = await _llmService.initializeModel();
      setState(() {
        _modelInitialized = initialized;
        _isLoading = false;
      });
      if (initialized) {
        _showSnackBar('✅ Model loaded successfully', Colors.green);
      } else {
        _showSnackBar('❌ Failed to load model', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _generateText() async {
    if (!_modelInitialized) {
      _showSnackBar('Model not initialized', Colors.orange);
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showSnackBar('Please enter a prompt', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response = await _llmService.generateText(prompt: prompt);
      setState(() {
        _response = response ?? 'No response generated';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
      _showSnackBar('❌ Generation failed: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma LLM Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _modelInitialized ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _modelInitialized ? Icons.check_circle : Icons.warning,
                      color: _modelInitialized ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _modelInitialized
                            ? 'Model Ready (gemma-3-270m-it-int8.task)'
                            : 'Initializing model...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Prompt Input
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt',
                border: OutlineInputBorder(),
                hintText: 'Ask about a landmark...',
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            ElevatedButton.icon(
              onPressed: _isLoading || !_modelInitialized ? null : _generateText,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Generating...' : 'Generate Response'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Response
            const Text(
              'Response:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response.isEmpty ? 'Response will appear here...' : _response,
                    style: TextStyle(
                      fontSize: 14,
                      color: _response.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Test Buttons
            const Text(
              'Quick Tests:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickTestButton('Taj Mahal', 'Tell me about the Taj Mahal.'),
                _buildQuickTestButton('India Gate', 'Describe India Gate Delhi.'),
                _buildQuickTestButton('Simple Test', 'What is 2+2?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(String label, String prompt) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _promptController.text = prompt;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
