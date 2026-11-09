import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_event.dart';
import 'package:fpdart/fpdart.dart';

import 'failure.dart';

/// عقد موحّد لأي مزوّد:
///  - مزوّد مباشر (Deepgram): بيطلّع Partial/Final وإنتي عم تحكي.
///  - مزوّد batch (Groq): بيطلّع Final واحد بعد stop().
/// الـ Stream بيسكّر (done) لما يخلص كل شي بعد stop() أو cancel().
/// الأخطاء بتجي عبر Stream.addError(Failure).
abstract interface class StreamingSttRepository {
  Future<Either<Failure, Stream<TranscriptEvent>>> start(SttLanguage language);

  /// يوقف التسجيل وينتظر آخر النتائج.
  Future<void> stop();

  /// يلغي فوراً بدون انتظار.
  Future<void> cancel();

  //Future<Either<Failure, Unit>> checkAvailability();
}
