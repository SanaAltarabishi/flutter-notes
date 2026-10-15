import 'package:equatable/equatable.dart';
import 'package:freenotes_app/core/constants/app_strings.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = AppStrings.serverError]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = AppStrings.cacheError]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = AppStrings.networkError]);
}

class RecognitionFailure extends Failure {
  const RecognitionFailure([super.message = AppStrings.recognitionFailed]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = AppStrings.invalidInput]);
}
