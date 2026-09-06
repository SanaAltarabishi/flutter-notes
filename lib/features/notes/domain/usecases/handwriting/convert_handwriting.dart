import 'package:fpdart/fpdart.dart';
import '../../../../../core/errors/failures.dart';
import '../../entities/stroke.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/handwriting_recognition_repository.dart';

class ConvertHandwritingParams {
  final List<Stroke> strokes;
  final String language;
  const ConvertHandwritingParams({
    required this.strokes,
    required this.language,
  });
}

//_________________________________________________
class ConvertHandwriting implements UseCase<String, ConvertHandwritingParams> {
  final HandwritingRecognitionRepository repository;

  ConvertHandwriting(this.repository);

  @override
  Future<Either<Failure, String>> call(ConvertHandwritingParams params) async {
    return await repository.recognizeText(params.strokes, params.language);
  }
}
