import '../../../domain/entities/stroke.dart';

abstract class MyScriptRemoteDataSource {
  Future<String> recognizeText(
      List<Stroke> strokes, String language);
  Future< String> recognizeShape(List<Stroke> strokes);
}
