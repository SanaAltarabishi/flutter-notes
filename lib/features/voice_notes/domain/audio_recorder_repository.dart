import 'package:fpdart/fpdart.dart';

import 'failure.dart';

abstract interface class AudioRecorderRepository {
  Future<Either<Failure, Unit>> start();

  /// يوقف التسجيل ويرجّع مسار الملف.
  Future<Either<Failure, String>> stop();

  Future<void> cancel();
}
