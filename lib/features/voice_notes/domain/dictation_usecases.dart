import 'package:freenotes_app/features/voice_notes/domain/streaming_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_event.dart';
import 'package:fpdart/fpdart.dart';

class StartDictation {
  const StartDictation(this._repo);
  final StreamingSttRepository _repo;
  Future<Either<Failure, Stream<TranscriptEvent>>> call(SttLanguage language) =>
      _repo.start(language);
}

class StopDictation {
  const StopDictation(this._repo);
  final StreamingSttRepository _repo;
  Future<void> call() => _repo.stop();
}

class CancelDictation {
  const CancelDictation(this._repo);
  final StreamingSttRepository _repo;
  Future<void> call() => _repo.cancel();
}
