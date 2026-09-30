import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/notes_repository.dart';

class DeleteBlockParams {
  final String id;
  const DeleteBlockParams(this.id);
}

class DeleteBlock implements UseCase<void, DeleteBlockParams> {
  final NotesRepository repository;
  DeleteBlock(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBlockParams params) {
    return repository.deleteBlock(params.id);
  }
}