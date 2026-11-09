import 'package:freenotes_app/features/voice_notes/presentation/voice_notes_notifier.dart';
import 'package:freenotes_app/features/voice_notes/presentation/voice_notes_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

TextDirection _dirFor(String s) {
  final first = RegExp(r'[A-Za-z\u0600-\u06FF]').firstMatch(s)?.group(0);
  if (first == null) return TextDirection.rtl;
  return RegExp(r'[\u0600-\u06FF]').hasMatch(first)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

class TranscriptBoxWidget extends ConsumerStatefulWidget {
  const TranscriptBoxWidget({
    super.key,
    required this.box,
    required this.area,
    required this.pageId,
  });

  final TranscriptBox box;
  final String pageId;

  /// حجم منطقة الشاشة (لحصر السحب داخلها).
  final Size area;

  @override
  ConsumerState<TranscriptBoxWidget> createState() =>
      _TranscriptBoxWidgetState();
}

class _TranscriptBoxWidgetState extends ConsumerState<TranscriptBoxWidget> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.box.text);

  @override
  void didUpdateWidget(covariant TranscriptBoxWidget old) {
    super.didUpdateWidget(old);
    if (widget.box.isEditing && !old.box.isEditing) {
      _controller.text = widget.box.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(voiceNotesProvider(widget.pageId).notifier);

    final borderColor = switch (box.status) {
      BoxStatus.recording || BoxStatus.error => scheme.error,
      BoxStatus.finalizing => scheme.tertiary,
      BoxStatus.ready => box.isEditing ? scheme.primary : scheme.outlineVariant,
    };

    return Material(
      elevation: 3,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: kTranscriptBoxWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: box.isEditing ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الهيدر = مقبض السحب (ما بيتعارض مع تحديد النص أثناء التعديل)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => notifier.moveBy(box.id, d.delta, widget.area),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, size: 20, color: scheme.outline),
                    const SizedBox(width: 6),
                    Expanded(child: _statusLabel(box, scheme)),
                    ..._actions(box, notifier),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _body(box, scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLabel(TranscriptBox box, ColorScheme scheme) {
    switch (box.status) {
      case BoxStatus.recording:
        return Row(children: [
          Icon(Icons.circle, size: 10, color: scheme.error),
          const SizedBox(width: 6),
          const Text('جاري التسجيل'),
          const SizedBox(width: 8),
          _RecordingTimer(startedAt: box.startedAt),
        ]);
      case BoxStatus.finalizing:
        return const Row(children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('جاري إنهاء النص...'),
        ]);
      case BoxStatus.ready:
        return Text(box.isEditing ? 'تعديل' : 'النص');
      case BoxStatus.error:
        return Text('صار خطأ', style: TextStyle(color: scheme.error));
    }
  }

  List<Widget> _actions(TranscriptBox box, VoiceNotesNotifier notifier) {
    Widget btn(IconData icon, String tip, VoidCallback onTap) => IconButton(
          icon: Icon(icon),
          iconSize: 20,
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          onPressed: onTap,
        );

    return [
      if (box.status == BoxStatus.ready)
        if (box.isEditing)
          btn(Icons.check, 'تم',
              () => notifier.finishEdit(box.id, _controller.text))
        else
          btn(Icons.edit_outlined, 'تعديل', () => notifier.startEdit(box.id)),
      btn(Icons.close, 'حذف', () => notifier.deleteBox(box.id)),
    ];
  }

  Widget _body(TranscriptBox box, ColorScheme scheme) {
    final grey = TextStyle(color: scheme.outline);

    switch (box.status) {
      case BoxStatus.error:
        return Text(box.error ?? 'خطأ', style: TextStyle(color: scheme.error));

      case BoxStatus.recording:
      case BoxStatus.finalizing:
        final fin = box.text;
        final tmp = box.interimText;
        if (fin.isEmpty && tmp.isEmpty) {
          return Text(
            box.status == BoxStatus.recording
                ? 'تحدّثي الآن...'
                : 'عم نجهّز النص...',
            style: grey,
          );
        }
        // النهائي بلون عادي، والمؤقت رمادي
        return Text.rich(
          TextSpan(children: [
            TextSpan(text: fin),
            if (tmp.isNotEmpty)
              TextSpan(text: fin.isEmpty ? tmp : ' $tmp', style: grey),
          ]),
          textDirection: _dirFor('$fin $tmp'),
        );

      case BoxStatus.ready:
        if (box.isEditing) {
          return TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            textDirection: _dirFor(_controller.text),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
          );
        }
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(box.text, textDirection: _dirFor(box.text)),
        );
    }
  }
}

class _RecordingTimer extends StatelessWidget {
  const _RecordingTimer({required this.startedAt});
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (_, __) {
        final d = DateTime.now().difference(startedAt);
        return Text(
          '${two(d.inMinutes)}:${two(d.inSeconds % 60)}',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        );
      },
    );
  }
}
