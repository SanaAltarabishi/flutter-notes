import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
//_______________________________________________
//if we request the database and it is not initialized, we will initialize it and return it.
//If it is already initialized, we will return the existing instance.
//it is kind of "Lazy Initialization", we don't open the database until we need it.
/*
await database
      │
      ▼
هل _database موجودة؟
      │
      └── لا
          │
          ▼
   _initDatabase()
          │
          ▼
 getDatabasesPath()
          │
          ▼
      dbPath
          │
          ▼
 join(dbPath, dbName)
          │
          ▼
         path
          │
          ▼
   openDatabase()
          │
          ▼
هل Database جديدة؟
      │
      ├── نعم
      │    │
      │    ▼
      │  _onCreate()
      │    │
      │    ├── CREATE books
      │    ├── CREATE pages
      │    └── CREATE content_blocks
      │
      ▼
  Database object
      │
      ▼
_database = Database
      │
      ▼
return Database

____________________________________
second time:
_database موجودة؟
      │
      └── نعم
          │
          ▼
   return _database


>>  we will not do :
getDatabasesPath()
openDatabase()
CREATE TABLE
 */

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

//_______________________________________________
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
/*
openDatabase
     │
     │ Database جديدة؟
     ▼
   نعم
     │
     ▼
_call _onCreate(...)

*/
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
//______________________________________________
Future<void> _onUpgrade(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2) {
    await db.execute('''
      ALTER TABLE books
      ADD COLUMN cover_color INTEGER NOT NULL
      DEFAULT 0xFF2196F3
    ''');
  }
}
//_______________________________________________
  Future<void> _onCreate(Database db, int version) async {
/*
books
┌────────┬──────────────┬────────────┬────────────┐────────────┐
│ id     │ title        │ created_at │ updated_at │cover_color
├────────┼──────────────┼────────────┼────────────┤────────────
│ ...    │ ...          │ ...        │ ...        │
└────────┴──────────────┴────────────┴────────────┘────────────

created_at INTEGER NOT NULL,becuase SQLite doesn't have DateTime type,
so we will store the timestamp as an integer (milliseconds since epoch) instead of a DateTime.
*/
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        cover_color INTEGER NOT NULL DEFAULT 0xFF2196F3
      )
    ''');
/*
Book
 ├── Page 1
 ├── Page 2
 └── Page 3
 _____________________________________
 ON DELETE CASCADE:
 if a book is deleted, all its pages will be automatically deleted as well.
 */
    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

/*
Book: "My Notes"
│
├── Page 1
│   │
│   ├── TextBlock
│   ├── InkBlock
│   └── ImageBlock
│
├── Page 2
│   │
│   ├── TextBlock
│   └── InkBlock
│
└── Page 3
    │
    └── ImageBlock
 */

    await db.execute('''
      CREATE TABLE content_blocks (
        id TEXT PRIMARY KEY,
        page_id TEXT NOT NULL,
        type TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        x REAL NOT NULL DEFAULT 0,
        y REAL NOT NULL DEFAULT 0,
        width REAL NOT NULL DEFAULT 0,
        height REAL NOT NULL DEFAULT 0,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');
  }

//_______________________________________________
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
