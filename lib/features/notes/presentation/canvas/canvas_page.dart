import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import 'canvas_provider.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/toolbar.dart';
import 'widgets/canvas_error_banner.dart';
import 'widgets/recognized_text_banner.dart';
import 'widgets/clear_canvas_dialog.dart';

class CanvasPage extends ConsumerStatefulWidget {
  final String pageId;
  const CanvasPage({super.key, required this.pageId});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  String _selectedLanguage = AppConstants.langArabic;

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider(widget.pageId));
    final canvasNotifier = ref.read(canvasProvider(widget.pageId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeNotes'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedLanguage,
            onSelected: (lang) => setState(() => _selectedLanguage = lang),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: AppConstants.langArabic, child: Text('العربية')),
              const PopupMenuItem(
                  value: AppConstants.langEnglish, child: Text('English')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                    _selectedLanguage == AppConstants.langArabic ? 'AR' : 'EN'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved (demo)')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CanvasToolbar(
            currentTool: canvasState.currentTool,
            currentColor: canvasState.currentColor,
            strokeWidth: canvasState.strokeWidth,
            canUndo: canvasState.strokes.isNotEmpty,
            canRedo: canvasState.redoStack.isNotEmpty,
            isRecognizing: canvasState.isRecognizing,
            onUndo: canvasNotifier.undo,
            onRedo: canvasNotifier.redo,
            onClear: () => showClearCanvasDialog(
              context,
              onConfirm: canvasNotifier.clear,
            ),
            onConvert: () =>
                canvasNotifier.convertToText(language: _selectedLanguage),
            onColorChanged: canvasNotifier.setColor,
            onStrokeWidthChanged: canvasNotifier.setStrokeWidth,
            onToolChanged: canvasNotifier.setTool,
          ),
          if (canvasState.recognizedText != null)
            RecognizedTextBanner(
              text: canvasState.recognizedText!,
              textDirection: _selectedLanguage == AppConstants.langArabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              onDismiss: canvasNotifier.clearRecognizedText,
            ),
          if (canvasState.error != null)
            CanvasErrorBanner(
              error: canvasState
                  .error!, // Failure now, not String — banner reads .message itself
              onDismiss: canvasNotifier.dismissError,
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  canvasNotifier.setCanvasSize(constraints.biggest);
                });
                return DrawingCanvas(
                  strokes: canvasState.strokes,
                  onStart: canvasNotifier.startStroke,
                  onUpdate: canvasNotifier.addPoint,
                  onEnd: canvasNotifier.endStroke,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
