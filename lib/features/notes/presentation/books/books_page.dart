import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../presentation/pages/pages_page.dart';
import 'books_provider.dart';
import 'widgets/book_card.dart';
import 'widgets/book_form_dialog.dart';
import 'widgets/delete_book_dialog.dart';
import 'widgets/retry_widget.dart';
import 'widgets/book_options_sheet.dart';

class BooksPage extends ConsumerWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(booksProvider, (previous, next) {
      final error = next.valueOrNull?.error;

      if (error != null) {
        print(error.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
          ),
        );

        ref.read(booksProvider.notifier).clearError();
      }
    });
    final booksAsync = ref.watch(booksProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.myBooks),
      ),
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return RetryWidget.fromFailure(
            error as Failure,
            onRetry: () {
              ref.read(booksProvider.notifier).refresh();
            },
          );
        },
        data: (state) {
          if (state.books.isEmpty) {
            return const Center(
              child: Text(
                AppStrings.emptyBook,
              ),
            );
          }

          return _BooksGrid(
            books: state.books,
            onBookLongPress: (book) {
              _showBookOptions(
                context,
                ref,
                book,
              );
            },
            onBookEdit: (book) => _showBookForm(
              context,
              existingBook: book,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showBookForm(context);
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newBook),
      ),
    );
  }

//____________________________________________
  void _showBookForm(
    BuildContext context, {
    Book? existingBook,
  }) {
    showDialog(
      context: context,
      builder: (_) => BookFormDialog(
        existingBook: existingBook,
      ),
    );
  }

//____________________________________________
  void _showBookOptions(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return BookOptionsSheet(
          //   book: book,
          onEdit: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => BookFormDialog(
                existingBook: book,
              ),
            );
          },
          onDelete: () {
            Navigator.pop(context);
            _showDeleteConfirmation(
              context,
              ref,
              book,
            );
          },
        );
      },
    );
  }

//____________________________________________
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return DeleteBookDialog(
          book: book,
          onConfirm: () {
            ref.read(booksProvider.notifier).deleteBook(book.id);

            Navigator.pop(context);
          },
        );
      },
    );
  }
}

//____________________________________________
class _BooksGrid extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onBookLongPress;
  final ValueChanged<Book> onBookEdit;

  const _BooksGrid({
    required this.books,
    required this.onBookLongPress,
    required this.onBookEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        return GestureDetector(
          onLongPress: () => onBookLongPress(book),
          child: BookCard(
            title: book.title,
            createdAt: book.createdAt,
            coverColor: Color(book.coverColorValue),
            onEdit: () => onBookEdit(book),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PagesPage(
                    book: book,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
