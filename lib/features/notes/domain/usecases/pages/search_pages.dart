import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/page.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class SearchPages implements UseCase<List<NotePage>, SearchPagesParams> {
  final NotesRepository repository;

  SearchPages(this.repository);

  @override
  Future<Either<Failure, List<NotePage>>> call(SearchPagesParams params) {
    return repository.searchPages(params.bookId, params.query);
  }
}

class SearchPagesParams {
  final String bookId;
  final String query;

  const SearchPagesParams(this.bookId, this.query);
}
