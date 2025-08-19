import 'package:flutter/material.dart';
import '../features/voice/voice_service.dart';
import '../core/database/memory_database.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;
  final MemoryDatabase memoryDatabase;

  const HomeScreen({
    Key? key,
    required this.voiceService,
    required this.memoryDatabase,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _transcription = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    // Use the passed voice service instead of creating a new one
    widget.voiceService.transcriptionStream.listen((text) {
      setState(() => _transcription = text);
    });

    widget.voiceService.listeningStream.listen((listening) {
      setState(() => _isListening = listening);
    });
  }

  void _onMicPressed() {
    if (_isListening) {
      widget.voiceService.stopListening();
    } else {
      setState(() => _transcription = '');
      widget.voiceService.startListening();
    }
  }

  @override
  void dispose() {
    // Dispose services when HomeScreen is destroyed
    widget.voiceService.dispose();
    widget.memoryDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreMind'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _transcription.isEmpty
                      ? 'Tap the microphone to start speaking...'
                      : _transcription,
                  style: TextStyle(
                    fontSize: 24,
                    color: _transcription.isEmpty
                        ? Colors.grey[600]
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FloatingActionButton(
              onPressed: _onMicPressed,
              backgroundColor: _isListening
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
