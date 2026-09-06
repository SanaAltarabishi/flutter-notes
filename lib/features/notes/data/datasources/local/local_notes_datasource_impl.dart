import 'package:freenotes_app/features/notes/data/datasources/local/local_notes_datasource.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/book_model.dart';
import '../../models/content_block_model.dart';
import '../../models/page_model.dart';
import 'database_helper.dart';

class LocalNotesDataSourceImpl implements LocalNotesDataSource {
  final DatabaseHelper dbHelper;

  LocalNotesDataSourceImpl(this.dbHelper);
//_______________________________________
//books(5 funct):
  @override
  Future<List<BookModel>> getBooks() async {
    final db = await dbHelper.database;
    final maps = await db.query(
        'books', //~: SELECT * FROM books;//todo: what about the keys?
        orderBy: 'updated_at DESC'); //يعني من الأكبر للأصغر
    return maps.map((m) => BookModel.fromMap(m)).toList();
/*
List<Map>
   ↓ map()
Iterable<BookModel>
   ↓ toList()
List<BookModel>
*/
  }
//_______________________________________

  @override
  Future<BookModel?> getBook(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
/*
why not write the value directly?as this :
where: "id = '$id'"
rather than :
where: 'id = ?',
whereArgs: [id],
use whereArgs is the correct way with sqflite
because it separates the values from the SQL text
and helps avoid SQL injection/escaping issues.
*/
    if (maps.isEmpty) return null;
    return BookModel.fromMap(maps.first); //BookModel.fromMap(maps[0]);
  }
//_______________________________________

  @override
  Future<void> insertBook(BookModel book) async {
    final db = await dbHelper.database;
    await db.insert('books', book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
//conflict: if a book with the same id already exists,
// it will be replaced with the new one.
  }
//_______________________________________

  @override
  Future<void> updateBook(BookModel book) async {
    final db = await dbHelper.database;
    await db
        .update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }
//_______________________________________

  @override
  Future<void> deleteBook(String id) async {
    final db = await dbHelper.database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

//_______________________________________
//pages :
  @override
  Future<List<PageModel>> getPages(String bookId) async {

    final db = await dbHelper.database;
    final maps = await db.query(
      'pages',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'order_index ASC',
    );
    return maps.map((m) => PageModel.fromMap(m)).toList();
  }

//_______________________________________
  @override
  Future<PageModel?> getPage(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('pages', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return PageModel.fromMap(maps.first);
  }

//_______________________________________
  @override
  Future<void> insertPage(PageModel page) async {
    final db = await dbHelper.database;
    await db.insert('pages', page.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//_______________________________________
  @override
  Future<void> updatePage(PageModel page) async {
    final db = await dbHelper.database;
    await db
        .update('pages', page.toMap(), where: 'id = ?', whereArgs: [page.id]);
  }

//_______________________________________
  @override
  Future<void> updatePageWithBlocks(
    PageModel page,
    List<ContentBlockModel> blocks,
  ) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'pages',
        page.toMap(),
        where: 'id = ?',
        whereArgs: [page.id],
      );

      await txn.delete(
        'content_blocks',
        where: 'page_id = ?',
        whereArgs: [page.id],
      );

      for (final block in blocks) {
        await txn.insert(
          'content_blocks',
          block.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

//_______________________________________
  @override
  Future<void> deletePage(String id) async {
    final db = await dbHelper.database;
    await db.delete('pages', where: 'id = ?', whereArgs: [id]);
  }

//_______________________________________
  @override
  Future<int> getNextPageOrderIndex(String bookId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(MAX(order_index), -1) + 1 AS next_order
    FROM pages
    WHERE book_id = ?
    ''',
      [bookId],
    );

/*
COALESCE(MAX(order_index), -1)
معناها ببساطة:
لو MAX(order_index) رجعت NULL، استخدم -1 بدلها.
ليه ممكن ترجع NULL؟
لما الـ Book مفيهوش أي Pages أصلًا.

*/

    return result.first['next_order'] as int;
  }

//_______________________________________
//blocks :
  @override
  Future<List<ContentBlockModel>> getBlocks(String pageId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'content_blocks',
      where: 'page_id = ?',
      whereArgs: [pageId],
      orderBy: 'order_index ASC',
    );
    return maps.map((m) => ContentBlockModel.fromMap(m)).toList();
  }
//_______________________________________

  @override
  Future<void> insertBlock(ContentBlockModel block) async {
    final db = await dbHelper.database;
    await db.insert('content_blocks', block.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
//_______________________________________

  @override
  Future<void> updateBlock(ContentBlockModel block) async {
    final db = await dbHelper.database;
    await db.update('content_blocks', block.toMap(),
        where: 'id = ?', whereArgs: [block.id]);
  }
//_______________________________________

  @override
  Future<void> deleteBlock(String id) async {
    final db = await dbHelper.database;
    await db.delete('content_blocks', where: 'id = ?', whereArgs: [id]);
  }

//_______________________________________
  @override
  Future<void> updateBlockOrder(String pageId, List<String> blockIds) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
/*  مجموعة من عمليات الـ Database يتم التعامل معها كوحدة واحدة.
 يعني إما:
كل العمليات تنجح ✅
أو لو حصل failure:
العمليات كلها يتم rollback لها ❌
 */
      for (int i = 0; i < blockIds.length; i++) {
        await txn.update(
          'content_blocks',
          {'order_index': i},
          where: 'id = ? AND page_id = ?',
          whereArgs: [blockIds[i], pageId],
        );
      }
    });
  }
}
