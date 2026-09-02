import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> init() => _speech.initialize();

  bool get isListening => _speech.isListening;

  Future<void> listen({
    required void Function(String text) onResult,
    void Function(String error)? onError,
  }) async {
    if (!await init()) {
      onError?.call('Speech recognition unavailable');
      return;
    }
    await _speech.listen(
      onResult: (r) {
        if (r.finalResult) onResult(r.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.dictation),
    );
  }

  Future<void> stop() => _speech.stop();
}
