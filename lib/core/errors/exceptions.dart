class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

class RecognitionException implements Exception {
  final String message;

  RecognitionException(this.message);
}