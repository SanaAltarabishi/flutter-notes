sealed class TranscriptEvent {
  const TranscriptEvent(this.text);
  final String text;
}

/// نص مؤقت ممكن يتغير (Deepgram interim).
class PartialTranscript extends TranscriptEvent {
  const PartialTranscript(super.text);
}

/// نص نهائي ثابت.
class FinalTranscript extends TranscriptEvent {
  const FinalTranscript(super.text);
}
