import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class DeleteBookParams {
  final String id;
  const DeleteBookParams(this.id);
}

//_________________________________________________
class DeleteBook implements UseCase<void, DeleteBookParams> {
  final NotesRepository repository;

  DeleteBook(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBookParams params) async {
    return await repository.deleteBook(params.id);
  }
}
