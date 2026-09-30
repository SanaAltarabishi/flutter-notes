import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/books/widgets/retry_widget.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/canvas_page.dart';
import 'package:freenotes_app/features/notes/presentation/pages/pages_provider.dart';
import 'package:freenotes_app/features/notes/presentation/pages/widgets/page_card.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';

class PagesPage extends ConsumerWidget {
  final Book book;

  const PagesPage({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(
      pagesProvider(book.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        centerTitle: true,
      ),
      body: pagesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return RetryWidget.fromFailure(
            error as Failure,
            onRetry: () {
              // Refresh the pages
              //   ref.read(pagesProvider(book.id).notifier).refresh();
            },
          );
        },
        data: (state) {
          if (state.pages.isEmpty) {
            return const _EmptyPagesView();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.pages.length,
            itemBuilder: (context, index) {
              final page = state.pages[index];

              return PageCard(
                page: page,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CanvasPage(
                        pageId: page.id,
                      ),
                    ),
                  );
                },
                onDelete: () {
                  _confirmDelete(
                    context,
                    ref,
                    book.id,
                    page.id,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(pagesProvider(book.id).notifier).addPage();
        },
        icon: const Icon(Icons.add),
        label: const Text('New page'),
      ),
    );
  }
}

//____________
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String bookId,
  String pageId,
) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete page?'),
        content: const Text(
          'This page and its drawings will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true || !context.mounted) {
    return;
  }

  await ref.read(pagesProvider(bookId).notifier).deletePage(pageId);
}

//_____________________
class _EmptyPagesView extends StatelessWidget {
  const _EmptyPagesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No pages yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first page and start writing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
