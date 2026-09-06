import 'package:flutter/material.dart';
import '../canvas_state.dart';

class CanvasToolbar extends StatelessWidget {
  final CanvasTool currentTool;
  final Color currentColor;
  final double strokeWidth;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onConvert;
  final bool canUndo;
  final bool canRedo;
  final bool isRecognizing;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<CanvasTool> onToolChanged;

  const CanvasToolbar({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.strokeWidth,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onConvert,
    required this.canUndo,
    required this.canRedo,
    required this.isRecognizing,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onToolChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Tools
            Row(
              children: [
                _ToolButton(
                  icon: Icons.edit,
                  isSelected: currentTool == CanvasTool.pen,
                  onTap: () => onToolChanged(CanvasTool.pen),
                  tooltip: 'Pen',
                ),
                _ToolButton(
                  icon: Icons.auto_fix_high,
                  isSelected: currentTool == CanvasTool.lasso,
                  onTap: () => onToolChanged(CanvasTool.lasso),
                  tooltip: 'Lasso',
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
                  tooltip: 'Clear',
                ),
                const Spacer(),
                if (isRecognizing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.icon(
                    onPressed: onConvert,
                    icon: const Icon(Icons.translate, size: 18),
                    label: const Text('Convert'),
                  ),
              ],
            ),
            // Bottom row: Colors & Width
            Row(
              children: [
                // Color picker
                ...[
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                ].map((color) => _ColorDot(
                  color: color,
                  isSelected: currentColor == color,
                  onTap: () => onColorChanged(color),
                )),
                const SizedBox(width: 16),
                // Stroke width slider
                Expanded(
                  child: Slider(
                    value: strokeWidth,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: strokeWidth.toStringAsFixed(1),
                    onChanged: onStrokeWidthChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    return IconButton(
      icon: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      onPressed: onTap,
      tooltip: tooltip,
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1))
          : null,
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
