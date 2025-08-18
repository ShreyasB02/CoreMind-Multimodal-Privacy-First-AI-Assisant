import 'package:flutter/material.dart';
import '../features/voice/voice_service.dart';
import '../core/database/memory_database.dart';
import 'dart:async';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _currentTranscription = '';
  String _lastResponse = 'Hi! I\'m CoreMind, your privacy-first AI assistant. Hold the mic button to start talking.';
  bool _isListening = false;

  StreamSubscription<String>? _transcriptionSubscription;
  StreamSubscription<bool>? _listeningSubscription;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _setupVoiceListeners();
  }

  void _setupVoiceListeners() {
    _transcriptionSubscription = widget.voiceService.transcriptionStream.listen(
          (transcription) {
        setState(() {
          _currentTranscription = transcription;
        });
      },
    );

    _listeningSubscription = widget.voiceService.listeningStream.listen(
          (isListening) {
        setState(() {
          _isListening = isListening;
        });

        if (isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
          _processTranscription();
        }
      },
    );
  }

  Future<void> _processTranscription() async {
    if (_currentTranscription.trim().isEmpty) return;

    try {
      // Store the user's input in memory
      await widget.memoryDatabase.insertMemory(
        content: _currentTranscription,
        contentType: 'voice_input',
        privacyLevel: 1, // Personal level
        sourceApp: 'coremind',
      );

      // Simple intent processing (we'll expand this)
      String response = await _generateResponse(_currentTranscription);

      setState(() {
        _lastResponse = response;
      });

      // Store the assistant's response
      await widget.memoryDatabase.insertMemory(
        content: response,
        contentType: 'assistant_response',
        privacyLevel: 0, // System level
        sourceApp: 'coremind',
      );

      // Speak the response
      await widget.voiceService.speak(response);

    } catch (e) {
      debugPrint('Error processing transcription: $e');
      setState(() {
        _lastResponse = 'Sorry, I encountered an error processing your request.';
      });
    }
  }

  Future<String> _generateResponse(String input) async {
    // Basic intent recognition (we'll replace this with TFLite later)
    String lowerInput = input.toLowerCase();

    if (lowerInput.contains('remember') || lowerInput.contains('save')) {
      return 'I\'ve saved that information for you. You can ask me to recall it anytime.';
    }

    if (lowerInput.contains('recall') || lowerInput.contains('what did i say')) {
      var memories = await widget.memoryDatabase.getRecentMemories(limit: 5);
      if (memories.isNotEmpty) {
        return 'Here are your recent memories: ${memories.map((m) => m['content']).take(3).join('. ')}';
      } else {
        return 'I don\'t have any memories to recall yet.';
      }
    }

    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      return 'Hello! I\'m CoreMind, running entirely on your device for maximum privacy. How can I help you today?';
    }

    if (lowerInput.contains('privacy') || lowerInput.contains('data')) {
      return 'All your data stays on your device. I process everything locally and never send information to external servers.';
    }

    if (lowerInput.contains('time')) {
      return 'The current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.';
    }

    // Default response
    return 'I heard you say: "$input". I\'m still learning, but I\'ve saved this for future reference.';
  }

  void _onMicPressed() async {
    if (_isListening) {
      await widget.voiceService.stopListening();
    } else {
      setState(() {
        _currentTranscription = '';
      });
      await widget.voiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'CoreMind',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Private',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Response Display
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant Response',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _lastResponse,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Current Transcription
              if (_currentTranscription.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listening...',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTranscription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Voice Button
              GestureDetector(
                onTap: _onMicPressed,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.red[400]!, Colors.red]
                                : [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.red : Colors.blue)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _isListening ? 'Listening... Tap to stop' : 'Tap to speak',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transcriptionSubscription?.cancel();
    _listeningSubscription?.cancel();
    super.dispose();
  }
}
