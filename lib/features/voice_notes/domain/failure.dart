// إذا عندك Failure جاهز بالمشروع، استبدلي هاد الملف فيه.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class PermissionFailure extends Failure {
  const PermissionFailure() : super('لازم تسمحي للتطبيق باستخدام المايكروفون');
}

class RecordingFailure extends Failure {
  const RecordingFailure([super.message = 'تعذّر التسجيل']);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('ما في اتصال بالإنترنت');
}

class RateLimitFailure extends Failure {
  const RateLimitFailure() : super('وصلتي للحد المجاني، جربي بعد شوي');
}

class TranscriptionFailure extends Failure {
  const TranscriptionFailure([super.message = 'تعذّر تحويل الصوت لنص']);
}

class RegionBlockedFailure extends Failure {
  const RegionBlockedFailure()
      : super('Groq غير متاح من منطقتك — شغّلي VPN وجربي مرة ثانية');
}

class ServiceUnreachableFailure extends Failure {
  const ServiceUnreachableFailure()
      : super('تعذّر الوصول للخدمة — ممكن تكون محجوبة، جربي VPN');
}
