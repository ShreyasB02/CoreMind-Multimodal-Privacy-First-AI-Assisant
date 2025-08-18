import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;

  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Enable debug logging to see what's failing
      bool available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true,
      );

      if (!available) {
        debugPrint('Speech recognition not available on this device');
        return false;
      }

      await _configureTTS();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  Future<void> _configureTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Skip engine selection for now - use default TTS engine
      // This avoids the type mismatch error
      debugPrint('TTS configured with default engine');
    } catch (e) {
      debugPrint('TTS configuration error: $e');
    }
  }

  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: listenFor ?? const Duration(minutes: 2),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      _listeningController.add(true);
    } catch (e) {
      debugPrint('Start listening error: $e');
      _onListeningStopped();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _onListeningStopped();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _transcriptionController.add(result.recognizedWords);

    if (result.finalResult) {
      debugPrint('Final transcription: ${result.recognizedWords}');
      _onListeningStopped();
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _onListeningStopped();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    _onListeningStopped();
  }

  void _onListeningStopped() {
    _isListening = false;
    _listeningController.add(false);
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _transcriptionController.close();
    _listeningController.close();
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
