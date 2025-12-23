import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/pdf_viewer_bloc.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/pdf_viewer_event.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/pdf_viewer_state.dart';
import 'package:scoreflow/features/pdf_viewer/models/recent_file.dart';
import 'package:scoreflow/features/pdf_viewer/repositories/recent_files_repository.dart';

class MockRecentFilesRepository extends Mock implements RecentFilesRepository {}
class MockPdfDocument extends Mock implements PdfDocument {}
class MockPdfPage extends Mock implements PdfPage {}

/// Helper to create a mock PdfDocument with the specified number of pages
MockPdfDocument createMockPdfDocument(int pageCount) {
  final mockDoc = MockPdfDocument();
  when(() => mockDoc.pages).thenReturn(List.generate(pageCount, (_) => MockPdfPage()));
  return mockDoc;
}

void main() {
  group('PdfViewerBloc', () {
    late RecentFilesRepository repository;

    setUp(() {
      repository = MockRecentFilesRepository();
      // Default stub for getRecentFiles
      when(() => repository.getRecentFiles()).thenAnswer((_) async => []);
    });

    test('initial state is PdfViewerInitial', () {
      final bloc = PdfViewerBloc(recentFilesRepository: repository);
      expect(bloc.state, const PdfViewerInitial());
      bloc.close();
    });

    group('RecentFilesRequested', () {
      final testFiles = [
        RecentFile.fromPath('/test1.pdf'),
        RecentFile.fromPath('/test2.pdf'),
      ];

      blocTest<PdfViewerBloc, PdfViewerState>(
        'loads recent files successfully',
        build: () {
          when(() => repository.getRecentFiles()).thenAnswer((_) async => testFiles);
          return PdfViewerBloc(recentFilesRepository: repository);
        },
        act: (bloc) => bloc.add(const RecentFilesRequested()),
        expect: () => [
          PdfViewerInitial(recentFiles: testFiles),
        ],
        verify: (_) {
          verify(() => repository.getRecentFiles()).called(1);
        },
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'handles errors when loading recent files',
        build: () {
          when(() => repository.getRecentFiles()).thenThrow(Exception('Failed'));
          return PdfViewerBloc(recentFilesRepository: repository);
        },
        act: (bloc) => bloc.add(const RecentFilesRequested()),
        expect: () => [
          isA<PdfViewerError>()
              .having((s) => s.message, 'message', contains('Failed to load recent files')),
        ],
      );
    });

    group('Navigation History', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'navigation history is bounded to max size',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () {
          final mockDoc = MockPdfDocument();
          when(() => mockDoc.pages).thenReturn(List.generate(100, (_) => MockPdfPage()));
          return PdfViewerLoaded(
            document: mockDoc,
            filePath: '/test.pdf',
            fileName: 'test.pdf',
            currentPage: 1,
            totalPages: 100,
          );
        },
        act: (bloc) {
          // Add more than maxNavigationHistory entries
          for (int i = 1; i <= 60; i++) {
            bloc.add(PageNumberChanged(i));
          }
        },
        verify: (bloc) {
          final state = bloc.state as PdfViewerLoaded;
          // History should be capped at maxNavigationHistory (50)
          expect(state.navigationHistory.length, lessThanOrEqualTo(50));
        },
      );
    });

    group('Page Navigation', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'validates page numbers are within bounds',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () {
          final mockDoc = MockPdfDocument();
          when(() => mockDoc.pages).thenReturn(List.generate(10, (_) => MockPdfPage()));
          return PdfViewerLoaded(
            document: mockDoc,
            filePath: '/test.pdf',
            fileName: 'test.pdf',
            currentPage: 1,
            totalPages: 10,
          );
        },
        act: (bloc) {
          bloc.add(const PageNumberChanged(0)); // Invalid
          bloc.add(const PageNumberChanged(11)); // Invalid
          bloc.add(const PageNumberChanged(5)); // Valid
        },
        expect: () => [
          // Only the valid page change should emit
          isA<PdfViewerLoaded>().having((s) => s.currentPage, 'currentPage', 5),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'next page increments by 1',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 5,
          totalPages: 10,
        ),
        act: (bloc) => bloc.add(const NextPageRequested()),
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.currentPage, 'currentPage', 6),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'previous page decrements by 1',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 5,
          totalPages: 10,
        ),
        act: (bloc) => bloc.add(const PreviousPageRequested()),
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.currentPage, 'currentPage', 4),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'does not go beyond first page',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
        ),
        act: (bloc) => bloc.add(const PreviousPageRequested()),
        expect: () => [], // Should not emit any state change
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'does not go beyond last page',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 10,
          totalPages: 10,
        ),
        act: (bloc) => bloc.add(const NextPageRequested()),
        expect: () => [], // Should not emit any state change
      );
    });

    group('Zoom', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'zoom level is clamped to min/max',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          zoomLevel: 1.0,
        ),
        act: (bloc) {
          bloc.add(const ZoomChanged(10.0)); // Above max
          bloc.add(const ZoomChanged(0.1)); // Below min
        },
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.zoomLevel, 'zoomLevel', 4.0), // Clamped to max
          isA<PdfViewerLoaded>().having((s) => s.zoomLevel, 'zoomLevel', 0.25), // Clamped to min
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'zoom in increases by step',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          zoomLevel: 1.0,
        ),
        act: (bloc) => bloc.add(const ZoomInRequested()),
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.zoomLevel, 'zoomLevel', 1.25),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'zoom out decreases by step',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          zoomLevel: 1.0,
        ),
        act: (bloc) => bloc.add(const ZoomOutRequested()),
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.zoomLevel, 'zoomLevel', 0.75),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'zoom reset returns to default',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          zoomLevel: 2.0,
        ),
        act: (bloc) => bloc.add(const ZoomResetRequested()),
        expect: () => [
          isA<PdfViewerLoaded>().having((s) => s.zoomLevel, 'zoomLevel', 1.0),
        ],
      );
    });

    group('Search', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'clears search when empty query',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          searchQuery: 'test',
          searchResults: const [],
        ),
        act: (bloc) => bloc.add(const SearchQueryChanged('')),
        expect: () => [
          isA<PdfViewerLoaded>()
              .having((s) => s.searchQuery, 'searchQuery', null)
              .having((s) => s.searchResults, 'searchResults', isEmpty),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'search closed clears query and results',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          searchQuery: 'test',
          searchResults: const [],
        ),
        act: (bloc) => bloc.add(const SearchClosed()),
        expect: () => [
          isA<PdfViewerLoaded>()
              .having((s) => s.searchQuery, 'searchQuery', null)
              .having((s) => s.searchResults, 'searchResults', isEmpty)
              .having((s) => s.isSearching, 'isSearching', false),
        ],
      );
    });

    group('Toggles', () {
      blocTest<PdfViewerBloc, PdfViewerState>(
        'toggles bookmark sidebar',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          isBookmarkSidebarOpen: false,
        ),
        act: (bloc) => bloc.add(const BookmarkSidebarToggled()),
        expect: () => [
          isA<PdfViewerLoaded>()
              .having((s) => s.isBookmarkSidebarOpen, 'isBookmarkSidebarOpen', true),
        ],
      );

      blocTest<PdfViewerBloc, PdfViewerState>(
        'toggles distraction free mode',
        build: () => PdfViewerBloc(recentFilesRepository: repository),
        seed: () => PdfViewerLoaded(
          document: createMockPdfDocument(10),
          filePath: '/test.pdf',
          fileName: 'test.pdf',
          currentPage: 1,
          totalPages: 10,
          isDistractionFreeMode: false,
        ),
        act: (bloc) => bloc.add(const DistractionFreeModeToggled()),
        expect: () => [
          isA<PdfViewerLoaded>()
              .having((s) => s.isDistractionFreeMode, 'isDistractionFreeMode', true),
        ],
      );
    });
  });
}
