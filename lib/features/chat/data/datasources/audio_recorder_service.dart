import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordedAudio {
  const RecordedAudio({required this.path, required this.durationMs});

  final String path;
  final int durationMs;
}

/// Wrapper sobre `record`: graba a un .m4a temporal en el caché de la app y
/// devuelve su path + duración al parar. Una sola grabación a la vez.
class AudioRecorderService {
  final _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _startedAt = DateTime.now();
  }

  /// `null` si no había grabación en curso (p. ej. se llamó dos veces).
  Future<RecordedAudio?> stop() async {
    final path = await _recorder.stop();
    final startedAt = _startedAt;
    _startedAt = null;
    if (path == null || startedAt == null) return null;
    return RecordedAudio(path: path, durationMs: DateTime.now().difference(startedAt).inMilliseconds);
  }

  Future<void> cancel() async {
    await _recorder.cancel();
    _startedAt = null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
