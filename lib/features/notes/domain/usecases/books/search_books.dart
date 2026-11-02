import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/book.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class SearchBooks implements UseCase<List<Book>, SearchBooksParams> {
  final NotesRepository repository;

  SearchBooks(this.repository);

  @override
  Future<Either<Failure, List<Book>>> call(SearchBooksParams params) {
    return repository.searchBooks(params.query);
  }
}

class SearchBooksParams {
  final String query;

  const SearchBooksParams(this.query);
}
