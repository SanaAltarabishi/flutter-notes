import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/notes_repository.dart';

class DeletePageParams {
  final String id;

  const DeletePageParams(this.id);
}

//_________________________________________________
class DeletePage implements UseCase<void, DeletePageParams> {
  final NotesRepository repository;

  DeletePage(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePageParams params) async {
    return await repository.deletePage(params.id);
  }
}
