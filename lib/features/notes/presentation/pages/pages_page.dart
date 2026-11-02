import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';
import 'package:freenotes_app/core/widgets/app_background.dart';
import 'package:freenotes_app/core/widgets/staggered_fade_slide.dart';
import 'package:freenotes_app/features/notes/presentation/books/widgets/retry_widget.dart';
import 'package:freenotes_app/features/notes/presentation/canvas/canvas_page.dart';
import 'package:freenotes_app/features/notes/presentation/pages/pages_provider.dart';
import 'package:freenotes_app/features/notes/presentation/pages/widgets/page_card.dart';
import 'package:freenotes_app/core/widgets/expandable_search_app_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/page.dart';

class PagesPage extends ConsumerStatefulWidget {
  final Book book;

  const PagesPage({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<PagesPage> createState() => _PagesPageState();
}

class _PagesPageState extends ConsumerState<PagesPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(
      pagesProvider(widget.book.id),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ExpandableSearchAppBar(
        title: Text(widget.book.title),
        hintText: AppStrings.searchPages,
        backgroundColor: AppColors.transparent,
        onQueryChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
          ref.read(pagesProvider(widget.book.id).notifier).search(query);
        },
      ),
      body: AppBackground(
        accentColor: Color(widget.book.coverColorValue),
        child: Column(
          children: [
            Expanded(
              child: pagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) {
                  return RetryWidget.fromFailure(
                    error as Failure,
                    onRetry: () {
                      ref
                          .read(pagesProvider(widget.book.id).notifier)
                          .search(_searchQuery);
                    },
                  );
                },
                data: (state) {
                  if (state.pages.isEmpty) {
                    return _searchQuery.trim().isEmpty
                        ? const _EmptyPagesView()
                        : const Center(
                            child: Text(AppStrings.noPagesMatch),
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
                    child: ListView.builder(
                      key: ValueKey(
                        state.pages.map((page) => page.id).join('|'),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.pages.length,
                      itemBuilder: (context, index) {
                        final page = state.pages[index];

                        return StaggeredFadeSlide(
                          index: index,
                          child: PageCard(
                            page: page,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CanvasPage(
                                    pageTitle: page.name,
                                    pageId: page.id,
                                  ),
                                ),
                              );
                            },
                            onEditName: () => _editPageName(
                              context,
                              ref,
                              widget.book.id,
                              page,
                            ),
                            onDelete: () {
                              _confirmDelete(
                                context,
                                ref,
                                widget.book.id,
                                page.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPage(context, ref, widget.book.id),
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

  await ref.read(pagesProvider(bookId).notifier).updatePageName(page, name);
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
