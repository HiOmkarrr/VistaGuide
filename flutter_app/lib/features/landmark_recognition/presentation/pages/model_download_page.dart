import 'package:flutter/material.dart';
import '../../data/services/llm_service.dart';

/// Page for downloading the Gemma LLM model
class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({super.key});

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  bool _downloadComplete = false;
  bool _downloadFailed = false;
  String? _errorMessage;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadFailed = false;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    final llmService = LlmService();
    final success = await llmService.downloadModel(
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
    );

    setState(() {
      _isDownloading = false;
      _downloadComplete = success;
      _downloadFailed = !success;
      if (!success) {
        _errorMessage = 'Download failed. Please check your internet connection.';
      }
    });

    if (success) {
      // Initialize the model after download
      await llmService.initializeModel();
      
      if (mounted) {
        // Navigate back with success
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download AI Model'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Icon(
              _downloadComplete
                  ? Icons.check_circle
                  : _downloadFailed
                      ? Icons.error
                      : Icons.cloud_download,
              size: 100,
              color: _downloadComplete
                  ? Colors.green
                  : _downloadFailed
                      ? Colors.red
                      : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              _downloadComplete
                  ? 'Download Complete!'
                  : _downloadFailed
                      ? 'Download Failed'
                      : 'AI Model Required',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              _downloadComplete
                  ? 'The AI model has been downloaded successfully. You can now use intelligent chatbot responses!'
                  : _downloadFailed
                      ? _errorMessage ?? 'An error occurred during download.'
                      : 'To enable intelligent AI-powered responses, we need to download the Gemma language model (524 MB).\n\nThis is a one-time download. The model will be stored on your device for offline use.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress indicator
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}% (${(_downloadProgress * 524).toStringAsFixed(1)} MB / 524 MB)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a few minutes...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // Download button
            if (!_isDownloading && !_downloadComplete)
              ElevatedButton.icon(
                onPressed: _downloadFailed ? _startDownload : _startDownload,
                icon: Icon(_downloadFailed ? Icons.refresh : Icons.download),
                label: Text(_downloadFailed ? 'Retry Download' : 'Download Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

            // Skip button
            if (!_isDownloading && !_downloadComplete)
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Skip (Use Smart Extraction)'),
              ),

            // Close button
            if (_downloadComplete)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

            // Info card
            if (!_isDownloading && !_downloadComplete)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Why download?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Works completely offline\n'
                      '• Natural AI-powered conversations\n'
                      '• Better understanding of your questions\n'
                      '• No internet required after download',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
