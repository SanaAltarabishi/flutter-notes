# freenotes_app

```
             USER
              │
              │ draws
              ▼
          Stroke[]
              │
              ▼
       Repository / UseCase
              │
              ▼
   MyScriptRemoteDataSource
              │
       ┌──────┴───────┐
       │              │
       ▼              ▼
 buildPayload      generateHmac
       │              │
       └──────┬───────┘
              ▼
           Dio POST
              │
              ▼
         MyScript API
              │
              ▼
          Response
              │
       ┌──────┴──────┐
       │             │
    success        failure
       │             │
       ▼             ▼
   Right(text)     Left(Failure)
```
----------------
BooksState = البيانات

BooksNotifier = الشخص المسؤول عن تغيير البيانات

----------------
```dart
final booksProvider =
    AsyncNotifierProvider<BooksNotifier, BooksState>(
      BooksNotifier.new,
    );
```
يا Riverpod، أنا عندي BooksNotifier مسؤول عن BooksState.
اعمل لي Provider أقدر أوصل من خلاله للـ Notifier والـ State.
------------------
```

                  booksProvider
                       │
                       ↓
            AsyncValue<BooksState>
              /        |        \
             /         |         \
        Loading       Data       Error
                       │
                       ↓
                  BooksState
                    /     \
                   /       \
                books      error

```