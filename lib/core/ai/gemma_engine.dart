import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class GemmaEngine {
  static const platform = MethodChannel('com.coremind.ai/gemma');
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<bool> loadModel() async {
    try {
      debugPrint('Loading Gemma model via MediaPipe...');

      final bool success = await platform.invokeMethod('loadModel', {
        'modelPath': 'models/gemma3b_int4.litertlm'
      });

      _isLoaded = success;

      if (success) {
        debugPrint('✅ Gemma model loaded successfully via MediaPipe!');
      } else {
        debugPrint('❌ Failed to load Gemma model');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Model loading error: $e');
      return false;
    }
  }

  Future<String> generateResponse(String prompt, {int maxTokens = 100}) async {
    if (!_isLoaded) {
      throw Exception('Gemma model not loaded');
    }

    try {
      debugPrint('Generating response for: "$prompt"');

      final String response = await platform.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': maxTokens,
      });

      debugPrint('Generated: "$response"');
      return response;
    } catch (e) {
      debugPrint('Generation error: $e');
      return 'I encountered an error generating a response. Could you try again?';
    }
  }

  void dispose() {
    if (_isLoaded) {
      platform.invokeMethod('disposeModel');
      _isLoaded = false;
    }
  }
}
