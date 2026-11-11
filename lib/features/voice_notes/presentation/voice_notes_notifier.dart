import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:freenotes_app/features/voice_notes/domain/failure.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/utils/text_utils.dart';
import 'package:freenotes_app/features/notes/domain/entities/content_block.dart';
import 'package:freenotes_app/features/notes/domain/usecases/blocks/get_blocks.dart';
import 'package:freenotes_app/features/notes/domain/usecases/blocks/save_block.dart';
import 'package:freenotes_app/features/notes/presentation/providers/core_providers.dart';
import '../providers.dart';
import 'voice_notes_state.dart';

class VoiceNotesNotifier
    extends AutoDisposeFamilyNotifier<VoiceNotesState, String> {
  int _seq = 0;
  StreamSubscription<TranscriptEvent>? _sub;

  @override
  VoiceNotesState build(String pageId) {
    ref.onDispose(() => _sub?.cancel());
    return const VoiceNotesState();
  }

  // ---------------- dictation flow ----------------
  Future<void> toggleRecording() {
    if (state.isFinalizing) return Future.value(); // منستنى تخلص الجلسة السابقة
    return state.isRecording ? _stop() : _start();
  }

  Future<void> _start() async {
    final language = ref.read(sttLanguageProvider);
    final result = await ref.read(startDictationProvider)(language);

    result.fold<void>(
      (failure) => state = state.copyWith(message: failure.message),
      (stream) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();
        final box = TranscriptBox(
          id: id,
          startedAt: DateTime.now(),
          offset: Offset(24, 24.0 + 40 * (_seq++ % 6)),
        );
        state = state.copyWith(
          boxes: [...state.boxes, box],
          activeRecordingId: id,
        );
        _sub = stream.listen(
          (event) => _onEvent(id, event),
          onError: (Object e) =>
              _fail(id, e is Failure ? e.message : 'خطأ بالاتصال'),
          onDone: () => _onDone(id),
        );
      },
    );
  }

  Future<void> _stop() async {
    final id = state.activeRecordingId;
    if (id == null) return;
    _update(id, (b) => b.copyWith(status: BoxStatus.finalizing));
    state = state.copyWith(clearActive: true);
    // بعد ما يخلص stop() الـ stream بيسكّر → _onDone بيحوّل المربع لـ ready
    await ref.read(stopDictationProvider)();
  }

  void _onEvent(String id, TranscriptEvent event) {
    switch (event) {
      case FinalTranscript(:final text):
        _update(
          id,
          (b) => b.copyWith(text: _merge(b.text, text), interimText: ''),
        );
      case PartialTranscript(:final text):
        _update(id, (b) => b.copyWith(interimText: text));
    }
  }

  void _onDone(String id) {
    _sub = null;
    final box = _find(id);
    if (box == null) return;

    // الاتصال سكّر قبل ما المستخدم يوقف
    if (state.activeRecordingId == id) {
      state = state.copyWith(clearActive: true);
      unawaited(ref.read(cancelDictationProvider)());
    }
    if (box.status == BoxStatus.error) return;

    final text = _merge(box.text, box.interimText);
    if (text.isEmpty) {
      state = state.copyWith(
        boxes: state.boxes.where((b) => b.id != id).toList(),
        message: 'ما انسمع كلام واضح',
      );
      return;
    }
    _update(
      id,
      (b) => b.copyWith(status: BoxStatus.ready, text: text, interimText: ''),
    );
  }

  Future<void> _fail(String id, String message) async {
    final box = _find(id);
    if (box == null) return;

    if (state.activeRecordingId == id) {
      state = state.copyWith(clearActive: true);
      await ref.read(cancelDictationProvider)();
    }

    final text = _merge(box.text, box.interimText);
    if (text.isNotEmpty) {
      // ما منضيّع النص يلي طلع: منعرضه كـ ready ومنبلّغ بالخطأ
      _update(
        id,
        (b) => b.copyWith(status: BoxStatus.ready, text: text, interimText: ''),
      );
      state = state.copyWith(message: message);
    } else {
      _update(
        id,
        (b) => b.copyWith(
          status: BoxStatus.error,
          error: message,
          interimText: '',
        ),
      );
    }
  }

  // ---------------- box actions ----------------
  void moveBy(String id, Offset delta, Size area) {
    _update(id, (b) {
      final next = b.offset + delta;
      final maxX = math.max(0.0, area.width - kTranscriptBoxWidth);
      final maxY = math.max(0.0, area.height - 72);
      return b.copyWith(
        offset: Offset(
          next.dx.clamp(0.0, maxX).toDouble(),
          next.dy.clamp(0.0, maxY).toDouble(),
        ),
      );
    });
  }

  void startEdit(String id) => _update(id, (b) => b.copyWith(isEditing: true));

  void finishEdit(String id, String text) {
    _update(id, (b) => b.copyWith(isEditing: false, text: text.trim()));
  }

  Future<void> deleteBox(String id) async {
    final box = _find(id);
    if (box == null) return;

    if (box.status == BoxStatus.recording ||
        box.status == BoxStatus.finalizing) {
      await _sub?.cancel();
      _sub = null;
      await ref.read(cancelDictationProvider)();
      if (state.activeRecordingId == id) {
        state = state.copyWith(clearActive: true);
      }
    }
    state = state.copyWith(
      boxes: state.boxes.where((b) => b.id != id).toList(),
    );
  }

  Future<bool> confirmToTextBlocks(
    String pageId, {
    required Offset Function(Offset viewportPosition) toCanvasPosition,
  }) async {
    final readyBoxes = state.boxes
        .where(
          (box) => box.status == BoxStatus.ready && box.text.trim().isNotEmpty,
        )
        .toList();
    if (readyBoxes.isEmpty) {
      state = state.copyWith(message: 'لا يوجد نص جاهز للحفظ');
      return false;
    }

    final blocksResult =
        await ref.read(getBlocksUseCaseProvider)(GetBlocksParams(pageId));
    final existingBlocks = blocksResult.fold(
      (failure) {
        state = state.copyWith(message: failure.message);
        return null;
      },
      (blocks) => blocks,
    );
    if (existingBlocks == null) return false;

    final firstOrder = existingBlocks.fold<int>(
          -1,
          (maxOrder, block) => math.max(maxOrder, block.orderIndex),
        ) +
        1;
    final saveBlock = ref.read(saveBlockUseCaseProvider);

    for (var index = 0; index < readyBoxes.length; index++) {
      final box = readyBoxes[index];
      final text = box.text.trim();
      final now = DateTime.now();
      final canvasPosition = toCanvasPosition(box.offset);
      final block = TextBlock(
        id: 'voice-$pageId-${box.id}',
        pageId: pageId,
        orderIndex: firstOrder + index,
        x: canvasPosition.dx,
        y: canvasPosition.dy,
        width: kTranscriptBoxWidth,
        height: measureTextHeight(
          text: text,
          fontFamily: 'Roboto',
          fontSize: 16,
          width: kTranscriptBoxWidth,
        ),
        text: text,
        fontFamily: 'Roboto',
        fontSize: 16,
        createdAt: box.startedAt,
        updatedAt: now,
      );
      final result = await saveBlock(SaveBlockParams(block));
      final failure = result.fold((value) => value, (_) => null);
      if (failure != null) {
        state = state.copyWith(message: failure.message);
        return false;
      }
    }

    state = state.copyWith(message: 'تم حفظ النص');
    return true;
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  // ---------------- helpers ----------------
  TranscriptBox? _find(String id) =>
      state.boxes.where((b) => b.id == id).firstOrNull;

  String _merge(String a, String b) {
    if (a.isEmpty) return b.trim();
    if (b.isEmpty) return a.trim();
    return '${a.trim()} ${b.trim()}';
  }

  void _update(String id, TranscriptBox Function(TranscriptBox) change) {
    state = state.copyWith(
      boxes: [for (final b in state.boxes) b.id == id ? change(b) : b],
    );
  }
}

final voiceNotesProvider = AutoDisposeNotifierProvider.family<
    VoiceNotesNotifier, VoiceNotesState, String>(
  VoiceNotesNotifier.new,
);
