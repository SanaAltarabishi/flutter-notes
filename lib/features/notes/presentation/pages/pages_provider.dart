import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/pages/page_state.dart';
import '../../domain/entities/page.dart';
import '../../domain/usecases/pages/create_page.dart';
import '../../domain/usecases/pages/delete_page.dart';
import '../../domain/usecases/pages/get_pages.dart';
import '../../domain/usecases/pages/update_page.dart';
import '../providers/core_providers.dart';

final pagesProvider =
    AsyncNotifierProvider.family<PagesNotifier, PagesState, String>(
  PagesNotifier.new,
);

//___________________________________________________
class PagesNotifier extends FamilyAsyncNotifier<PagesState, String> {
  late final String bookId;

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

  Future<void> addPage(String name) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final createPage = ref.read(createPageUseCaseProvider);
    final result = await createPage(CreatePageParams(bookId, name));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      (page) => AsyncData(
          current.copyWith(pages: [...current.pages, page], clearError: true)),
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
          pages: current.pages
              .map((item) => item.id == page.id ? page.copyWith(name: name) : item)
              .toList(),
          clearError: true,
        ),
      ),
    );
  }


//___________________________________________________
  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(clearError: true));
    }
  }
}
