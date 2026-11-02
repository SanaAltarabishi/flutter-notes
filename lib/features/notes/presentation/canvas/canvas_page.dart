import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/widgets/canvas_area.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import 'canvas_provider.dart';
import 'canvas_state.dart';
import 'widgets/canvas_app_bar.dart';
import 'widgets/text_editor_dialog.dart';
import 'widgets/tool_bar_widgets/toolbar.dart';
import 'widgets/canvas_error_banner.dart';
import 'widgets/clear_canvas_dialog.dart';

class CanvasPage extends ConsumerStatefulWidget {
  final String pageId;
  final String pageTitle;
  const CanvasPage({super.key, required this.pageId, required this.pageTitle});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _selectedLanguage = AppConstants.langArabic;
  Size _viewportSize = Size.zero;
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  bool _isLeaving = false;

  Future<void> _saveAndLeave() async {
    if (_isLeaving) return;

    _isLeaving = true;

    await ref.read(canvasProvider(widget.pageId).notifier).saveOnExit();

    if (!mounted) return;

    setState(() {});

    // Wait until PopScope updates canPop.
    await WidgetsBinding.instance.endOfFrame;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(_applyZoomAnimation);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(canvasProvider(widget.pageId).notifier).saveOnExit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _applyZoomAnimation() {
    final animation = _zoomAnimation;
    if (animation != null) {
      _transformationController.value = animation.value;
    }
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

    return PopScope(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _saveAndLeave();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        // backgroundColor: AppColors.white,
        appBar: CanvasAppBar(
            pageTitle: widget.pageTitle,
            onSave: () async {
              await notifier.saveCurrentDrawing();
              print('saved');
            } //todo : it's not actually usedS
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
                      : isHighlighter
                          ? 10
                          : 1,

              sliderMax: selectedText != null
                  ? 48
                  : isEraser
                      ? 50
                      : isHighlighter
                          ? 50
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
                        AppStrings.selectHandwriting,
                      ),
                    ),
                  );
              },
              onAddText: () => _addTextAtCenter(notifier, canvasState),
              onEditText: selectedText == null
                  ? null
                  : () => showTextDialog(
                        context: context,
                        title: AppStrings.editText,
                        initial: selectedText.text,
                        confirmLabel: AppStrings.save,
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
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
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
                onCanvasExpanded: _animateForCanvasExpansion,
                selectedLanguage: _selectedLanguage,
                onEditPendingText: () {
                  showTextDialog(
                    context: context,
                    title: AppStrings.fixRecognizedText,
                    initial: canvasState.pendingRecognizedText!,
                    confirmLabel: AppStrings.update,
                    onSubmit: notifier.updatePendingText,
                  );
                },
              ),
            )
          ],
        ),
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
    _animateToMatrix(Matrix4.diagonal3Values(scale, scale, 1));
  }

  void _zoomIn() => _zoomBy(1.2);

  void _zoomOut() => _zoomBy(0.8);

  void _zoomBy(double factor) {
    if (_viewportSize.isEmpty) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final fitScale = _viewportSize.width / AppConstants.pageWidth;
    final targetScale =
        (currentScale * factor).clamp(fitScale, 10.0).toDouble();
    final actualFactor = targetScale / currentScale;
    if (actualFactor == 1) return;

    final center = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    final target = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(actualFactor, actualFactor, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1)
      ..multiply(_transformationController.value);
    _animateToMatrix(target);
  }

  void _animateToMatrix(Matrix4 target) {
    _zoomAnimationController.stop();
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value.clone(),
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _zoomAnimationController.forward(from: 0);
  }

  void _animateForCanvasExpansion(Offset contentShift) {
    if (contentShift == Offset.zero) return;

    // Content added at the top/left shifts existing scene coordinates by
    // contentShift. Applying the inverse scene translation keeps the selected
    // content anchored while the new canvas area becomes visible.
    final target = _transformationController.value.clone()
      ..translateByDouble(-contentShift.dx, -contentShift.dy, 0, 1);
    _animateToMatrix(target);
  }

  void _addTextAtCenter(CanvasNotifier notifier, CanvasState state) {
    final viewportCenter = _transformationController.toScene(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
    );
    final center = Offset(viewportCenter.dx - 110, viewportCenter.dy - 20);

    showTextDialog(
      context: context,
      title: AppStrings.addText,
      initial: '',
      confirmLabel: AppStrings.add,
      onSubmit: (text) => notifier.addTextBlock(text, center),
    );
  }
}
