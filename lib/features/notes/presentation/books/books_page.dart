import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import 'package:freenotes_app/core/widgets/app_background.dart';
import 'package:freenotes_app/core/widgets/staggered_fade_slide.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../presentation/pages/pages_page.dart';
import 'books_provider.dart';
import 'widgets/book_card.dart';
import 'widgets/book_form_dialog.dart';
import 'widgets/delete_book_dialog.dart';
import 'widgets/retry_widget.dart';
import 'widgets/book_options_sheet.dart';
import '../../../../core/widgets/expandable_search_app_bar.dart';

class BooksPage extends ConsumerStatefulWidget {
  const BooksPage({super.key});

  @override
  ConsumerState<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends ConsumerState<BooksPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
      extendBodyBehindAppBar: true,
      appBar: ExpandableSearchAppBar(
        title: const Text(AppStrings.myBooks),
        hintText: AppStrings.searchBooks,
        backgroundColor: AppColors.transparent,
        onQueryChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
          ref.read(booksProvider.notifier).search(query);
        },
      ),
      body: AppBackground(
        safeArea: true,
        child: Column(
          children: [
            Expanded(
              child: booksAsync.when(
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
                    return Center(
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? AppStrings.emptyBook
                            : AppStrings.noBooksMatch,
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic));

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(slide),
                          child: child,
                        ),
                      );
                    },
                    child: _BooksGrid(
                      key: ValueKey(
                        state.books.map((book) => book.id).join('|'),
                      ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    super.key,
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

        return StaggeredFadeSlide(
          index: index,
          child: GestureDetector(
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
          ),
        );
      },
    );
  }
}
