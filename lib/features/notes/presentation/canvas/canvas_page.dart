import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/canvas_area.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'canvas_provider.dart';
import 'canvas_state.dart';
import 'widgets/canvas_app_bar.dart';
import 'widgets/text_editor_dialog.dart';
import 'widgets/tool_bar_widgets/toolbar.dart';
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
  Size _viewportSize = Size.zero;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider(widget.pageId));
    final notifier = ref.read(canvasProvider(widget.pageId).notifier);
    final isHighlighter = canvasState.currentTool == CanvasTool.highlighter;
    final selectedText = canvasState.selectedTextBlock;

    final isEraser = canvasState.currentTool == CanvasTool.eraser;
    final isPan = canvasState.currentTool == CanvasTool.pan;

    final showColor = !isPan &&
        (selectedText != null ||
            canvasState.currentTool == CanvasTool.pen ||
            canvasState.currentTool == CanvasTool.highlighter ||
            canvasState.currentTool == CanvasTool.magic);

    final showSize = !isPan &&
        (selectedText != null ||
            canvasState.currentTool == CanvasTool.pen ||
            canvasState.currentTool == CanvasTool.highlighter ||
            canvasState.currentTool == CanvasTool.eraser);

    return Scaffold(
      appBar: CanvasAppBar(onSave: () async {
        await notifier.saveCurrentDrawing();
        print('saved');
      } //todo : it's not actually used
          ),
      body: Column(
        children: [
          CanvasToolbar(
            showColor: showColor,
            showSize: showSize,
            currentTool: canvasState.currentTool,
            activeColor: selectedText != null
                ? Color(selectedText.colorValue)
                : (isHighlighter
                    ? canvasState.highlighterColor
                    : canvasState.currentColor),
            sliderValue: selectedText != null
                ? selectedText.fontSize
                : isEraser
                    ? canvasState.eraserSize
                    : isHighlighter
                        ? canvasState.highlighterWidth
                        : canvasState.strokeWidth,
            sliderMin: selectedText != null
                ? 10
                : isEraser
                    ? 5
                    : 1,

            sliderMax: selectedText != null
                ? 48
                : isEraser
                    ? 50
                    : isHighlighter
                        ? 30
                        : 10,
            selectedLanguage: _selectedLanguage,
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
            onConvertUnavailable: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    content: const Text(
                      'Select handwriting before converting it to text.',
                    ),
                  ),
                );
            },
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
                : isEraser
                    ? notifier.setEraserSize
                    : isHighlighter
                        ? notifier.setHighlighterWidth
                        : notifier.setStrokeWidth,
            onSliderChangeEnd: selectedText != null
                ? (_) => notifier.commitSelectedTextFontSize()
                : null,
            onLanguageChanged: (language) {
              setState(() => _selectedLanguage = language);
            },
            onToolChanged: notifier.setTool,
            onFitPage: _fitPage,
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
              transformationController: _transformationController,
              onViewportSizeChanged: _handleViewportSizeChanged,
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

  void _handleViewportSizeChanged(Size size) {
    if (size != _viewportSize && mounted) {
      setState(() => _viewportSize = size);
    }
  }

  void _fitPage() {
    if (_viewportSize.width <= 0) return;
    final scale = _viewportSize.width / AppConstants.pageWidth;
    _transformationController.value = Matrix4.diagonal3Values(
      scale,
      scale,
      1,
    );
  }

  void _addTextAtCenter(CanvasNotifier notifier, CanvasState state) {
    final viewportCenter = _transformationController.toScene(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
    );
    final center = Offset(viewportCenter.dx - 110, viewportCenter.dy - 20);

    showTextDialog(
      context: context,
      title: 'Add text',
      initial: '',
      confirmLabel: 'Add',
      onSubmit: (text) => notifier.addTextBlock(text, center),
    );
  }
}
