import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/books/books_provider.dart';
import 'package:freenotes_app/features/notes/presentation/books/widgets/retry_widget.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/canvas_page.dart';
import 'package:freenotes_app/features/notes/presentation/pages/pages_provider.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';

class PagesPage extends ConsumerWidget {
  final Book book;
  const PagesPage({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(pagesProvider(book.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        centerTitle: true,
      ),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => RetryWidget.fromFailure(
          err as Failure,
          onRetry: () => ref.read(booksProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.pages.isEmpty) {
            return const Center(child: Text('No pages yet. Add one!'));
          }
          return ListView.builder(
            itemCount: state.pages.length,
            itemBuilder: (context, index) {
              final page = state.pages[index];
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Page ${page.orderIndex + 1}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CanvasPage(pageId: page.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(pagesProvider(book.id).notifier).addPage(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
