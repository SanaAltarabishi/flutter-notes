import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/content_block.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class SaveBlockParams {
  final ContentBlock block;
  const SaveBlockParams(this.block);
}
//_________________________________________________
class SaveBlock implements UseCase<void, SaveBlockParams> {
  final NotesRepository repository;

  SaveBlock(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveBlockParams params) async {
    return await repository.saveBlock(params.block);
  }
}
