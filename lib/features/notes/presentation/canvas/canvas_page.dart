import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/canvas_area.dart';
import '../../../../core/constants/app_constants.dart';
import 'canvas_provider.dart';
import 'canvas_state.dart';
import 'widgets/canvas_app_bar.dart';
import 'widgets/text_editor_dialog.dart';
import 'widgets/toolbar.dart';
import 'widgets/canvas_error_banner.dart';
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
    final notifier = ref.read(canvasProvider(widget.pageId).notifier);
    final isHighlighter = canvasState.currentTool == CanvasTool.highlighter;
    final selectedText = canvasState.selectedTextBlock;

    return Scaffold(
      appBar: CanvasAppBar(
        selectedLanguage: _selectedLanguage,
        onLanguageChanged: (language) {
          setState(() => _selectedLanguage = language);
        },
         onSave: notifier.saveCurrentDrawing, //todo : it's not actually used
      ),
      body: Column(
        children: [
          CanvasToolbar(
            currentTool: canvasState.currentTool,
            activeColor: selectedText != null
                ? Color(selectedText.colorValue)
                : (isHighlighter
                    ? canvasState.highlighterColor
                    : canvasState.currentColor),
            sliderValue: selectedText != null
                ? selectedText.fontSize
                : (isHighlighter
                    ? canvasState.highlighterWidth
                    : canvasState.strokeWidth),
            sliderMin: selectedText != null ? 10 : 1,
            sliderMax: selectedText != null ? 48 : (isHighlighter ? 30 : 10),
            canUndo: canvasState.canUndo,
            canRedo: canvasState.canRedo,
            isRecognizing: canvasState.isRecognizing,
            hasSelection: canvasState.hasSelection,
            onDeleteSelected: notifier.deleteSelection,
            onUndo: notifier.undo,
            onRedo: notifier.redo,
            onClear: () => showClearCanvasDialog(
              context,
              onConfirm: notifier.clear,
            ),
            onConvert: canvasState.hasStrokeSelection
                ? () => notifier.convertToText(language: _selectedLanguage)
                : null,
            onAddText: () => _addTextAtCenter(notifier, canvasState),
            onEditText: selectedText == null
                ? null
                : () => showTextDialog(
                      context: context,
                      title: 'Edit text',
                      initial: selectedText.text,
                      confirmLabel: 'Save',
                      onSubmit: notifier.editSelectedText,
                    ),
            onColorChanged: notifier.setColor, //todo :
            onSliderChanged: selectedText != null
                ? notifier.previewSelectedTextFontSize
                : (isHighlighter
                    ? notifier.setHighlighterWidth
                    : notifier.setStrokeWidth),
            onSliderChangeEnd: selectedText != null
                ? (_) => notifier.commitSelectedTextFontSize()
                : null,
            onToolChanged: notifier.setTool,
          ),
          if (canvasState.error != null)
            CanvasErrorBanner(
              error: canvasState.error!,
              onDismiss: notifier.dismissError,
            ),
          Expanded(
            child: CanvasArea(
              state: canvasState,
              notifier: notifier,
              selectedLanguage: _selectedLanguage,
              onEditPendingText: () {
                showTextDialog(
                  context: context,
                  title: 'Fix recognized text',
                  initial: canvasState.pendingRecognizedText!,
                  confirmLabel: 'Update',
                  onSubmit: notifier.updatePendingText,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _addTextAtCenter(CanvasNotifier notifier, CanvasState state) {
    final size = state.canvasSize;
    final center = size.width > 0 && size.height > 0
        ? Offset(size.width / 2 - 110, size.height / 2 - 20)
        : const Offset(60, 60);

    showTextDialog(
      context: context,
      title: 'Add text',
      initial: '',
      confirmLabel: 'Add',
      onSubmit: (text) => notifier.addTextBlock(text, center),
    );
  }
}
