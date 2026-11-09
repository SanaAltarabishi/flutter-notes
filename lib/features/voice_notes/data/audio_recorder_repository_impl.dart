import 'package:freenotes_app/features/voice_notes/data/audio_recorder_datasource.dart';
import 'package:freenotes_app/features/voice_notes/domain/audio_recorder_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:fpdart/fpdart.dart';

class AudioRecorderRepositoryImpl implements AudioRecorderRepository {
  AudioRecorderRepositoryImpl(this._ds);
  final AudioRecorderDataSource _ds;

  @override
  Future<Either<Failure, Unit>> start() async {
    try {
      if (!await _ds.hasPermission()) return left(const PermissionFailure());
      await _ds.start();
      return right(unit);
    } catch (_) {
      return left(const RecordingFailure());
    }
  }

  @override
  Future<Either<Failure, String>> stop() async {
    try {
      final path = await _ds.stop();
      if (path == null) return left(const RecordingFailure('ما انحفظ التسجيل'));
      return right(path);
    } catch (_) {
      return left(const RecordingFailure());
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _ds.cancel();
    } catch (_) {}
  }
}
