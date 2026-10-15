import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import 'package:freenotes_app/core/widgets/color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/book.dart';
import '../books_provider.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  final Book? existingBook; //todo : why we pass the entire object ?

  const BookFormDialog({
    super.key,
    this.existingBook,
  });

  bool get isEditing =>
      existingBook != null; //todo : why we using it like that ?

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
        ? AppColors.primary
        : Color(widget.existingBook!.coverColorValue);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    //todo: is it normal to have setstate with the riverpod ?
    setState(() {
      _selectedColor = color;
    });
  }

//__________________________________________________
  void _submit() {
    //todo: why the submit have this kind of logic ?
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

//__________________________________________________
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
            widget.isEditing ? AppStrings.editBook : AppStrings.createNewBook,
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
                AppStrings.bookTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: AppStrings.enterBookTitle,
                  prefixIcon: const Icon(
                    Icons.title_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        14), //todo : make the raduis the same
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                AppStrings.appearance,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ColorPicker(
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
          child: const Text(AppStrings.cancel),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(
            widget.isEditing ? Icons.check : Icons.add,
          ),
          label: Text(
            widget.isEditing ? AppStrings.save : AppStrings.create,
          ),
        ),
      ],
    );
  }
}
