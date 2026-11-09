import 'package:freenotes_app/features/voice_notes/domain/stt_language.dart';
import 'package:freenotes_app/features/voice_notes/presentation/transcript_box_widget.dart';
import 'package:freenotes_app/features/voice_notes/presentation/voice_notes_notifier.dart';
import 'package:freenotes_app/features/voice_notes/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceNotesOverlay extends ConsumerWidget {
  const VoiceNotesOverlay({
    super.key,
    required this.pageId,
    required this.onClose,
    required this.onSaved,
  });

  final String pageId;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(voiceNotesProvider(pageId).select((s) => s.message), (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
      ref.read(voiceNotesProvider(pageId).notifier).clearMessage();
    });

    final state = ref.watch(voiceNotesProvider(pageId));
    final notifier = ref.read(voiceNotesProvider(pageId).notifier);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withOpacity(0.96),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.mic_none),
                    ),
                    const Expanded(child: Text('ملاحظات صوتية')),
                    _EngineMenu(enabled: !state.isBusy),
                    const _LanguageMenu(),
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'حفظ النص في الصفحة',
                      onPressed: state.isBusy
                          ? null
                          : () async {
                              final saved =
                                  await notifier.confirmToTextBlocks(pageId);
                              if (saved) {
                                onSaved();
                                onClose();
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                      onPressed: state.isBusy ? null : onClose,
                    ),
                  ],
                ),
              ),
            ),
            for (final box in state.boxes)
              Positioned(
                key: ValueKey(box.id),
                left: box.offset.dx,
                top: box.offset.dy,
                child: TranscriptBoxWidget(
                  box: box,
                  area: area,
                  pageId: pageId,
                ),
              ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                backgroundColor: state.isRecording ? scheme.error : null,
                foregroundColor: state.isRecording ? scheme.onError : null,
                onPressed: state.isFinalizing ? null : notifier.toggleRecording,
                child: Icon(state.isRecording ? Icons.stop : Icons.mic),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EngineMenu extends ConsumerWidget {
  const _EngineMenu({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sttEngineProvider);
    return PopupMenuButton<SttEngine>(
      enabled: enabled,
      icon: const Icon(Icons.graphic_eq),
      tooltip: 'محرّك التعرّف',
      initialValue: current,
      onSelected: ref.read(sttEngineProvider.notifier).set,
      itemBuilder: (_) => [
        for (final e in SttEngine.values)
          PopupMenuItem(value: e, child: Text(e.label)),
      ],
    );
  }
}

class _LanguageMenu extends ConsumerWidget {
  const _LanguageMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sttLanguageProvider);
    return PopupMenuButton<SttLanguage>(
      icon: const Icon(Icons.translate),
      tooltip: 'لغة التعرّف',
      initialValue: current,
      onSelected: ref.read(sttLanguageProvider.notifier).set,
      itemBuilder: (_) => [
        for (final l in SttLanguage.values)
          PopupMenuItem(value: l, child: Text(l.label)),
      ],
    );
  }
}
