import 'package:freenotes_app/core/errors/failures.dart';
import '../../domain/entities/page.dart';

class PagesState {
  final List<NotePage> pages;
  final Failure? error;
  const PagesState({
    this.pages = const [],
    this.error,
  });

  PagesState copyWith({
    List<NotePage>? pages,
    Failure? error,
    bool clearError = false,
  }) {
    return PagesState(
        pages: pages ?? this.pages,
        error: clearError ? null : (error ?? this.error));
  }
}
