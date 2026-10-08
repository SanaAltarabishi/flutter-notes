import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/page.dart';
import '../../repositories/notes_repository.dart';

class UpdatePageParams {
  final NotePage page;

  const UpdatePageParams(this.page);
}

class UpdatePage implements UseCase<void, UpdatePageParams> {
  final NotesRepository repository;

  UpdatePage(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePageParams params) async {
    return repository.updatePage(params.page);
  }
}
