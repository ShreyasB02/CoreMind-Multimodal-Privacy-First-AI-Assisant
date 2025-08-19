import '../../core/ai/tflite_engine.dart';
import '../../core/ai/tokenizer.dart';
import '../../core/database/memory_database.dart';
import 'package:flutter/foundation.dart';

class ResponseGenerator {
  final TFLiteEngine _aiEngine;
  final MemoryDatabase _memoryDb;

  ResponseGenerator(this._aiEngine, this._memoryDb);

  Future<String> generateResponse(String userInput) async {
    try {
      // Step 1: Classify intent using AI
      String intent = await _aiEngine.classifyIntent(userInput);
      debugPrint('Classified intent: $intent');

      // Step 2: Generate response based on intent
      switch (intent) {
        case 'memory_store':
          return await _handleMemoryStore(userInput);
        case 'memory_recall':
          return await _handleMemoryRecall(userInput);
        case 'time_query':
          return _handleTimeQuery();
        case 'greeting':
          return _handleGreeting();
        case 'app_control':
          return await _handleAppControl(userInput);
        default:
          return await _handleGeneralQuery(userInput);
      }
    } catch (e) {
      debugPrint('Response generation error: $e');
      return 'I encountered an error processing your request. Could you try again?';
    }
  }

  Future<String> _handleMemoryStore(String input) async {
    // Extract the content to remember
    String content = input.replaceAll(RegExp(r'(remember|save|note)\s*', caseSensitive: false), '').trim();

    if (content.isNotEmpty) {
      // Generate embedding if model is loaded
      List<double>? embedding;
      if (_aiEngine.isModelLoaded) {
        List<int> tokens = SimpleTokenizer.encode(content);
        embedding = await _aiEngine.generateEmbedding(tokens);
      }

      // Store in memory database
      await _memoryDb.insertMemory(
        content: content,
        contentType: 'user_note',
        embedding: embedding,
        privacyLevel: 1,
        sourceApp: 'coremind',
      );

      return 'I\'ve saved that to your personal memory: "$content"';
    } else {
      return 'What would you like me to remember?';
    }
  }

  Future<String> _handleMemoryRecall(String input) async {
    // Search memories
    var memories = await _memoryDb.getRecentMemories(limit: 5);

    if (memories.isEmpty) {
      return 'I don\'t have any memories stored yet. Try saying "Remember that I like coffee" to save something.';
    }

    // If user asked for something specific, try to match
    if (input.contains('about') || input.contains('when')) {
      String query = input.toLowerCase();
      var searchResults = await _memoryDb.searchMemories(
        query.replaceAll(RegExp(r'(recall|remember|what|when|about)\s*', caseSensitive: false), '').trim(),
        limit: 3,
      );

      if (searchResults.isNotEmpty) {
        String results = searchResults.map((m) => m['content']).join('. ');
        return 'Here\'s what I found: $results';
      }
    }

    // Return recent memories
    String recentMemories = memories.take(3).map((m) => m['content']).join('. ');
    return 'Your recent memories: $recentMemories';
  }

  String _handleTimeQuery() {
    DateTime now = DateTime.now();
    return 'The current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')} on ${_formatDate(now)}.';
  }

  String _handleGreeting() {
    List<String> greetings = [
      'Hello! I\'m CoreMind, your privacy-first AI assistant. How can I help you today?',
      'Hi there! Ready to help with whatever you need, all processed locally on your device.',
      'Hey! I\'m here to assist you while keeping all your data private and secure.',
    ];
    return greetings[DateTime.now().millisecond % greetings.length];
  }

  Future<String> _handleAppControl(String input) async {
    // Log app control intent
    await _memoryDb.logAppInteraction(
      targetApp: 'system',
      actionType: 'voice_command',
      parameters: {'command': input},
    );

    return 'App control features are coming soon! For now, I can help you remember things and answer basic questions.';
  }

  Future<String> _handleGeneralQuery(String input) async {
    // Check if we have relevant memories
    var relatedMemories = await _memoryDb.searchMemories(input, limit: 2);

    String response = 'You said: "$input". ';

    if (relatedMemories.isNotEmpty) {
      response += 'I found some related memories: ${relatedMemories.map((m) => m['content']).join(', ')}. ';
    }

    response += 'I\'m still learning, but I\'ve saved this for future reference.';

    return response;
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
