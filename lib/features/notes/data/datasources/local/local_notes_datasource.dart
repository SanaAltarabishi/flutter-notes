import '../../models/book_model.dart';
import '../../models/content_block_model.dart';
import '../../models/page_model.dart';

abstract class LocalNotesDataSource {
  Future<List<BookModel>> getBooks();
  Future<BookModel?> getBook(String id);
  Future<void> insertBook(BookModel book);
  Future<void> updateBook(BookModel book);
  Future<void> deleteBook(String id);

  Future<List<PageModel>> getPages(String bookId);
  Future<PageModel?> getPage(String id);
  Future<void> insertPage(PageModel page);
  Future<void> updatePage(PageModel page);
  Future<void> updatePageWithBlocks(
    PageModel page,
    List<ContentBlockModel> blocks,
  );
  Future<void> deletePage(String id);
Future<int> getNextPageOrderIndex(String bookId);

  Future<List<ContentBlockModel>> getBlocks(String pageId);
  Future<void> insertBlock(ContentBlockModel block);
  Future<void> updateBlock(ContentBlockModel block);
  Future<void> deleteBlock(String id);
  Future<void> updateBlockOrder(String pageId, List<String> blockIds);
}
