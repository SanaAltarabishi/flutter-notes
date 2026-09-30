# FreeNotes

FreeNotes is a Flutter handwriting note-taking application. It organizes notes as books and pages, provides a freeform canvas for pen input, and can convert selected handwriting into editable text through the MyScript Cloud API.

The application is currently an active prototype. The main writing flow is implemented, while a few declared capabilities and cross-platform targets still need finishing work. This README documents the code as it exists today, not an aspirational product specification.

## What It Does

- Creates, edits, colors, and deletes books.
- Creates and deletes pages inside a book.
- Provides a canvas with pen, highlighter, eraser, and lasso tools.
- Changes pen and highlighter colors and widths.
- Selects and moves saved blocks or live strokes.
- Adds text blocks to a page.
- Saves drawings as persistent ink blocks.
- Converts lasso-selected handwriting to text in Arabic or English.
- Shows recognized text for confirmation before saving it as a text block.
- Stores books, pages, and canvas content locally in SQLite.
- Uses Material 3 styling and Riverpod-based dependency injection.

## User Flow

```text
Home
  -> Books
      -> Pages
          -> Canvas
              -> Draw or add text
              -> Select handwriting with lasso
              -> Convert selected strokes
              -> Accept or discard recognition
```

The recognition flow is intentionally selection-based. The user chooses which strokes should be converted instead of sending the entire page to the recognition service. This reduces accidental recognition, keeps requests smaller, and gives the user control over mixed handwritten content.

## Requirements

- Flutter SDK with Dart 3 or newer.
- A device or emulator for the target platform.
- MyScript Cloud credentials for handwriting recognition.
- Internet access when recognition is requested.

The current storage implementation uses `sqflite`, so Android, iOS, and macOS are the practical supported platforms. Flutter runner folders also exist for Windows, Linux, and Web, but the current database setup is not configured for those platforms.

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run static analysis and tests:

```bash
flutter analyze
flutter test
```

Run the application without recognition:

```bash
flutter run
```

Run with MyScript recognition enabled:

```bash
flutter run \
  --dart-define=MYSCRIPT_APPLICATION_KEY=your-application-key \
  --dart-define=MYSCRIPT_HMAC_KEY=your-hmac-key
```

Build an Android release with recognition enabled:

```bash
flutter build apk --release \
  --dart-define=MYSCRIPT_APPLICATION_KEY=your-application-key \
  --dart-define=MYSCRIPT_HMAC_KEY=your-hmac-key
```

Do not commit real MyScript keys. `--dart-define` keeps credentials out of source control, but compile-time values can still be extracted from a distributed application. For a production release, put the recognition request behind a trusted server rather than shipping long-lived API credentials in the client.

## Architecture

The project uses a feature-first structure with a lightweight clean-architecture split:

```text
lib/
  app.dart
  main.dart
  core/
    constants/
    errors/
    usecases/
    utils/
  features/
    notes/
      data/
        datasources/
          local/
          remote/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        books/
        pages/
        canvas/
        providers/
  services/
```

### Responsibilities by layer

**Presentation** owns pages, widgets, Riverpod notifiers, and view state. It responds to user actions and renders state; it should not know how SQLite rows or HTTP payloads are built.

**Domain** contains entities, repository contracts, and use cases such as creating books, loading pages, saving blocks, and converting handwriting. It expresses application behavior without depending on Flutter widgets or database details.

**Data** implements the domain contracts. The local data source talks to SQLite, the remote data source talks to MyScript, models serialize data, and the repository coordinates those sources.

**Core** contains shared constants, failures, exceptions, and use-case abstractions used across features.

### Dependency flow

```text
Widget
  -> Riverpod Notifier
      -> Use Case
          -> Repository interface
              -> Repository implementation
                  -> Local SQLite data source
                  -> MyScript remote data source
```

The main dependency graph is assembled in `lib/features/notes/presentation/providers/core_providers.dart`.

## Why These Choices?

### Why Riverpod instead of widget-local state?

Books, pages, and canvas state outlive individual widgets and depend on asynchronous data sources. Riverpod makes those dependencies injectable, keeps state outside the widget tree, and gives each page or canvas a scoped provider keyed by its ID.

The project uses different notifier types for different jobs:

- `BooksNotifier` uses `AsyncNotifier` because loading books begins asynchronously.
- `PagesNotifier` uses a family notifier scoped by `bookId`.
- `CanvasNotifier` uses a family notifier scoped by `pageId`.

This is preferable to passing large mutable objects through several widget levels or placing all application state in one global notifier.

### Why use cases and repositories?

The UI should not decide whether a book comes from SQLite, a network service, or a future cache. Use cases provide small application operations, while repositories hide storage and transport details behind interfaces.

This adds a few files compared with calling SQLite directly from a widget, but it makes the core behavior easier to test, replace, and extend. It also keeps MyScript-specific request logic out of the canvas UI.

### Why SQLite instead of a remote database?

Notes need to be available without an account and, ideally, without an internet connection. SQLite provides local, structured, offline persistence with relationships between books, pages, and blocks.

A remote database could support synchronization and multi-device access, but it would introduce authentication, conflict resolution, network failure states, and a backend. Those are worthwhile future capabilities, not prerequisites for the local note-taking workflow.

### Why one `content_blocks` table with typed data?

Pages contain different kinds of objects: ink, text, and planned image content. A shared table stores their common position, size, ordering, and timestamps, while the `type` and JSON `data` fields hold type-specific details.

This makes new block types easier to add than creating a new table for every canvas object. The tradeoff is that JSON is less queryable and less strictly validated by SQLite than normalized columns would be.

### Why explicit `Either<Failure, T>` results?

The `fpdart` result style makes expected failures visible at the repository and use-case boundaries. The UI can render a failure deliberately instead of relying on exceptions to travel through asynchronous widget code. Exceptions are still used inside data sources where a low-level operation fails; repositories translate those failures into domain-level failures.

### Why MyScript Cloud?

Handwriting recognition is a specialized problem involving stroke timing, language models, layout, and script recognition. Using a dedicated recognition service avoids maintaining that engine inside the app and supports Arabic and English recognition.

The cost is network dependence, API credentials, request latency, and a third-party service dependency. Recognition is therefore treated as an explicit action with a pending result that the user can accept or discard.

## Persistence Model

The database is named `freenotes.db` and currently uses schema version 2.

```text
books
  id, title, created_at, updated_at, cover_color
      |
      +-- pages
            id, book_id, order_index, created_at, updated_at
                |
                +-- content_blocks
                      id, page_id, type, order_index,
                      x, y, width, height, data,
                      created_at, updated_at
```

Foreign keys use `ON DELETE CASCADE`, so deleting a book removes its pages and their content blocks. Dates are stored as integer millisecond timestamps because SQLite does not have a native `DateTime` type.

Database creation and migration live in `lib/features/notes/data/datasources/local/database_helper.dart`.

## Handwriting Recognition Details

Recognition is implemented by `MyScriptRemoteDataSourceImpl`:

1. The lasso selects live strokes on the canvas.
2. Stroke points are converted into MyScript `x`, `y`, and timing arrays.
3. The payload is JSON-encoded.
4. An SHA-512 HMAC is generated from the request body using the configured MyScript keys.
5. Dio sends a `POST` request to MyScript's `/recognize` endpoint.
6. The returned label is shown as pending text.
7. Accepting the result saves a `TextBlock`; discarding it leaves the original strokes untouched.

Configuration lives in `lib/core/constants/app_constants.dart`:

- Base URL: `https://cloud.myscript.com/api/v4.0/iink`
- Application key: `MYSCRIPT_APPLICATION_KEY`
- HMAC key: `MYSCRIPT_HMAC_KEY`
- Languages: `ar` and `en_US`

## Important Dependencies

| Package | Purpose |
| --- | --- |
| `flutter_riverpod` | State management and dependency injection |
| `sqflite` | Local SQLite persistence |
| `path_provider`, `path` | Database path resolution |
| `dio` | HTTP communication with MyScript |
| `crypto` | HMAC generation |
| `fpdart` | Explicit functional error results |
| `equatable` | Value equality for states and entities |
| `flex_color_picker` | Book cover color selection |
| `image_picker` | Declared for image workflows; not yet fully wired into the canvas |
| `pdf` | Declared for future PDF export |
| `share_plus` | Declared for future sharing workflows |

## Current Limitations

The repository is not yet a production-ready release. The most important known gaps are:

- The current widget test is still Flutter's default counter test and references `MyApp`, while the real root widget is `FreeNotesApp`.
- Some canvas state/provider names are inconsistent around selected block IDs and need cleanup before a clean analyzer run.
- `endStroke()` is currently empty; stroke points are still collected during drawing, but stroke-finalization behavior is unfinished.
- The Home page's Quick Note action is not wired to a workflow yet.
- Undo and redo currently cover live strokes, not all saved database blocks.
- Image blocks, PDF export, and sharing dependencies are not complete user-facing features.
- Shape recognition and the planned magic-selection tool are not complete.
- Android release signing currently uses the debug signing configuration and should be replaced before publishing.

These limitations are recorded here so contributors can tell the difference between an installed dependency, a domain model, and a finished feature.

## Useful Files

- `lib/main.dart`: application entry point.
- `lib/app.dart`: `ProviderScope`, Material 3 theme, and root page.
- `lib/features/notes/presentation/pages/home_page.dart`: book/page navigation entry point.
- `lib/features/notes/presentation/books/books_page.dart`: book management UI.
- `lib/features/notes/presentation/pages/pages_page.dart`: page management UI.
- `lib/features/notes/presentation/canvas/canvas_page.dart`: canvas screen.
- `lib/features/notes/presentation/canvas/canvas_provider.dart`: canvas mutations and interaction behavior.
- `lib/features/notes/data/datasources/local/database_helper.dart`: SQLite schema and migrations.
- `lib/features/notes/data/datasources/remote/myscript_remote_datasource_imp.dart`: MyScript payload, HMAC, and HTTP request.

## Contributing Workflow

Before opening a change:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Keep feature behavior in the notes feature, keep persistence and HTTP details in data sources, and expose new operations through domain use cases. When adding a dependency, document its purpose and verify that the corresponding user-facing workflow is actually connected.

```