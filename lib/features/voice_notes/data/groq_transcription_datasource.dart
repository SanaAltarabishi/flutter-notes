import 'package:dio/dio.dart';

/// يتعامل مع واجهة Groq المتوافقة مع OpenAI.
/// الـ Dio لازم يكون baseUrl = https://api.groq.com/openai/v1
class GroqTranscriptionDataSource {
  GroqTranscriptionDataSource(this._dio, {required this.model});

  final Dio _dio;
  final String model;

  Future<String> transcribe(String audioPath, {String? language}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split('/').last,
      ),
      'model': model,
      if (language != null) 'language': language,
      'response_format': 'json',
      'temperature': '0',
    });

    final res = await _dio.post<Map<String, dynamic>>(
      '/audio/transcriptions',
      data: form,
    );
    return (res.data?['text'] as String? ?? '').trim();
  }
}
