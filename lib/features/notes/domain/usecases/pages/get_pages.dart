import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/page.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class GetPagesParams {
  final String bookId;
  const GetPagesParams(this.bookId);
}
//_________________________________________________
class GetPages implements UseCase<List<NotePage>, GetPagesParams> {
  final NotesRepository repository;

  GetPages(this.repository);

  @override
  Future<Either<Failure,List<NotePage>>> call(GetPagesParams params) async {
    return await repository.getPages(params.bookId);
  }
}
