import 'package:freenotes_app/features/voice_notes/data/deepgram_streaming_datasource.dart';
import 'package:freenotes_app/features/voice_notes/data/deepgram_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/data/file_recorder_datasource.dart';
import 'package:freenotes_app/features/voice_notes/data/groq_batch_datasource.dart';
import 'package:freenotes_app/features/voice_notes/data/groq_batch_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/dictation_usecases.dart';
import 'package:freenotes_app/features/voice_notes/domain/streaming_stt_repository.dart';
import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

// للتجربة فقط:
// flutter run --dart-define=DEEPGRAM_API_KEY=xxx --dart-define=GROQ_API_KEY=yyy
// للـ production: لا تحطي المفاتيح بالتطبيق — backend يعطي توكن قصير العمر
// (Deepgram) أو يمرّر الطلبات (Groq).
const _deepgramKey = String.fromEnvironment('DEEPGRAM_API_KEY');
const _groqKey = String.fromEnvironment('GROQ_API_KEY');
const _groqModel = 'whisper-large-v3';

// ---------- اختيار المحرّك (للمقارنة بالتطبيق) ----------
enum SttEngine {
  deepgram('Deepgram — نص مباشر'),
  groq('Groq — بعد الإيقاف');

  const SttEngine(this.label);
  final String label;
}

class SttEngineNotifier extends Notifier<SttEngine> {
  @override
  SttEngine build() => SttEngine.deepgram;
  void set(SttEngine engine) => state = engine;
}

final sttEngineProvider = NotifierProvider<SttEngineNotifier, SttEngine>(
  SttEngineNotifier.new,
);

// ---------- اللغة ----------
class SttLanguageNotifier extends Notifier<SttLanguage> {
  @override
  SttLanguage build() => SttLanguage.arabic;
  void set(SttLanguage language) => state = language;
}

final sttLanguageProvider = NotifierProvider<SttLanguageNotifier, SttLanguage>(
  SttLanguageNotifier.new,
);

// ---------- repository حسب المحرّك ----------
final sttRepositoryProvider = Provider<StreamingSttRepository>((ref) {
  switch (ref.watch(sttEngineProvider)) {
    case SttEngine.deepgram:
      final ds = DeepgramStreamingDataSource(
        AudioRecorder(),
        apiKey: _deepgramKey,
      );
      ref.onDispose(ds.dispose);
      return DeepgramSttRepository(ds);

    case SttEngine.groq:
      final recorder = FileRecorderDataSource(AudioRecorder());
      ref.onDispose(recorder.dispose);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.groq.com/openai/v1',
          headers: {'Authorization': 'Bearer $_groqKey'},
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      return GroqBatchSttRepository(
        recorder,
        GroqBatchDataSource(dio, model: _groqModel),
      );
  }
});

// ---------- use cases ----------
final startDictationProvider = Provider(
  (ref) => StartDictation(ref.watch(sttRepositoryProvider)),
);
final stopDictationProvider = Provider(
  (ref) => StopDictation(ref.watch(sttRepositoryProvider)),
);
final cancelDictationProvider = Provider(
  (ref) => CancelDictation(ref.watch(sttRepositoryProvider)),
);
// final checkAvailabilityProvider = Provider(
//   (ref) => CheckAvailability(ref.watch(sttRepositoryProvider)),
// );

// final engineAvailabilityProvider = FutureProvider<Either<Failure, Unit>>(
//   (ref) => ref.watch(checkAvailabilityProvider)(),
// );
