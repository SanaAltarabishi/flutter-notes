import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/page.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/repositories/handwriting_recognition_repository.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/local/local_notes_datasource.dart';
import '../datasources/remote/myscript_remote_datasource.dart';
import '../models/book_model.dart';
import '../models/content_block_model.dart';
import '../models/page_model.dart';

class NotesRepositoryImpl
    implements NotesRepository, HandwritingRecognitionRepository {
  final LocalNotesDataSource localDataSource;
  final MyScriptRemoteDataSource remoteDataSource;

  NotesRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });
//___________________________________________________
// BOOKS :
  @override
  Future<Either<Failure, List<Book>>> getBooks() async {
    try {
      final models = await localDataSource.getBooks();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load books: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, Book>> getBook(String id) async {
    try {
      final model = await localDataSource.getBook(id);
      if (model == null) return const Left(CacheFailure('Book not found'));
      //todo : we could do it in the ui and make it in another type
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load book: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, Book>> createBook(Book book) async {
    try {
      final modelBook = BookModel.fromEntity(book);
      await localDataSource.insertBook(modelBook);
      return Right(book);
    } catch (e) {
      return Left(CacheFailure('Failed to create book: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, void>> updateBook(Book book) async {
    try {
      await localDataSource.updateBook(BookModel.fromEntity(book));
      print(book.coverColorValue);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update book: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, void>> deleteBook(String id) async {
    try {
      await localDataSource.deleteBook(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete book: $e'));
    }
  }

//___________________________________________________
//?PAGES :
  @override
  Future<Either<Failure, List<NotePage>>> getPages(String bookId) async {
    try {
      final pageModels = await localDataSource.getPages(bookId);
      final pages = <NotePage>[];
      for (final pageModel in pageModels) {
        final blockModels = await localDataSource.getBlocks(pageModel.id);
        pages.add(pageModel.toEntity(blockModels: blockModels));
      }
      return Right(pages);
    } catch (e) {
      return Left(CacheFailure('Failed to load pages: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, NotePage>> getPage(String id) async {
    try {
      final pageModel = await localDataSource.getPage(id);
      if (pageModel == null) return const Left(CacheFailure('Page not found'));
      final blockModels = await localDataSource.getBlocks(id);
      return Right(pageModel.toEntity(blockModels: blockModels));
    } catch (e) {
      return Left(CacheFailure('Failed to load page: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, NotePage>> createPage(
    NotePage page,
  ) async {
    try {
      //   final existingPages = await localDataSource.getPages(bookId);
      //   final now = DateTime.now();
      //   final page = PageModel(
      //     id: now.millisecondsSinceEpoch.toString(),
      //     bookId: bookId,
      //     orderIndex: existingPages.length,
      //     createdAtMillis: now.millisecondsSinceEpoch,
      //     updatedAtMillis: now.millisecondsSinceEpoch,
      //   );
      //   await localDataSource.insertPage(page);
      final model = PageModel.fromEntity(page);

      await localDataSource.insertPage(model);

      return Right(page);
    } catch (e) {
      return Left(CacheFailure('Failed to create page: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, void>> updatePage(NotePage page) async {
    try {
      // await localDataSource.updatePage(PageModel.fromEntity(page));
      // // Also save blocks
      // for (final block in page.blocks) {
      //   await localDataSource.insertBlock(ContentBlockModel.fromEntity(block));
      // }
      final pageModel = PageModel.fromEntity(page);

      final blockModels =
          page.blocks.map(ContentBlockModel.fromEntity).toList();

      await localDataSource.updatePageWithBlocks(
        pageModel,
        blockModels,
      );

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update page: $e'));
    }
  }
//___________________________________________________

  @override
  Future<Either<Failure, void>> deletePage(String id) async {
    try {
      await localDataSource.deletePage(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete page: $e'));
    }
  }

//___________________________________________________
  @override
  Future<Either<Failure, int>> getNextPageOrderIndex(
    String bookId,
  ) async {
    try {
      final orderIndex = await localDataSource.getNextPageOrderIndex(bookId);
      return Right(orderIndex);
    } catch (e) {
      return Left(
        CacheFailure(
          'Failed to get next page order index: $e',
        ),
      );
    }
  }

//___________________________________________________
// BLOCKS
  @override
  Future<Either<Failure, List<ContentBlock>>> getBlocks(String pageId) async {
    try {
      final models = await localDataSource.getBlocks(pageId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load blocks: $e'));
    }
  }

//___________________________________________________
  @override
  Future<Either<Failure, void>> saveBlock(ContentBlock block) async {
    try {
      await localDataSource.insertBlock(ContentBlockModel.fromEntity(block));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save block: $e'));
    }
  }

//___________________________________________________
  @override
  Future<Either<Failure, void>> deleteBlock(String id) async {
    try {
      await localDataSource.deleteBlock(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete block: $e'));
    }
  }

//___________________________________________________
  @override
  Future<Either<Failure, void>> reorderBlocks(
      String pageId, List<String> blockIds) async {
    try {
      await localDataSource.updateBlockOrder(pageId, blockIds);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to reorder blocks: $e'));
    }
  }

//___________________________________________________
// RECOGNITION
  @override
  Future<Either<Failure, String>> recognizeText(
    List<Stroke> strokes,
    String language,
  ) {
    return _handleRecognition(
      () => remoteDataSource.recognizeText(
        strokes,
        language,
      ),
    );
  }

//___________________________________________________
  @override
  Future<Either<Failure, String>> recognizeShape(
    List<Stroke> strokes,
  ) {
    return _handleRecognition(
      () => remoteDataSource.recognizeShape(strokes),
    );
  }
//___________________________________________________

  Future<Either<Failure, String>> _handleRecognition(
    Future<String> Function() action,
  ) async {
    try {
      final result = await action();

      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on RecognitionException catch (e) {
      return Left(RecognitionFailure(e.message));
    }
  }
}
