import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:dio/dio.dart';

/// واجهة Groq المتوافقة مع OpenAI. baseUrl = https://api.groq.com/openai/v1
class GroqBatchDataSource {
  GroqBatchDataSource(this._dio, {required this.model});
  final Dio _dio;
  final String model;

  static String? languageCode(SttLanguage l) => switch (l) {
        SttLanguage.arabic => 'ar',
        SttLanguage.english => 'en',
        SttLanguage.auto => null, // الموديل بيكتشف اللغة
      };

  Future<String> transcribe(String audioPath, SttLanguage language) async {
    final code = languageCode(language);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split('/').last,
      ),
      'model': model,
      if (code != null) 'language': code,
      'response_format': 'json',
      'temperature': '0',
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/audio/transcriptions',
      data: form,
    );
    return (res.data?['text'] as String? ?? '').trim();
  }

  Future<void> ping() =>
      _dio.get('/models').timeout(const Duration(seconds: 6));
}
