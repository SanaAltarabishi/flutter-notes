import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class TranscriptionRepository {
  Future<Either<Failure, String>> transcribe({
    required String audioPath,
    required SttLanguage language,
  });
}
