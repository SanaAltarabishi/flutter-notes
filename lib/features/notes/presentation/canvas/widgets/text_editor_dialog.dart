import 'package:flutter/material.dart';

class TextEditorDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String confirmLabel;

  const TextEditorDialog({
    super.key,
    required this.title,
    required this.initialText,
    required this.confirmLabel,
  });

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'Type something...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

//___________________________
Future<void> showTextDialog({
  required String title,
  required String initial,
  required String confirmLabel,
  required ValueChanged<String> onSubmit,
  required BuildContext context,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => TextEditorDialog(
      title: title,
      initialText: initial,
      confirmLabel: confirmLabel,
    ),
  );

  if (result != null) {
    onSubmit(result);
  }
}
