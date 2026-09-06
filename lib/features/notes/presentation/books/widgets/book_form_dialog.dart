import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/book.dart';
import '../books_provider.dart';
import 'book_color_picker.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  final Book? existingBook;

  const BookFormDialog({
    super.key,
    this.existingBook,
  });

  bool get isEditing => existingBook != null;

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  late final TextEditingController _titleController;

  late Color _selectedColor;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.existingBook?.title ?? '',
    );

    _selectedColor = widget.existingBook == null
        ? Colors.blue
        : Color(widget.existingBook!.coverColorValue);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    final notifier = ref.read(booksProvider.notifier);

    if (widget.existingBook == null) {
      notifier.addBook(
        title,
        _selectedColor.value,
      );
    } else {
      print('here here ');
      notifier.updateBook(
        widget.existingBook!.copyWith(
          title: title,
          coverColorValue: _selectedColor.value,
          updatedAt: DateTime.now(),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isEditing ? Icons.edit_outlined : Icons.menu_book_outlined,
          ),
          const SizedBox(width: 10),
          Text(
            widget.isEditing ? 'Edit Book' : 'Create New Book',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book title',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Enter book title',
                  prefixIcon: const Icon(
                    Icons.title_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              BookColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: _selectColor,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        20,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(
            widget.isEditing ? Icons.check : Icons.add,
          ),
          label: Text(
            widget.isEditing ? 'Save' : 'Create',
          ),
        ),
      ],
    );
  }
}
