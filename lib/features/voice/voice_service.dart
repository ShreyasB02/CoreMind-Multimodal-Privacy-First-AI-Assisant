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
  bool _isDisposed = false;

  StreamController<String>? _transcriptionController;
  StreamController<bool>? _listeningController;

  Stream<String> get transcriptionStream => _transcriptionController?.stream ?? const Stream.empty();
  Stream<bool> get listeningStream => _listeningController?.stream ?? const Stream.empty();

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  VoiceService() {
    _initControllers();
  }

  void _initControllers() {
    if (_isDisposed) return;

    _transcriptionController?.close();
    _listeningController?.close();

    _transcriptionController = StreamController<String>.broadcast();
    _listeningController = StreamController<bool>.broadcast();
  }

  Future<bool> initialize() async {
    if (_isInitialized || _isDisposed) return _isInitialized;

    try {
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
      debugPrint('Voice service initialized successfully');
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
      debugPrint('TTS configured successfully');
    } catch (e) {
      debugPrint('TTS configuration error: $e');
    }
  }

  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized || _isListening || _isDisposed) {
      debugPrint('Cannot start listening: initialized=$_isInitialized, listening=$_isListening, disposed=$_isDisposed');
      return;
    }

    try {
      debugPrint('Starting to listen...');
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      _addToListeningStream(true);
      debugPrint('Started listening successfully');
    } catch (e) {
      debugPrint('Start listening error: $e');
      _onListeningStopped();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening || _isDisposed) return;

    try {
      await _speechToText.stop();
      debugPrint('Stop listening called');
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }

    _onListeningStopped();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (_isDisposed) return;

    debugPrint('Speech result: ${result.recognizedWords} (final: ${result.finalResult})');
    _addToTranscriptionStream(result.recognizedWords);

    if (result.finalResult) {
      debugPrint('Final transcription: ${result.recognizedWords}');
      _onListeningStopped();
    }
  }

  void _onSpeechStatus(String status) {
    if (_isDisposed) return;

    debugPrint('Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _onListeningStopped();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (_isDisposed) return;

    debugPrint('Speech error: ${error.errorMsg}');
    _onListeningStopped();
  }

  void _onListeningStopped() {
    if (_isDisposed) return;

    _isListening = false;
    _addToListeningStream(false);
    debugPrint('Listening stopped');
  }

  void _addToTranscriptionStream(String text) {
    if (!_isDisposed && _transcriptionController != null && !_transcriptionController!.isClosed) {
      _transcriptionController!.add(text);
    }
  }

  void _addToListeningStream(bool isListening) {
    if (!_isDisposed && _listeningController != null && !_listeningController!.isClosed) {
      _listeningController!.add(isListening);
    }
  }

  Future<void> speak(String text) async {
    if (_isDisposed) return;

    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    try {
      debugPrint('Speaking: $text');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    if (_isDisposed) return;

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Stop speaking error: $e');
    }
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isListening = false;

    debugPrint('Disposing voice service...');

    try {
      _speechToText.cancel();
      _flutterTts.stop();
    } catch (e) {
      debugPrint('Error during service disposal: $e');
    }

    _transcriptionController?.close();
    _listeningController?.close();

    _transcriptionController = null;
    _listeningController = null;

    debugPrint('Voice service disposed');
  }
}
