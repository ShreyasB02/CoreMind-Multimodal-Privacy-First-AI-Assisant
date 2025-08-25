import '../../core/ai/gemma_engine.dart';
import '../../core/database/memory_database.dart';
import 'package:flutter/foundation.dart';

class AIResponseService {
  final GemmaEngine _gemmaEngine;
  final MemoryDatabase _memoryDb;

  AIResponseService(this._gemmaEngine, this._memoryDb);

  Future<String> processUserInput(String input) async {
    try {
      // Get recent context from memory
      List<Map<String, dynamic>> recentMemories = await _memoryDb
          .getRecentMemories(limit: 3);
      String context = _buildContext(recentMemories);

      // Create prompt with context
      String prompt = _buildPrompt(input, context);

      // Generate response using Gemma
      String response = await _gemmaEngine.generateResponse(
          prompt, maxTokens: 50);

      // Store conversation using correct method
      String sessionId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      await _memoryDb.insertConversation(
        sessionId: sessionId,
        role: 'user',
        content: input,
      );
      await _memoryDb.insertConversation(
        sessionId: sessionId,
        role: 'assistant',
        content: response,
      );

      return _cleanupResponse(response);
    } catch (e) {
      debugPrint('AI response error: $e');
      return 'I\'m processing your request. Please give me a moment...';
    }
  }

  String _buildContext(List<Map<String, dynamic>> memories) {
    if (memories.isEmpty) return '';

    return 'Previous context: ${memories.map((m) => m['content'].toString()).take(2).join('. ')}';
  }

  String _buildPrompt(String input, String context) {
    return '''<bos><start_of_turn>user
${context.isNotEmpty ? '$context\n\n' : ''}$input<end_of_turn>
<start_of_turn>model
''';
  }

  String _cleanupResponse(String response) {
    // Clean up Gemma-specific tokens
    response = response.trim()
        .replaceAll('<end_of_turn>', '')
        .replaceAll('<bos>', '')
        .replaceAll('<start_of_turn>', '')
        .trim();

    // Ensure reasonable length
    if (response.length > 200) {
      response = '${response.substring(0, 200)}...';
    }

    return response.isEmpty ? 'I\'m here to help you!' : response;
  }
}