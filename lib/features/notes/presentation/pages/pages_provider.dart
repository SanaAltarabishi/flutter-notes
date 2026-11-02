import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/pages/page_state.dart';
import '../../domain/entities/page.dart';
import '../../domain/usecases/pages/create_page.dart';
import '../../domain/usecases/pages/delete_page.dart';
import '../../domain/usecases/pages/get_pages.dart';
import '../../domain/usecases/pages/update_page.dart';
import '../../domain/usecases/pages/search_pages.dart';
import '../providers/core_providers.dart';

final pagesProvider =
    AsyncNotifierProvider.family<PagesNotifier, PagesState, String>(
  PagesNotifier.new,
);

//___________________________________________________
class PagesNotifier extends FamilyAsyncNotifier<PagesState, String> {
  late final String bookId;
  String _searchQuery = '';
  int _searchRequest = 0;

  @override
  Future<PagesState> build(String arg) async {
    bookId = arg;
    final getPages = ref.read(getPagesUseCaseProvider);
    final result = await getPages(GetPagesParams(bookId));
    return result.fold(
      (failure) => throw failure, //Exception(failure.message),
      (pages) => PagesState(pages: pages),
    );
  }
//___________________________________________________

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    _searchQuery = normalizedQuery;
    final request = ++_searchRequest;
    state = const AsyncLoading();

    final result = normalizedQuery.isEmpty
        ? await ref.read(getPagesUseCaseProvider)(GetPagesParams(bookId))
        : await ref.read(searchPagesUseCaseProvider)(
            SearchPagesParams(bookId, normalizedQuery),
          );

    if (request != _searchRequest) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (pages) => AsyncData(PagesState(pages: pages)),
    );
  }

  Future<void> addPage(String name) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final createPage = ref.read(createPageUseCaseProvider);
    final result = await createPage(CreatePageParams(bookId, name));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      (page) => AsyncData(current.copyWith(
        pages: _matchesSearch(page.name)
            ? [...current.pages, page]
            : current.pages,
        clearError: true,
      )),
    );
  }
//___________________________________________________

  Future<void> deletePage(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final deleteBook = ref.read(deletePageUseCaseProvider);
    final result = await deleteBook(DeletePageParams(id));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      // مفيش استعلام جديد — بس فلترة القائمة الموجودة بالذاكرة
      (_) => AsyncData(current.copyWith(
        pages: current.pages.where((p) => p.id != id).toList(),
        clearError: true,
      )),
    );
  }
//___________________________________________________

  Future<void> updatePageName(NotePage page, String name) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatePage = ref.read(updatePageUseCaseProvider);
    final result = await updatePage(
      UpdatePageParams(page.copyWith(name: name)),
    );

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      (_) => AsyncData(
        current.copyWith(
          pages: _updatedPages(current.pages, page.copyWith(name: name)),
          clearError: true,
        ),
      ),
    );
  }

  bool _matchesSearch(String name) {
    return _searchQuery.isEmpty ||
        name.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  List<NotePage> _updatedPages(List<NotePage> pages, NotePage updatedPage) {
    if (!_matchesSearch(updatedPage.name)) {
      return pages.where((item) => item.id != updatedPage.id).toList();
    }

    return [
      for (final item in pages)
        if (item.id == updatedPage.id) updatedPage else item,
    ];
  }

//___________________________________________________
  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(clearError: true));
    }
  }
}
