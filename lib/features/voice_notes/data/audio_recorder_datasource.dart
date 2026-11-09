import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderDataSource {
  AudioRecorderDataSource(this._recorder);
  final AudioRecorder _recorder;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/stt_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // 16kHz mono AAC ~ 32kbps: صغير الحجم (حد Groq المجاني للرفع 25MB)
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 32000,
      ),
      path: path,
    );
  }

  Future<String?> stop() => _recorder.stop();
  Future<void> cancel() => _recorder.cancel();
  Future<void> dispose() => _recorder.dispose();
}
