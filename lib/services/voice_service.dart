import 'dart:async';

class VoiceRecognitionEvent {
  const VoiceRecognitionEvent({
    required this.rawText,
    required this.intent,
  });

  final String rawText;
  final String intent;
}

class VoiceAnnouncementEvent {
  const VoiceAnnouncementEvent({
    required this.text,
    required this.style,
  });

  final String text;
  final VoiceAnnouncementStyle style;
}

enum VoiceAnnouncementStyle { coach, warning, guidance }

class VoiceService {
  final StreamController<VoiceRecognitionEvent> _recognitionController =
      StreamController<VoiceRecognitionEvent>.broadcast();
  final StreamController<VoiceAnnouncementEvent> _announcementController =
      StreamController<VoiceAnnouncementEvent>.broadcast();

  Stream<VoiceRecognitionEvent> get recognitionStream =>
      _recognitionController.stream;
  Stream<VoiceAnnouncementEvent> get announcementStream =>
      _announcementController.stream;

  Future<void> speak(
    String text, {
    VoiceAnnouncementStyle style = VoiceAnnouncementStyle.coach,
  }) async {
    _announcementController.add(
      VoiceAnnouncementEvent(text: text, style: style),
    );
  }

  void dispatchMockRecognition(String rawText) {
    _recognitionController.add(
      VoiceRecognitionEvent(
        rawText: rawText,
        intent: parseIntentFromText(rawText),
      ),
    );
  }

  String parseIntentFromText(String rawText) {
    final String normalized =
        rawText.replaceAll(' ', '').replaceAll('，', '').trim();
    if (normalized.contains('咋个吃') ||
        normalized.contains('怎么吃') ||
        normalized.contains('如何吃')) {
      return 'intent.highlight_usage';
    }
    if (normalized.contains('录入新药') || normalized.contains('认药')) {
      return 'intent.scan_new_medication';
    }
    if (normalized.contains('有冲突') || normalized.contains('能不能一起吃')) {
      return 'intent.review_conflict';
    }
    return 'intent.unknown';
  }

  void dispose() {
    _recognitionController.close();
    _announcementController.close();
  }
}
