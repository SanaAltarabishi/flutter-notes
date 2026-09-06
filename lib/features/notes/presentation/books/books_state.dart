import '../../../../core/errors/failures.dart';
import '../../domain/entities/book.dart';

class BooksState {
  final List<Book> books;
  final Failure? error;
  const BooksState({
    this.books = const [],
    this.error,
  });

  BooksState copyWith({
    List<Book>? books,
    Failure? error,
    bool clearError = false,
  }) {
    return BooksState(
      books: books ?? this.books,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
/*
                 BooksState
                     │
                     │
             represents the UI state
                     │
                     ▼
              ┌─────────────┐
              │    books    │
              │             │
              │ [Book,Book] │
              └─────────────┘
                     │
                     │
                copyWith()
                     │
                     ▼
             New BooksState

___________________________________________
SQLite
  │
  ↓
BookModel
  │
  │ mapping
  ↓
Book
  │
  │ used by
  ↓
BooksState
  │
  ↓
UI
____________________________________________
BLOC :
UI
 ↓
Event
 ↓
Bloc
 ↓ emit()
State
 ↓
UI
____________________________________________
Rivepod :
UI
 ↓
Notifier method
 ↓
Notifier
 ↓ state= ....
State
 ↓
UI

 */
