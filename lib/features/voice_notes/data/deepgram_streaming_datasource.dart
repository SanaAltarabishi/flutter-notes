import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

import '../domain/stt_language.dart';

class DeepgramStreamingDataSource {
  DeepgramStreamingDataSource(this._recorder, {required String apiKey})
      : _apiKey = apiKey;

  final AudioRecorder _recorder;
  final String _apiKey;

  IOWebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _mic;

  static String languageCode(SttLanguage l) => switch (l) {
        SttLanguage.arabic => 'ar-SY',
        SttLanguage.english => 'en',
        // ما تأكدت إنو العربي مدعوم بـ multi — جرّبيه، وإذا رفض بيطلع خطأ اتصال.
        SttLanguage.auto => 'multi',
      };

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<Stream<Map<String, dynamic>>> start(SttLanguage language) async {
    final uri = Uri.parse('wss://api.deepgram.com/v1/listen').replace(
      queryParameters: {
        'model': 'nova-3',
        'language': languageCode(language),
        'encoding': 'linear16',
        'sample_rate': '16000',
        'channels': '1',
        'interim_results': 'true',
        'smart_format': 'true',
        'punctuate': 'true',
        'endpointing': '300',
      },
    );

    final channel = IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': 'Token $_apiKey'},
    );
    await channel.ready; // بيرمي استثناء إذا فشل الاتصال/المفتاح
    _channel = channel;

    try {
      final audio = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      _mic = audio.listen((chunk) => channel.sink.add(chunk));
    } catch (_) {
      await channel.sink.close();
      _channel = null;
      rethrow;
    }

    return channel.stream.map(
      (m) => m is String
          ? jsonDecode(m) as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  Future<void> stop() async {
    final channel = _channel;
    try {
      await _recorder.stop();
    } catch (_) {}
    await _mic?.cancel();
    _mic = null;
    if (channel == null) return;

    channel.sink.add(jsonEncode({'type': 'CloseStream'}));
    try {
      // السيرفر بيسكّر الاتصال بعد ما يبعت آخر النتائج
      await channel.sink.done.timeout(const Duration(seconds: 4));
    } catch (_) {}
    await channel.sink.close();
    _channel = null;
  }

  Future<void> cancel() async {
    try {
      await _recorder.cancel();
    } catch (_) {}
    await _mic?.cancel();
    _mic = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
