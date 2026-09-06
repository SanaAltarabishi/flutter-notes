import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/content_block.dart';
import '../../repositories/notes_repository.dart';

class GetBlocksParams {
  final String pageId;
  const GetBlocksParams(this.pageId);
}

class GetBlocks implements UseCase<List<ContentBlock>, GetBlocksParams> {
  final NotesRepository repository;
  GetBlocks(this.repository);

  @override
  Future<Either<Failure, List<ContentBlock>>> call(GetBlocksParams params) {
    return repository.getBlocks(params.pageId);
  }
}
