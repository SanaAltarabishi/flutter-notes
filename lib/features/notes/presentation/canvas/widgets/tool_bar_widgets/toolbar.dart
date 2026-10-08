import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_constants.dart';
import 'package:freenotes_app/core/widgets/color_picker.dart';
import '../../canvas_state.dart';

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
  });

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  bool _showAdvancedControls = true;

  final ScrollController _toolsScrollController = ScrollController();
  final ScrollController _colorsScrollController = ScrollController();

  @override
  void dispose() {
    _toolsScrollController.dispose();
    _colorsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolsRow(
                  showAdvancedControls: _showAdvancedControls,
                  currentTool: widget.currentTool,
                  canUndo: widget.canUndo,
                  canRedo: widget.canRedo,
                  hasSelection: widget.hasSelection,
                  isRecognizing: widget.isRecognizing,
                  selectedLanguage: widget.selectedLanguage,
                  onToggleAdvanced: () {
                    setState(() {
                      _showAdvancedControls = !_showAdvancedControls;
                    });
                  },
                  onToolChanged: widget.onToolChanged,
                  onAddText: widget.onAddText,
                  onUndo: widget.onUndo,
                  onRedo: widget.onRedo,
                  onClear: widget.onClear,
                  onEditText: widget.onEditText,
                  onDeleteSelected: widget.onDeleteSelected,
                  onLanguageChanged: widget.onLanguageChanged,
                  onConvert: widget.onConvert,
                  scrollController: _toolsScrollController,
                ),
                if (_showAdvancedControls) ...[
                  const SizedBox(height: 4),
                  _AdvancedControls(
                    isNarrow: isNarrow,
                    activeColor: widget.activeColor,
                    sliderValue: widget.sliderValue,
                    sliderMin: widget.sliderMin,
                    sliderMax: widget.sliderMax,
                    onColorChanged: widget.onColorChanged,
                    onSliderChanged: widget.onSliderChanged,
                    onSliderChangeEnd: widget.onSliderChangeEnd,
                    scrollController: _colorsScrollController,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

//________________
class _ToolsRow extends StatelessWidget {
  final bool showAdvancedControls;
  final CanvasTool currentTool;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelection;
  final bool isRecognizing;
  final String selectedLanguage;

  final VoidCallback onToggleAdvanced;
  final ValueChanged<CanvasTool> onToolChanged;
  final VoidCallback onAddText;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback? onEditText;
  final VoidCallback onDeleteSelected;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback? onConvert;
  final ScrollController scrollController;

  const _ToolsRow({
    required this.showAdvancedControls,
    required this.currentTool,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelection,
    required this.isRecognizing,
    required this.selectedLanguage,
    required this.onToggleAdvanced,
    required this.onToolChanged,
    required this.onAddText,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onEditText,
    required this.onDeleteSelected,
    required this.onLanguageChanged,
    required this.onConvert,
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
            if (!showAdvancedControls)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.unfold_more, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'More tools',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            IconButton(
              tooltip: showAdvancedControls
                  ? 'Hide advanced controls'
                  : 'Show advanced controls',
              onPressed: onToggleAdvanced,
              icon: Icon(
                showAdvancedControls
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.back_hand_outlined,
              isSelected: currentTool == CanvasTool.lasso,
              onTap: () => onToolChanged(CanvasTool.lasso),
              tooltip: 'Select',
            ),
            _ToolButton(
              icon: Icons.edit,
              isSelected: currentTool == CanvasTool.pen,
              onTap: () => onToolChanged(CanvasTool.pen),
              tooltip: 'Pen',
            ),
            _ToolButton(
              icon: Icons.highlight,
              isSelected: currentTool == CanvasTool.highlighter,
              onTap: () => onToolChanged(CanvasTool.highlighter),
              tooltip: 'Highlighter',
            ),
            _ToolButton(
              icon: Icons.cleaning_services_outlined,
              isSelected: currentTool == CanvasTool.eraser,
              onTap: () => onToolChanged(CanvasTool.eraser),
              tooltip: 'Eraser',
            ),
            _ToolButton(
              icon: Icons.auto_awesome,
              isSelected: currentTool == CanvasTool.magic,
              onTap: () => onToolChanged(CanvasTool.magic),
              tooltip: 'Magic pointer',
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: onAddText,
              tooltip: 'Add text',
            ),
            const VerticalDivider(width: 1),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onClear,
              tooltip: 'Clear drawing',
            ),
            if (onEditText != null)
              IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: onEditText,
                tooltip: 'Edit text',
              ),
            if (hasSelection)
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red,
                ),
                onPressed: onDeleteSelected,
                tooltip: 'Delete selected',
              ),
            if (isRecognizing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              _LanguageConvertGroup(
                selectedLanguage: selectedLanguage,
                onLanguageChanged: onLanguageChanged,
                onConvert: onConvert,
              ),
          ],
        ),
      ),
    );
  }
}

//________________
class _AdvancedControls extends StatelessWidget {
  final bool isNarrow;
  final Color activeColor;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;
  final ScrollController scrollController;

  const _AdvancedControls({
    required this.isNarrow,
    required this.activeColor,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onColorChanged,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colorControls = [
      ...[
        Colors.black,
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.yellow,
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

    if (isNarrow) {
      return Column(
        children: [
          Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            thickness: 7,
            radius: const Radius.circular(12),
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: colorControls,
              ),
            ),
          ),
          slider,
        ],
      );
    }

    return Row(
      children: [
        ...colorControls,
        const SizedBox(width: 16),
        Expanded(child: slider),
      ],
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
class _LanguageConvertGroup extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback? onConvert;
  const _LanguageConvertGroup({
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onConvert,
  });
  @override
  Widget build(BuildContext context) {
    final isArabic = selectedLanguage == AppConstants.langArabic;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Recognition language',
            initialValue: selectedLanguage,
            onSelected: onLanguageChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AppConstants.langArabic,
                child: Text('Arabic'),
              ),
              PopupMenuItem(
                value: AppConstants.langEnglish,
                child: Text('English'),
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
                  Text(
                    isArabic ? 'AR' : 'EN',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
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
            onPressed: onConvert,
            icon: const Icon(
              Icons.translate,
              size: 18,
            ),
            label: const Text('Convert'),
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
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? theme.primaryColor : null,
      ),
      tooltip: tooltip,
      onPressed: onTap,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
            )
          : null,
    );
  }
}
