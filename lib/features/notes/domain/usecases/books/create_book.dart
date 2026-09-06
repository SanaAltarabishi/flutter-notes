import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/book.dart';
import '../../repositories/notes_repository.dart';
import '../../../../../core/usecases/usecase.dart';

class CreateBookParams {
  final String title;
  final int coverColorValue;
  const CreateBookParams(this.title, this.coverColorValue);
}

//_________________________________________________
class CreateBook implements UseCase<Book, CreateBookParams> {
  final NotesRepository repository;

  CreateBook(this.repository);

  @override
  Future<Either<Failure, Book>> call(CreateBookParams params) async {
    final now = DateTime.now(); //todo : make sure if this is the best practice
    final book = Book(
      id: now.millisecondsSinceEpoch.toString(),
      title: params.title,
      coverColorValue: params.coverColorValue,
      createdAt: now,
      updatedAt: now,
    );

    return await repository.createBook(book);
  }
}
