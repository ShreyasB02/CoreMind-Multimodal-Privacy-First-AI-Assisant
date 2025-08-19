import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

class TFLiteEngine {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // For text processing, we'll use a simple embedding model first
  static const String _modelPath = 'models/text_embedding.tflite';
  static const int _embeddingDimension = 384; // Common for small models

  bool get isModelLoaded => _isModelLoaded;

  Future<bool> loadModel() async {
    try {
      // Load the TFLite model from assets
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Get model input/output info
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('Model loaded successfully');
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');

      _isModelLoaded = true;
      return true;
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  // Generate embeddings for text (semantic similarity)
  Future<List<double>?> generateEmbedding(List<int> tokenIds) async {
    if (!_isModelLoaded || _interpreter == null) {
      debugPrint('Model not loaded');
      return null;
    }

    try {
      // Prepare input tensor
      var input = [tokenIds];

      // Prepare output tensor
      var output = List.filled(_embeddingDimension, 0.0)
          .reshape([1, _embeddingDimension]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract embedding vector
      List<double> embedding = (output[0] as List).cast<double>();

      return embedding;
    } catch (e) {
      debugPrint('Embedding generation error: $e');
      return null;
    }
  }

  // Simple intent classification (for now)
  Future<String> classifyIntent(String text) async {
    // For now, use simple rule-based classification
    // Later we'll replace this with actual model inference

    String lowerText = text.toLowerCase();

    if (lowerText.contains('remember') || lowerText.contains('save') || lowerText.contains('note')) {
      return 'memory_store';
    }

    if (lowerText.contains('recall') || lowerText.contains('what did') || lowerText.contains('remember when')) {
      return 'memory_recall';
    }

    if (lowerText.contains('time') || lowerText.contains('date')) {
      return 'time_query';
    }

    if (lowerText.contains('weather')) {
      return 'weather_query';
    }

    if (lowerText.contains('open') || lowerText.contains('launch')) {
      return 'app_control';
    }

    if (lowerText.contains('hello') || lowerText.contains('hi') || lowerText.contains('hey')) {
      return 'greeting';
    }

    return 'general_query';
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
