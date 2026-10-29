import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import 'package:freenotes_app/core/constants/app_constants.dart';
import 'package:freenotes_app/core/widgets/color_picker.dart';
import '../../canvas_state.dart';

// Layout pattern: "stable bar + anchored popover".
// - The bar is ONE fixed-height row. Nothing in it appears, disappears or
// - Color / size options live in a popover that floats above the canvas
class CanvasToolbar extends StatefulWidget {
  final CanvasTool currentTool;
  final Color activeColor;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final String selectedLanguage;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback? onConvert;
  final VoidCallback? onConvertUnavailable;
  final VoidCallback onAddText;
  final VoidCallback? onEditText;
  final bool canUndo;
  final bool canRedo;
  final bool isRecognizing;
  final bool hasSelection;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onDeleteSelected;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;
  final ValueChanged<CanvasTool> onToolChanged;
  final VoidCallback onFitPage;
  final bool showColor;
  final bool showSize;

  const CanvasToolbar({
    super.key,
    required this.currentTool,
    required this.activeColor,
    required this.sliderValue,
    this.sliderMin = 1,
    this.sliderMax = 10,
    required this.selectedLanguage,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    this.onConvert,
    this.onConvertUnavailable,
    required this.onAddText,
    this.onEditText,
    required this.canUndo,
    required this.canRedo,
    required this.isRecognizing,
    required this.hasSelection,
    required this.onLanguageChanged,
    required this.onDeleteSelected,
    required this.onColorChanged,
    required this.onSliderChanged,
    this.onSliderChangeEnd,
    required this.onToolChanged,
    required this.onFitPage,
    required this.showColor,
    required this.showSize,
  });

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  static const double _rowHeight = 48;
  static const double _panelMaxWidth = 360;
  bool _showAdvancedControls = false;
  final ScrollController _toolsScrollController = ScrollController();
  // Shows / hides the floating panel (it is not part of the layout).
  final OverlayPortalController _panelController = OverlayPortalController();
  /// Connects the panel to the toolbar, so it opens right under it.
  final LayerLink _panelLink = LayerLink();
  /// The bar and the panel share this id: a tap inside either one is "inside".
  final Object _tapGroup = Object();
  bool get _hasAdvancedControls => widget.showColor || widget.showSize;

  @override
  void didUpdateWidget(covariant CanvasToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The new tool has no options: close the panel (after this frame).
    if (_showAdvancedControls && !_hasAdvancedControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setPanelVisible(false);
      });
    }
  }

  @override
  void dispose() {
    _toolsScrollController.dispose();
    super.dispose();
  }

  void _setPanelVisible(bool visible) {
    if (_showAdvancedControls == visible) return;
    if (visible && !_hasAdvancedControls) return;

    setState(() => _showAdvancedControls = visible);
    if (visible) {
      _panelController.show();
    } else {
      _panelController.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return CompositedTransformTarget(
      link: _panelLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:const BoxDecoration(
          color: AppColors.lightGrey,
          border: Border(
            bottom: BorderSide(color: AppColors.greyBorder),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = math.min(constraints.maxWidth, _panelMaxWidth);

              return OverlayPortal(
                controller: _panelController,
                overlayChildBuilder: (_) => _buildPanelOverlay(panelWidth, isRtl),
                child: TapRegion(
                  groupId: _tapGroup,
                  // Fixed height: the bar can never grow or shrink.
                  child: SizedBox(
                    height: _rowHeight,
                    child: Row(
                      children: [
                        _StyleButton(
                          enabled: _hasAdvancedControls,
                          open: _showAdvancedControls,
                          showColor: widget.showColor,
                          color: widget.activeColor,
                          tooltip: _showAdvancedControls
                              ? AppStrings.lessTools
                              : AppStrings.moreTools,
                          onTap: () => _setPanelVisible(!_showAdvancedControls),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ToolsRow(
                            currentTool: widget.currentTool,
                            canUndo: widget.canUndo,
                            canRedo: widget.canRedo,
                            hasSelection: widget.hasSelection,
                            isRecognizing: widget.isRecognizing,
                            selectedLanguage: widget.selectedLanguage,
                            onToolChanged: widget.onToolChanged,
                            onFitPage: widget.onFitPage,
                            onAddText: widget.onAddText,
                            onUndo: widget.onUndo,
                            onRedo: widget.onRedo,
                            onClear: widget.onClear,
                            onEditText: widget.onEditText,
                            onDeleteSelected: widget.onDeleteSelected,
                            onLanguageChanged: widget.onLanguageChanged,
                            onConvert: widget.onConvert,
                            onConvertUnavailable: widget.onConvertUnavailable,
                            scrollController: _toolsScrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The floating panel. It sits in the Overlay, above the canvas.
  Widget _buildPanelOverlay(double width, bool isRtl) {
    // Stack gives the follower LOOSE constraints, so the panel keeps its own
    // size instead of being stretched to the full screen.
    return Stack(
      children: [
        CompositedTransformFollower(
          link: _panelLink,
          showWhenUnlinked: false,
          targetAnchor: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
          followerAnchor: isRtl ? Alignment.topRight : Alignment.topLeft,
          offset: Offset(isRtl ? -8 : 8, 6),
          child: TapRegion(
            groupId: _tapGroup,
            // Tap outside bar + panel closes it. The tap still reaches the
            // canvas, so the user can keep drawing.
            onTapOutside: (_) => _setPanelVisible(false),
            child: _StylePanel(
              width: width,
              showColor: widget.showColor,
              showSize: widget.showSize,
              activeColor: widget.activeColor,
              sliderValue: widget.sliderValue,
              sliderMin: widget.sliderMin,
              sliderMax: widget.sliderMax,
              onColorChanged: widget.onColorChanged,
              onSliderChanged: widget.onSliderChanged,
              onSliderChangeEnd: widget.onSliderChangeEnd,
            ),
          ),
        ),
      ],
    );
  }
}

//________________
/// Fixed 48x48 button Shows the active color and
class _StyleButton extends StatelessWidget {
  final bool enabled;
  final bool open;
  final bool showColor;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _StyleButton({
    required this.enabled,
    required this.open,
    required this.showColor,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 24,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showColor ? color : AppColors.greySurface,
                      border: Border.all(
                        color: open ? theme.primaryColor : AppColors.greyBorder,
                        width: open ? 2 : 1,
                      ),
                    ),
                    child: showColor ? null : const Icon(Icons.tune, size: 16),
                  ),
                ),
                Positioned(
                  right: 3,
                  bottom: 5,
                  child: Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//________________
// The scrollable tools. Every slot is always present: actions that do not apply are disabled, not removed, so nothing shifts sideways.
class _ToolsRow extends StatelessWidget {
  final CanvasTool currentTool;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelection;
  final bool isRecognizing;
  final String selectedLanguage;

  final ValueChanged<CanvasTool> onToolChanged;
  final VoidCallback onFitPage;
  final VoidCallback onAddText;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback? onEditText;
  final VoidCallback onDeleteSelected;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback? onConvert;
  final VoidCallback? onConvertUnavailable;
  final ScrollController scrollController;

  const _ToolsRow({
    required this.currentTool,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelection,
    required this.isRecognizing,
    required this.selectedLanguage,
    required this.onToolChanged,
    required this.onFitPage,
    required this.onAddText,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onEditText,
    required this.onDeleteSelected,
    required this.onLanguageChanged,
    required this.onConvert,
    required this.onConvertUnavailable,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      thickness: 2,
      radius: const Radius.circular(12),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: onFitPage,
              tooltip: AppStrings.fitPage,
            ),
            _ToolButton(
              icon: Icons.back_hand_outlined,
              isSelected: currentTool == CanvasTool.pan,
              onTap: () => onToolChanged(CanvasTool.pan),
              tooltip: AppStrings.panZoom,
            ),
            _ToolButton(
              icon: Icons.highlight_alt,
              isSelected: currentTool == CanvasTool.lasso,
              onTap: () => onToolChanged(CanvasTool.lasso),
              tooltip: AppStrings.select,
            ),
            _ToolButton(
              icon: Icons.edit,
              isSelected: currentTool == CanvasTool.pen,
              onTap: () => onToolChanged(CanvasTool.pen),
              tooltip: AppStrings.pen,
            ),
            _ToolButton(
              icon: Icons.highlight,
              isSelected: currentTool == CanvasTool.highlighter,
              onTap: () => onToolChanged(CanvasTool.highlighter),
              tooltip: AppStrings.highlighter,
            ),
            _ToolButton(
              icon: Icons.cleaning_services_outlined,
              isSelected: currentTool == CanvasTool.eraser,
              onTap: () => onToolChanged(CanvasTool.eraser),
              tooltip: AppStrings.eraser,
            ),
            _ToolButton(
              icon: Icons.auto_awesome,
              isSelected: currentTool == CanvasTool.magic,
              onTap: () => onToolChanged(CanvasTool.magic),
              tooltip: AppStrings.magicPointer,
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: onAddText,
              tooltip: AppStrings.addText,
            ),
            const VerticalDivider(width: 1),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
              tooltip: AppStrings.undo,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
              tooltip: AppStrings.redo,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onClear,
              tooltip: AppStrings.clearDrawing,
            ),
            // Disabled when there is no text to edit.
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: onEditText,
              tooltip: AppStrings.editText,
            ),
            //  Disabled when nothing is selected.
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              color: hasSelection ? AppColors.red : null,
              onPressed: hasSelection ? onDeleteSelected : null,
              tooltip: AppStrings.deleteSelected,
            ),
            const SizedBox(width: 4),
            _LanguageConvertGroup(
              selectedLanguage: selectedLanguage,
              isRecognizing: isRecognizing,
              onLanguageChanged: onLanguageChanged,
              onConvert: onConvert,
              onConvertUnavailable: onConvertUnavailable,
            ),
          ],
        ),
      ),
    );
  }
}

//________________
// The floating options panel (color + size).
class _StylePanel extends StatelessWidget {
  final double width;
  final bool showColor;
  final bool showSize;
  final Color activeColor;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;

  const _StylePanel({
    required this.width,
    required this.showColor,
    required this.showSize,
    required this.activeColor,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onColorChanged,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorControls = [
      ...[
        AppColors.black,
        AppColors.red,
        AppColors.blue,
        AppColors.green,
        AppColors.orange,
        AppColors.purple,
        AppColors.yellow,
      ].map(
        (color) => _ColorDot(
          color: color,
          selected: activeColor.value == color.value,
          onTap: () => onColorChanged(color),
        ),
      ),
      ColorPicker(
        selectedColor: activeColor,
        onColorSelected: onColorChanged,
        compact: true,
      ),
    ];

    final slider = Slider(
      value: sliderValue.clamp(sliderMin, sliderMax),
      min: sliderMin,
      max: sliderMax,
      label: sliderValue.toStringAsFixed(1),
      onChanged: onSliderChanged,
      onChangeEnd: onSliderChangeEnd,
    );

    // Small fade + slide when the panel opens.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * -6), child: child),
      ),
      child: Material(
        color: AppColors.lightGrey,
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.greyBorder),
        ),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelSection(
                  enabled: showColor,
                  child: Wrap(
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: colorControls,
                  ),
                ),
                const SizedBox(height: 4),
                _PanelSection(enabled: showSize, child: slider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//__________________________
// Keeps the section in the layout, but dimmed and untouchable when the current tool does not use it.
class _PanelSection extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _PanelSection({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(ignoring: !enabled, child: child),
    );
  }
}

//__________________________
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? AppColors.white : color,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

//_____________
/// Language + Convert.
class _LanguageConvertGroup extends StatelessWidget {
  final String selectedLanguage;
  final bool isRecognizing;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback? onConvert;
  final VoidCallback? onConvertUnavailable;

  const _LanguageConvertGroup({
    required this.selectedLanguage,
    required this.isRecognizing,
    required this.onLanguageChanged,
    required this.onConvert,
    required this.onConvertUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = selectedLanguage == AppConstants.langArabic;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greyBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            enabled: !isRecognizing,
            tooltip: AppStrings.recognitionLanguage,
            initialValue: selectedLanguage,
            onSelected: onLanguageChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AppConstants.langArabic,
                child: Text(AppStrings.arabicLanguage),
              ),
              PopupMenuItem(
                value: AppConstants.langEnglish,
                child: Text(AppStrings.englishLanguage),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Same width for both language codes.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 28),
                    child: Center(
                      child: Text(
                        isArabic
                            ? AppStrings.arabicCode
                            : AppStrings.englishCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          FilledButton.icon(
            onPressed: isRecognizing ? null : (onConvert ?? onConvertUnavailable),
            style: onConvert == null
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.greyBorder,
                    foregroundColor: AppColors.greyText,
                  )
                : null,
            icon: isRecognizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.translate,
                    size: 18,
                  ),
            label: const Text(AppStrings.convert),
          ),
        ],
      ),
    );
  }
}

//____________
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;
  const _ToolButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.1)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? theme.primaryColor : null,
        ),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}