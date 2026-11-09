import 'dart:ui';

const kTranscriptBoxWidth = 300.0;

enum BoxStatus { recording, finalizing, ready, error }

class TranscriptBox {
  const TranscriptBox({
    required this.id,
    required this.offset,
    required this.startedAt,
    this.status = BoxStatus.recording,
    this.text = '',
    this.interimText = '',
    this.isEditing = false,
    this.error,
  });

  final String id;
  final Offset offset;
  final DateTime startedAt;
  final BoxStatus status;

  /// النص النهائي (ثابت).
  final String text;

  /// النص المؤقت (رمادي، بيتغير وإنتي عم تحكي).
  final String interimText;
  final bool isEditing;
  final String? error;

  TranscriptBox copyWith({
    Offset? offset,
    BoxStatus? status,
    String? text,
    String? interimText,
    bool? isEditing,
    String? error,
  }) {
    return TranscriptBox(
      id: id,
      startedAt: startedAt,
      offset: offset ?? this.offset,
      status: status ?? this.status,
      text: text ?? this.text,
      interimText: interimText ?? this.interimText,
      isEditing: isEditing ?? this.isEditing,
      error: error ?? this.error,
    );
  }
}

class VoiceNotesState {
  const VoiceNotesState({
    this.boxes = const [],
    this.activeRecordingId,
    this.message,
  });

  final List<TranscriptBox> boxes;
  final String? activeRecordingId;

  /// رسالة مؤقتة للـ SnackBar.
  final String? message;

  bool get isRecording => activeRecordingId != null;
  bool get isFinalizing => boxes.any((b) => b.status == BoxStatus.finalizing);

  /// تسجيل أو إنهاء شغّال: ما منبدّل المحرّك ولا منبدأ تسجيل جديد.
  bool get isBusy => isRecording || isFinalizing;

  VoiceNotesState copyWith({
    List<TranscriptBox>? boxes,
    String? activeRecordingId,
    bool clearActive = false,
    String? message,
    bool clearMessage = false,
  }) {
    return VoiceNotesState(
      boxes: boxes ?? this.boxes,
      activeRecordingId:
          clearActive ? null : (activeRecordingId ?? this.activeRecordingId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
