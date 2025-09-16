/// Test Gemini Integration for VistaGuide
///
/// This file demonstrates how the Gemini AI integration enhances destination information
/// Run this test to see how AI enriches place data with historical and educational content

import 'package:flutter/material.dart';
import '../../../../core/services/gemini_enrichment_service.dart';
import '../../data/models/destination.dart';

class GeminiTestPage extends StatefulWidget {
  const GeminiTestPage({super.key});

  @override
  State<GeminiTestPage> createState() => _GeminiTestPageState();
}

class _GeminiTestPageState extends State<GeminiTestPage> {
  final GeminiEnrichmentService _geminiService = GeminiEnrichmentService();
  final TextEditingController _placeController = TextEditingController();

  Map<String, dynamic>? _enrichedData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _placeController.text = "Red Fort, Delhi"; // Default test place
  }

  Future<void> _testGeminiEnrichment() async {
    final placeName = _placeController.text.trim();
    if (placeName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _enrichedData = null;
    });

    try {
      print('🤖 Testing Gemini enrichment for: $placeName');

      final enrichedData =
          await _geminiService.enrichPlaceInformation(placeName);

      setState(() {
        _enrichedData = enrichedData;
        _isLoading = false;
      });

      print('✅ Gemini enrichment successful!');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Gemini enrichment failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Gemini AI Enhancement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a place name to see how Gemini AI enriches it with historical and educational information:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _placeController,
                      decoration: const InputDecoration(
                        labelText: 'Place Name',
                        hintText: 'e.g., Red Fort, Delhi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGeminiEnrichment,
                      child: _isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Enhancing with AI...'),
                              ],
                            )
                          : const Text('✨ Enhance with Gemini AI'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(_error!),
                    ],
                  ),
                ),
              ),
            if (_enrichedData != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✨ AI-Enhanced Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEnrichedSection(
                              'Description', _enrichedData!['description']),
                          _buildEnrichedSection(
                              'Image URL', _enrichedData!['imageUrl']),
                          _buildHistoricalSection(
                              _enrichedData!['historicalInfo']),
                          _buildEducationalSection(
                              _enrichedData!['educationalInfo']),
                          _buildTagsSection(_enrichedData!['tags']),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrichedSection(String title, dynamic content) {
    if (content == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content.toString()),
        ],
      ),
    );
  }

  Widget _buildHistoricalSection(Map<String, dynamic>? historicalInfo) {
    if (historicalInfo == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          if (historicalInfo['briefDescription'] != null)
            Text('Brief: ${historicalInfo['briefDescription']}'),
          if (historicalInfo['extendedDescription'] != null)
            Text('Extended: ${historicalInfo['extendedDescription']}'),
          if (historicalInfo['keyEvents'] != null)
            Text('Events: ${(historicalInfo['keyEvents'] as List).join(', ')}'),
        ],
      ),
    );
  }

  Widget _buildEducationalSection(Map<String, dynamic>? educationalInfo) {
    if (educationalInfo == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Educational Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          if (educationalInfo['facts'] != null)
            Text('Facts: ${(educationalInfo['facts'] as List).join(', ')}'),
          if (educationalInfo['importance'] != null)
            Text('Importance: ${educationalInfo['importance']}'),
          if (educationalInfo['culturalRelevance'] != null)
            Text('Cultural: ${educationalInfo['culturalRelevance']}'),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List<dynamic>? tags) {
    if (tags == null || tags.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI-Generated Tags',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: tags
                .map((tag) => Chip(
                      label: Text(tag.toString()),
                      backgroundColor: Colors.orange.shade100,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }
}
