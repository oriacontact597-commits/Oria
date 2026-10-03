import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _ttsInitialized = false;
  String _lastError = '';

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
  bool get isTtsAvailable => _ttsInitialized;
  String get lastError => _lastError;

  FlutterTts get tts => _tts;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('VoiceService status: $status');
        },
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('VoiceService error: $error');
        },
      );
      if (_isInitialized) {
        await _tts.setLanguage('fr-FR');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _ttsInitialized = true;
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('VoiceService init error: $e');
      _lastError = e.toString();
      _isInitialized = false;
      return false;
    }
  }

  Future<String> startListening({Duration timeout = const Duration(seconds: 20)}) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return '';
    }

    if (_isListening || _speech.isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!await _speech.hasPermission) {
      _lastError = 'Permission micro refusée. Autorise le micro dans les paramètres.';
      return '';
    }

    _isListening = true;
    String recognizedText = '';

    try {
      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _speech.stop();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'fr_FR',
          listenFor: timeout,
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
      );
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Listening error: $e');
    }

    _isListening = false;
    return recognizedText;
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
  }

  Future<void> speak(String text) async {
    try {
      if (!_ttsInitialized) {
        await _tts.setLanguage('fr-FR');
        await _tts.setSpeechRate(0.5);
        _ttsInitialized = true;
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
