import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/page.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class CreatePageParams {
  final String bookId;
  const CreatePageParams(this.bookId);
}

//_________________________________________________
class CreatePage implements UseCase<NotePage, CreatePageParams> {
  final NotesRepository repository;

  CreatePage(this.repository);

  @override
  Future<Either<Failure, NotePage>> call(CreatePageParams params) async {
    final orderResult = await repository.getNextPageOrderIndex(params.bookId);

    return orderResult.fold((failure) => Left(failure), (orderIndex) {
      final now = DateTime.now();

      final page = NotePage(
        id: now.millisecondsSinceEpoch.toString(),
        bookId: params.bookId,
        orderIndex: orderIndex,
        createdAt: now,
        updatedAt: now,
        blocks: const [],
      );

      return repository.createPage(page);
    });
  }
}
//todo :in create book we move the DateTime into the useCase,but here we have the order so we couldn't
//todo > fix it and make them with the same approach in the entir app !
