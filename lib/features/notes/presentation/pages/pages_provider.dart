import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/features/notes/presentation/pages/page_state.dart';
import '../../domain/usecases/pages/create_page.dart';
import '../../domain/usecases/pages/get_pages.dart';
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

  Future<void> addPage() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final createPage = ref.read(createPageUseCaseProvider);
    final result = await createPage(CreatePageParams(bookId));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      (page) => AsyncData(
          current.copyWith(pages: [...current.pages, page], clearError: true)),
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
