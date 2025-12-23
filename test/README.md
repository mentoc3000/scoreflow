# ScoreFlow Tests

This directory contains comprehensive unit and integration tests for the ScoreFlow PDF viewer application.

## Test Structure

```
test/
├── features/
│   └── pdf_viewer/
│       └── bloc/
│           ├── annotation_bloc_test.dart
│           ├── pdf_viewer_bloc_test.dart
│           └── tab_manager_bloc_test.dart
└── widget_test.dart (default Flutter test)
```

## Running Tests

### Run all tests:
```bash
flutter test
```

### Run specific test file:
```bash
flutter test test/features/pdf_viewer/bloc/annotation_bloc_test.dart
```

### Run tests with coverage:
```bash
flutter test --coverage
```

### Generate coverage report (requires lcov):
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Coverage

### AnnotationBloc Tests (`annotation_bloc_test.dart`)
Tests for annotation management with undo/redo support:

- **Loading annotations**: Verifies annotations load from repository
- **Adding annotations**: Tests adding new annotations with debounced saves
- **Updating annotations**: Tests modifying existing annotations
- **Deleting annotations**: Tests removing annotations and clearing selection
- **Selection management**: Tests selecting and deselecting annotations
- **Add mode toggle**: Tests toggling annotation creation mode
- **Undo/Redo**: Tests undo/redo functionality using ReplayBloc
- **Debouncing**: Verifies multiple rapid changes only trigger one save
- **Error handling**: Tests graceful error handling for repository failures

**Key scenarios tested:**
- Debouncing prevents excessive saves during rapid annotation moves
- Selection clears when annotation is deleted
- Undo/redo works correctly with annotation history
- Save operations properly await completion before emitting state

### PdfViewerBloc Tests (`pdf_viewer_bloc_test.dart`)
Tests for PDF document viewing and navigation:

- **Recent files**: Loading and error handling for recent files list
- **Page navigation**: Next/prev page, page validation, boundary checks
- **Navigation history**: Bounded history (max 50 entries), back/forward navigation
- **Zoom controls**: Zoom in/out/reset, clamping to min/max values
- **Search**: Query changes, clearing, cancellation, result validation
- **Toggles**: Bookmark sidebar, distraction-free mode
- **Validation**: Page number bounds checking for all navigation types

**Key scenarios tested:**
- Navigation history doesn't grow unbounded
- Page numbers are validated before navigation
- Zoom levels are clamped to configured min/max
- Search properly clears when closed or query is empty
- Invalid page numbers in search results are caught

### TabManagerBloc Tests (`tab_manager_bloc_test.dart`)
Tests for multi-tab document management:

- **Tab restoration**: Loading saved tabs on startup
- **Opening tabs**: Adding new tabs, preventing duplicates
- **Closing tabs**: Removing tabs, creating home tab when empty
- **Switching tabs**: Changing active tab, validating existence
- **State persistence**: Saving/loading tab state (page, zoom, etc.)
- **Max tabs limit**: Preventing more than configured maximum tabs
- **Active tab management**: Switching to last tab when closing active

**Key scenarios tested:**
- Creates home tab when no saved tabs exist
- Switches to existing tab instead of opening duplicate
- Creates new home tab when closing the last tab
- Properly cleans up tab state when closing
- Enforces maximum tab limit (10 tabs)
- Persists all state changes to repository

## Testing Best Practices

1. **Use `blocTest`**: Leverages the bloc_test package for cleaner bloc testing
2. **Mock dependencies**: Uses mocktail for mocking repositories
3. **Test async operations**: Properly awaits debounced and async operations
4. **Verify side effects**: Checks that repository methods are called correctly
5. **Test error cases**: Ensures graceful handling of failures
6. **Test boundaries**: Validates edge cases like max values, empty states

## Dependencies

The tests use:
- `flutter_test`: Flutter's testing framework
- `bloc_test`: Testing utilities for blocs
- `mocktail`: Mocking library for Dart

## Continuous Integration

These tests should be run in CI/CD pipelines before merging any changes. All tests must pass before deployment.

## Adding New Tests

When adding new features:
1. Write tests first (TDD approach recommended)
2. Test happy path and error cases
3. Test boundary conditions
4. Test async operations properly await
5. Verify all state emissions
6. Check side effects (repository calls, etc.)

## Known Issues

None currently. All critical bugs identified in the code review have been fixed and are covered by tests.
