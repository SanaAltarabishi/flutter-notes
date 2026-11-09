import 'dart:io';

import 'package:freenotes_app/features/voice_notes/data/deepgram_streaming_datasource.dart';
import 'package:freenotes_app/features/voice_notes/domain/streaming_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_event.dart';
import 'package:fpdart/fpdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/stt_language.dart';
import '../domain/failure.dart';

class DeepgramSttRepository implements StreamingSttRepository {
  DeepgramSttRepository(this._ds);
  final DeepgramStreamingDataSource _ds;

  @override
  Future<Either<Failure, Stream<TranscriptEvent>>> start(
    SttLanguage language,
  ) async {
    try {
      if (!await _ds.hasPermission()) return left(const PermissionFailure());
      final raw = await _ds.start(language);
      return right(raw.expand(_toEvents));
    } on SocketException {
      return left(const NetworkFailure());
    } on WebSocketChannelException {
      return left(
        const TranscriptionFailure(
          'تعذّر الاتصال بـ Deepgram — تحقّقي من المفتاح والإنترنت واللغة',
        ),
      );
    } catch (_) {
      return left(const RecordingFailure());
    }
  }

  static Iterable<TranscriptEvent> _toEvents(Map<String, dynamic> m) {
    if (m['type'] != 'Results') return const [];
    final alts = (m['channel'] as Map?)?['alternatives'] as List?;
    if (alts == null || alts.isEmpty) return const [];
    final text = (alts.first as Map)['transcript']?.toString().trim() ?? '';
    if (text.isEmpty) return const [];
    return [
      m['is_final'] == true ? FinalTranscript(text) : PartialTranscript(text),
    ];
  }

  @override
  Future<void> stop() => _ds.stop();

  @override
  Future<void> cancel() => _ds.cancel();

  // deepgram_stt_repository.dart
  // @override
  // Future<Either<Failure, Unit>> checkAvailability() async => right(unit);
}
