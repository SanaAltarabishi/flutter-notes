import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/local_notes_datasource.dart';
import '../../data/datasources/local/local_notes_datasource_impl.dart';
import '../../data/datasources/remote/myscript_remote_datasource.dart';
import '../../data/datasources/remote/myscript_remote_datasource_imp.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/handwriting_recognition_repository.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/usecases/blocks/delete_block.dart';
import '../../domain/usecases/blocks/get_blocks.dart';
import '../../domain/usecases/blocks/save_block.dart';
import '../../domain/usecases/books/delete_book.dart';
import '../../domain/usecases/books/update_book.dart';
import '../../domain/usecases/handwriting/convert_handwriting.dart';
import '../../domain/usecases/books/create_book.dart';
import '../../domain/usecases/pages/create_page.dart';
import '../../domain/usecases/books/get_books.dart';
import '../../domain/usecases/pages/delete_page.dart';
import '../../domain/usecases/pages/get_pages.dart';

//CORE:
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});
//___________________________________________________
// DATA SOURCES
final localNotesDataSourceProvider = Provider<LocalNotesDataSource>((ref) {
  return LocalNotesDataSourceImpl(ref.watch(databaseHelperProvider));
});

final myScriptRemoteDataSourceProvider =
    Provider<MyScriptRemoteDataSource>((ref) {
  return MyScriptRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});
//___________________________________________________
//REPOSITORIES:
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl(
    localDataSource: ref.watch(localNotesDataSourceProvider),
    remoteDataSource: ref.watch(myScriptRemoteDataSourceProvider),
  );
});

final handwritingRecognitionRepositoryProvider =
    Provider<HandwritingRecognitionRepository>((ref) {
  return NotesRepositoryImpl(
    localDataSource: ref.watch(localNotesDataSourceProvider),
    remoteDataSource: ref.watch(myScriptRemoteDataSourceProvider),
  );
});
//___________________________________________________
//USE CASES:
//? books :
final getBooksUseCaseProvider = Provider<GetBooks>((ref) {
  return GetBooks(ref.watch(notesRepositoryProvider));
});

final createBookUseCaseProvider = Provider<CreateBook>((ref) {
  return CreateBook(ref.watch(notesRepositoryProvider));
});
final deleteBookUseCaseProvider = Provider<DeleteBook>((ref) {
  return DeleteBook(ref.watch(notesRepositoryProvider));
});

final updateBookUseCaseProvider = Provider<UpdateBook>((ref) {
  return UpdateBook(ref.watch(notesRepositoryProvider));
});
//_____________________________
//? pages:
final getPagesUseCaseProvider = Provider<GetPages>((ref) {
  return GetPages(ref.watch(notesRepositoryProvider));
});

final createPageUseCaseProvider = Provider<CreatePage>((ref) {
  return CreatePage(ref.watch(notesRepositoryProvider));
});

final deletePageUseCaseProvider = Provider<DeletePage>((ref) {
  return DeletePage(ref.watch(notesRepositoryProvider));
});

//_____________________________
// ? blocks :
final saveBlockUseCaseProvider = Provider<SaveBlock>((ref) {
  return SaveBlock(ref.watch(notesRepositoryProvider));
});

final getBlocksUseCaseProvider = Provider<GetBlocks>((ref) {
  return GetBlocks(ref.watch(notesRepositoryProvider));
});
final deleteBlockUseCaseProvider = Provider<DeleteBlock>((ref) {
  return DeleteBlock(ref.watch(notesRepositoryProvider));
});

// final reorderBlocksUseCaseProvider = Provider<ReorderBlocks>((ref) {
//   return ReorderBlocks(ref.watch(notesRepositoryProvider));
// });

//_____________________________
//? handwriting:
final convertHandwritingUseCaseProvider = Provider<ConvertHandwriting>((ref) {
  return ConvertHandwriting(
      ref.watch(handwritingRecognitionRepositoryProvider));
});
