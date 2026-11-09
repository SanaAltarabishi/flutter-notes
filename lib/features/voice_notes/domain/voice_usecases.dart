import 'package:freenotes_app/features/voice_notes/domain/audio_recorder_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:freenotes_app/features/voice_notes/domain/transcription_repository.dart';
import 'package:fpdart/fpdart.dart';

class StartRecording {
  const StartRecording(this._repo);
  final AudioRecorderRepository _repo;
  Future<Either<Failure, Unit>> call() => _repo.start();
}

class StopRecording {
  const StopRecording(this._repo);
  final AudioRecorderRepository _repo;
  Future<Either<Failure, String>> call() => _repo.stop();
}

class CancelRecording {
  const CancelRecording(this._repo);
  final AudioRecorderRepository _repo;
  Future<void> call() => _repo.cancel();
}

class TranscribeAudio {
  const TranscribeAudio(this._repo);
  final TranscriptionRepository _repo;
  Future<Either<Failure, String>> call(
          String audioPath, SttLanguage language) =>
      _repo.transcribe(audioPath: audioPath, language: language);
}
