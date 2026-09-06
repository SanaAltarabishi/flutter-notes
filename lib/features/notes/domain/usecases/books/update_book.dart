import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/book.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class UpdateBookParams {
  final Book book;
  const UpdateBookParams(this.book);
}

//_________________________________________________
class UpdateBook implements UseCase<void, UpdateBookParams> {
  final NotesRepository repository;

  UpdateBook(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBookParams params) async {
    return await repository.updateBook(params.book);
  }
}
