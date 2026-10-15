import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import 'package:freenotes_app/features/notes/presentation/books/widgets/retry_widget.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/canvas_page.dart';
import 'package:freenotes_app/features/notes/presentation/pages/pages_provider.dart';
import 'package:freenotes_app/features/notes/presentation/pages/widgets/page_card.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/page.dart';

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
                onEditName: () => _editPageName(context, ref, book.id, page),
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
        onPressed: () => _createPage(context, ref, book.id),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newPage),
      ),
    );
  }
}

//____________
Future<void> _createPage(
  BuildContext context,
  WidgetRef ref,
  String bookId,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _PageNameDialog(title: AppStrings.nameYourPage),
  );

  if (name == null || !context.mounted) {
    return;
  }

  await ref.read(pagesProvider(bookId).notifier).addPage(name);
}

//____________
Future<void> _editPageName(
  BuildContext context,
  WidgetRef ref,
  String bookId,
  NotePage page,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _PageNameDialog(
      title: AppStrings.editPageName,
      initialName: page.name,
      confirmLabel: AppStrings.save,
    ),
  );

  if (name == null || !context.mounted) {
    return;
  }

  await ref
      .read(pagesProvider(bookId).notifier)
      .updatePageName(page, name);
}

//____________
class _PageNameDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String confirmLabel;

  const _PageNameDialog({
    required this.title,
    this.initialName = '',
    this.confirmLabel = AppStrings.create,
  });

  @override
  State<_PageNameDialog> createState() => _PageNameDialogState();
}

class _PageNameDialogState extends State<_PageNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
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
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: AppStrings.pageName,
            hintText: AppStrings.pageNameHint,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.enterPageName;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
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
        title: const Text(AppStrings.deletePage),
        content: const Text(
          AppStrings.deletePageMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
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
              AppStrings.noPagesYet,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.createFirstPage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
