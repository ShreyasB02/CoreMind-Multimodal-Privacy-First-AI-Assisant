import 'package:flutter/material.dart';
import '../features/voice/voice_service.dart';
import '../core/database/memory_database.dart';
import '../core/ai/gemma_engine.dart';
import '../features/agent/ai_response_service.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;
  final MemoryDatabase memoryDatabase;

  const HomeScreen({
    super.key,
    required this.voiceService,
    required this.memoryDatabase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _transcription = '';
  bool _isListening = false;

  // AI Integration
  late final GemmaEngine _gemmaEngine;
  late final AIResponseService _aiService;
  String _lastResponse = '';
  bool _isThinking = false;
  bool _isAIReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize AI engine
    _gemmaEngine = GemmaEngine();
    _aiService = AIResponseService(_gemmaEngine, widget.memoryDatabase);

    // Load AI model asynchronously
    _loadAIModel();

    // Voice service listeners
    widget.voiceService.transcriptionStream.listen((text) {
      setState(() => _transcription = text);

      // When speech is final and AI is ready, generate response
      if (!widget.voiceService.isListening && text.isNotEmpty && _isAIReady) {
        _generateAIResponse(text);
      }
    });

    widget.voiceService.listeningStream.listen((listening) {
      setState(() => _isListening = listening);
    });
  }

  Future<void> _loadAIModel() async {
    setState(() => _lastResponse = 'Loading AI model...');

    bool success = await _gemmaEngine.loadModel();

    setState(() {
      _isAIReady = success;
      _lastResponse = success
          ? 'AI ready! Tap microphone to start...'
          : 'AI model failed to load. Voice commands only.';
    });

    if (success) {
      debugPrint('🤖 Gemma AI ready for inference!');
    } else {
      debugPrint('❌ AI model failed to load');
    }
  }

  Future<void> _generateAIResponse(String userInput) async {
    if (!_isAIReady) return;

    setState(() {
      _isThinking = true;
      _lastResponse = 'Thinking...';
    });

    try {
      String response = await _aiService.processUserInput(userInput);

      setState(() {
        _lastResponse = response;
        _isThinking = false;
      });

      // Speak the response
      await widget.voiceService.speak(response);
    } catch (e) {
      setState(() {
        _lastResponse = 'Sorry, I encountered an error processing your request.';
        _isThinking = false;
      });
      debugPrint('AI Response error: $e');
    }
  }

  void _onMicPressed() {
    if (_isListening) {
      widget.voiceService.stopListening();
    } else {
      setState(() {
        _transcription = '';
        if (_isAIReady) {
          _lastResponse = 'Listening...';
        }
      });
      widget.voiceService.startListening();
    }
  }

  @override
  void dispose() {
    // Dispose AI engine first
    _gemmaEngine.dispose();

    // Then dispose other services
    widget.voiceService.dispose();
    widget.memoryDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('CoreMind'),
            const SizedBox(width: 8),
            Icon(
              _isAIReady ? Icons.psychology : Icons.psychology_outlined,
              color: _isAIReady ? Colors.green : Colors.grey,
              size: 20,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // Transcription area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isListening ? Colors.red : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 32,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You said:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcription.isEmpty
                          ? 'Tap microphone to speak...'
                          : _transcription,
                      style: TextStyle(
                        fontSize: 18,
                        color: _transcription.isEmpty
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // AI Response area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isThinking ? Colors.blue : Colors.blue.shade200,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 24,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CoreMind AI:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isThinking) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastResponse,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status and microphone button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAIReady ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAIReady ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: _isAIReady ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAIReady ? 'AI Ready' : 'AI Loading...',
                        style: TextStyle(
                          color: _isAIReady ? Colors.green.shade800 : Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Microphone button
                FloatingActionButton.extended(
                  onPressed: _onMicPressed,
                  backgroundColor: _isListening
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: Text(
                    _isListening ? 'Listening...' : 'Tap to Speak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
