import 'dart:async';
import 'dart:io';

import 'package:freenotes_app/features/voice_notes/data/file_recorder_datasource.dart';
import 'package:freenotes_app/features/voice_notes/data/groq_batch_datasource.dart';
import 'package:freenotes_app/features/voice_notes/domain/streaming_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_event.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Groq مو streaming: منسجّل لملف، وبعد stop() بنرفعه وبنطلّع FinalTranscript واحد.
/// هيك بيركب على نفس العقد الموحّد بدون ما تتغير الواجهة.
class GroqBatchSttRepository implements StreamingSttRepository {
  GroqBatchSttRepository(this._recorder, this._groq);

  final FileRecorderDataSource _recorder;
  final GroqBatchDataSource _groq;

  StreamController<TranscriptEvent>? _controller;
  SttLanguage _language = SttLanguage.arabic;

  @override
  Future<Either<Failure, Stream<TranscriptEvent>>> start(
    SttLanguage language,
  ) async {
    try {
      if (!await _recorder.hasPermission()) {
        return left(const PermissionFailure());
      }
      await _recorder.start();
      _language = language;
      _controller = StreamController<TranscriptEvent>();
      return right(_controller!.stream);
    } catch (_) {
      return left(const RecordingFailure());
    }
  }

  @override
  Future<void> stop() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;

    String? path;
    try {
      path = await _recorder.stop();
      if (path == null) {
        c.addError(const RecordingFailure('ما انحفظ التسجيل'));
      } else {
        final text = await _groq.transcribe(path, _language);
        if (text.isNotEmpty) c.add(FinalTranscript(text));
      }
    } on DioException catch (e) {
      c.addError(_map(e));
    } catch (_) {
      c.addError(const TranscriptionFailure());
    } finally {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      await c.close();
    }
  }

  @override
  Future<void> cancel() async {
    final c = _controller;
    _controller = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
    await c?.close();
  }

  Failure _map(DioException e) {
    final code = e.response?.statusCode;
    if (code == 429) return const RateLimitFailure();
    if (code == 401) return const TranscriptionFailure('مفتاح Groq غير صحيح');
    if (code == 413) {
      return const TranscriptionFailure('التسجيل كبير (الحد 25MB)');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }
    return const TranscriptionFailure();
  }

  // @override
  // Future<Either<Failure, Unit>> checkAvailability() async {
  //   try {
  //     await _groq.ping();
  //     return right(unit);
  //   } on DioException catch (e) {
  //     final code = e.response?.statusCode;
  //     if (code == 401)
  //       return left(const TranscriptionFailure('مفتاح Groq غير صحيح'));
  //     if (code == 403) return left(const RegionBlockedFailure());
  //     // فشل اتصال أو مهلة: إما ما في إنترنت أو الخدمة محجوبة
  //     return left(
  //       await _hasInternet()
  //           ? const ServiceUnreachableFailure()
  //           : const NetworkFailure(),
  //     );
  //   } catch (_) {
  //     return left(const ServiceUnreachableFailure());
  //   }
  // }

  // Future<bool> _hasInternet() async {
  //   try {
  //     await Dio()
  //         .get('https://www.gstatic.com/generate_204')
  //         .timeout(const Duration(seconds: 4));
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }
}
