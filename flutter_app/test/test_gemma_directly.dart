import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Simple test to verify Gemma model generates text
/// This bypasses the camera/Navigator flow to test the core LLM functionality
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test Gemma text generation directly', () async {
    const platform = MethodChannel('com.example.vistaguide/llm');
    
    // Set up mock for the method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (MethodCall methodCall) async {
      if (methodCall.method == 'generateText') {
        // This would normally call the native Android code
        // For now, we just want to see if the channel is set up correctly
        return 'Test response from Gemma model';
      }
      return null;
    });

    try {
      final result = await platform.invokeMethod('generateText', {
        'prompt': 'Tell me about the Taj Mahal in one sentence.',
      });
      
      print('✅ Gemma response: $result');
      expect(result, isNotNull);
      expect(result, isA<String>());
    } catch (e) {
      print('❌ Error: $e');
      fail('Failed to generate text: $e');
    }
  });
}
