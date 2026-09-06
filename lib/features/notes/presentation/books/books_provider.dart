import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/books/create_book.dart';
import '../../domain/usecases/books/delete_book.dart';
import '../../domain/usecases/books/update_book.dart';
import 'books_state.dart';
import '../providers/core_providers.dart';

final booksProvider =
    AsyncNotifierProvider<BooksNotifier, BooksState>(BooksNotifier.new);

//___________________________________________________
class BooksNotifier extends AsyncNotifier<BooksState> {
  //depend of the build , when we open the ui we need to get the books from the database and show them in the ui
  //so its asyncronous operation so we need to use asyncNotifier
  @override
  Future<BooksState> build() async {
//build() = "جهّزلي الـ initial state"
//build() it's the start point of the Provider.
//when Riverpod needs the booksProvider for the first time, it creates the Notifier and calls build() to get the initial state.
    final getBooks = ref.read(getBooksUseCaseProvider);
    final Either<Failure, List<Book>> result = await getBooks(const NoParams());
    //await means : wait for the result of the getBooks function to be returned before continuing with the rest of the code.
    //This is necessary because getBooks is an asynchronous function that may take some time to complete,
    //and we want to ensure that we have the result before proceeding.

    return result.fold(
      (failure) => throw failure, //Exception(failure.message),
      (books) => BooksState(books: books),
    );
  }

/*
build()
   │
   ▼
Get GetBooks UseCase
   │
   ▼
Execute GetBooks
   │
   ▼
Repository
   │
   ▼
Database
   │
   ▼
Either<Failure, List<Book>>
   │
   ├───────────────┐
   │               │
 Failure          Books
   │               │
   ▼               ▼
throw           BooksState
   │               │
   ▼               ▼
AsyncError      AsyncData
 */
//___________________________________________________

  Future<void> refresh() async {
    //ref.read(booksProvider.notifier).refresh();
    state = const AsyncLoading();

    final getBooks = ref.read(getBooksUseCaseProvider);
    final result = await getBooks(const NoParams());

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (books) => AsyncData(BooksState(books: books)),
    );
  }

//___________________________________________________
/*
ما محتاجة ترجع أي قيمة لمين استدعاها — لأنه الطريقة يلي بيوصل فيها التغيير للـ UI مش عن طريق الـ return value، وإنما عن طريق تعديل state مباشرة جوا الدالة. رايفربود بيراقب state، مش الـ return value متاع refresh(). فمين ما استدعى refresh() (زي onRetry: () => ref.read(booksProvider.notifier).refresh())، هو بس بده "يشغّلها ويستنى تخلص"، وما بده أي قيمة راجعة منها — لهيك void هي الأنسب.

بالمقابل، build() لازم ترجع State فعلياً — لأنه هاي هي الطريقة الوحيدة يلي فيها رايفربود بيعرف شو الـ initial state (ما في state = ... جواها متل باقي الدوال، لأنه state أصلاً لسا مش موجودة لغاية ما build() ترجع قيمة).

 */

  Future<void> addBook(String title, int coverColorValue) async {
    if (title.trim().isEmpty) return;

    final createBook = ref.read(createBookUseCaseProvider);
    final Either<Failure, Book> result =
        await createBook(CreateBookParams(title, coverColorValue));

    final current = state.valueOrNull;
    if (current == null) return;

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      (book) => AsyncData(current.copyWith(
        books: [...current.books, book],
        // error: null,
        clearError: true,
      )),
    );
  }
//___________________________________________________

  Future<void> deleteBook(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final deleteBook = ref.read(deleteBookUseCaseProvider);
    final result = await deleteBook(DeleteBookParams(id));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      // مفيش استعلام جديد — بس فلترة القائمة الموجودة بالذاكرة
      (_) => AsyncData(current.copyWith(
        books: current.books.where((b) => b.id != id).toList(),
        clearError: true,
      )),
    );
  }

//___________________________________________________
  Future<void> updateBook(Book book) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updateBook = ref.read(updateBookUseCaseProvider);
    print('notifiere update ');
    final result = await updateBook(UpdateBookParams(book));

    state = result.fold(
      (failure) => AsyncData(current.copyWith(error: failure)),
      // نفس الفكرة: نستبدل الكتاب القديم بالجديد جوا القائمة، بدون إعادة تحميل
      (_) => AsyncData(current.copyWith(
        books: [
          for (final b in current.books)
            if (b.id == book.id) book else b,
        ],
        clearError: true,
      )),
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
/*
اسألي حالك بس سؤال واحد قبل ما تكتبي أي fold:
"لو هالعملية فشلت، هل لسا عندي بيانات قديمة صالحة أعرضها؟"
- لأ (أول تحميل / refresh كامل) → استخدمي throw failure (بـ build()) أو AsyncError(failure, ...) (بأي مكان تاني بتكتبي فيه state = ... مباشرة).
- أي ؟
إيه (فيه بيانات موجودة، بس فعل إضافي زي إضافة/حذف/تعديل فشل) → خليها AsyncData(current.copyWith(error: failure)) — يعني لسا AsyncData، بس حطيتي الـ Failure جوا الـ state نفسه.
*/
