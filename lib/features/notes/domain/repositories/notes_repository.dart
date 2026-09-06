import 'package:fpdart/fpdart.dart';
import 'package:freenotes_app/core/errors/failures.dart';
import '../entities/book.dart';
import '../entities/content_block.dart';
import '../entities/page.dart';

abstract class NotesRepository {
  // Books
  Future<Either<Failure, List<Book>>> getBooks();
  Future<Either<Failure, Book>> getBook(String id);
  Future<Either<Failure, Book>> createBook(Book book);
  Future<Either<Failure, void>> updateBook(Book book);
  Future<Either<Failure, void>> deleteBook(String id);

  // Pages
  Future<Either<Failure, List<NotePage>>> getPages(String bookId);
  Future<Either<Failure, NotePage>> getPage(String id);
  Future<Either<Failure, NotePage>> createPage(
    NotePage page,
  );
  Future<Either<Failure, void>> updatePage(NotePage page);
  Future<Either<Failure, void>> deletePage(String id);
  Future<Either<Failure, int>> getNextPageOrderIndex(
    String bookId,
  );

  // Content Blocks
  Future<Either<Failure, List<ContentBlock>>> getBlocks(String pageId);
  Future<Either<Failure, void>> saveBlock(ContentBlock block);
  Future<Either<Failure, void>> deleteBlock(String id);
  Future<Either<Failure, void>> reorderBlocks(
      String pageId, List<String> blockIds);
}
