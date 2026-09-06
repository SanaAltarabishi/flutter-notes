import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/stroke.dart';

abstract class HandwritingRecognitionRepository {
  Future<Either<Failure, String>> recognizeText(
      List<Stroke> strokes, String language);
  Future<Either<Failure, String>> recognizeShape(List<Stroke> strokes);
}
