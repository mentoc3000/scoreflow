import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/recent_file.dart';
import '../repositories/recent_files_repository.dart';
import 'pdf_viewer_event.dart';
import 'pdf_viewer_state.dart';

/// Bloc for managing PDF viewer state and operations
class PdfViewerBloc extends Bloc<PdfViewerEvent, PdfViewerState> {
  final RecentFilesRepository _recentFilesRepository;
  final SecureBookmarks _secureBookmarks = SecureBookmarks();
  PdfDocument? _currentDocument;

  PdfViewerBloc({required RecentFilesRepository recentFilesRepository})
    : _recentFilesRepository = recentFilesRepository,
      super(const PdfViewerInitial()) {
    on<RecentFilesRequested>(_onRecentFilesRequested);
    on<OpenFileRequested>(_onOpenFileRequested);
    on<FileSelected>(_onFileSelected);
    on<RecentFileOpened>(_onRecentFileOpened);
    on<NextPageRequested>(_onNextPageRequested);
    on<PreviousPageRequested>(_onPreviousPageRequested);
    on<PageNumberChanged>(_onPageNumberChanged);
    on<PageViewChanged>(_onPageViewChanged);
    on<FileClosed>(_onFileClosed);
    on<BookmarkTapped>(_onBookmarkTapped);
    on<BookmarkSidebarToggled>(_onBookmarkSidebarToggled);
    on<NavigateBackRequested>(_onNavigateBackRequested);
    on<NavigateForwardRequested>(_onNavigateForwardRequested);
  }

  /// Loads recent files from the repository
  Future<void> _onRecentFilesRequested(RecentFilesRequested event, Emitter<PdfViewerState> emit) async {
    try {
      final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();
      emit(PdfViewerInitial(recentFiles: recentFiles));
    } catch (e) {
      emit(PdfViewerError(message: 'Failed to load recent files: ${e.toString()}'));
    }
  }

  /// Opens file picker dialog
  Future<void> _onOpenFileRequested(OpenFileRequested event, Emitter<PdfViewerState> emit) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final String? filePath = result.files.first.path;
        if (filePath != null) {
          add(FileSelected(filePath));
        }
      }
    } catch (e) {
      final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();
      emit(PdfViewerError(message: 'Failed to open file picker: ${e.toString()}', recentFiles: recentFiles));
    }
  }

  /// Handles file selection from picker
  Future<void> _onFileSelected(FileSelected event, Emitter<PdfViewerState> emit) async {
    await _loadPdfFile(event.filePath, emit, isFromRecentFiles: false);
  }

  /// Handles opening a recent file
  Future<void> _onRecentFileOpened(RecentFileOpened event, Emitter<PdfViewerState> emit) async {
    debugPrint('=== Opening recent file ===');
    debugPrint('Path: ${event.filePath}');

    // Check if file still exists
    final File file = File(event.filePath);

    // First check if file exists
    final bool exists = await file.exists();
    debugPrint('File exists: $exists');

    if (!exists) {
      final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();
      emit(PdfViewerError(message: 'File not found: ${event.filePath}', recentFiles: recentFiles));
      // Remove the non-existent file from recent files
      await _recentFilesRepository.removeRecentFile(event.filePath);
      return;
    }

    // Try to restore file access using security-scoped bookmark
    final List<RecentFile> allRecentFiles = await _recentFilesRepository.getRecentFiles();
    final RecentFile? recentFile = allRecentFiles.cast<RecentFile?>().firstWhere(
      (f) => f?.path == event.filePath,
      orElse: () => null,
    );

    String? resolvedPath;
    if (recentFile?.bookmark != null) {
      debugPrint('Found bookmark, attempting to resolve...');
      try {
        final FileSystemEntity resolved = await _secureBookmarks.resolveBookmark(recentFile!.bookmark!);
        resolvedPath = resolved.path;
        debugPrint('Bookmark resolved to: $resolvedPath');
        await _secureBookmarks.startAccessingSecurityScopedResource(File(resolvedPath));
        debugPrint('Started accessing security-scoped resource');
      } catch (e) {
        debugPrint('Bookmark resolution failed: $e');
        // Bookmark failed, will try direct access
      }
    }

    await _loadPdfFile(resolvedPath ?? event.filePath, emit, isFromRecentFiles: true, bookmark: recentFile?.bookmark);
  }

  /// Loads a PDF file from the given path
  Future<void> _loadPdfFile(
    String filePath,
    Emitter<PdfViewerState> emit, {
    bool isFromRecentFiles = false,
    int retryCount = 0,
    String? bookmark,
  }) async {
    debugPrint('=== Loading PDF ===');
    debugPrint('Path: $filePath');
    debugPrint('From recent files: $isFromRecentFiles');
    debugPrint('Retry count: $retryCount');

    emit(PdfViewerLoading(filePath));

    try {
      // Close previous document if exists
      await _currentDocument?.dispose();

      debugPrint('Opening PDF document...');
      // Open the PDF document
      final PdfDocument document = await PdfDocument.openFile(filePath);
      debugPrint('PDF opened successfully. Pages: ${document.pages.length}');

      // Verify the document has pages
      if (document.pages.isEmpty) {
        await document.dispose();
        final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();
        emit(PdfViewerError(message: 'PDF file has no pages: $filePath', recentFiles: recentFiles));
        return;
      }

      final String fileName = filePath.split('/').last;
      final int totalPages = document.pages.length;

      // Create security-scoped bookmark if we don't have one already
      String? newBookmark = bookmark;
      if (newBookmark == null && !isFromRecentFiles) {
        // Only create bookmark when opening via file picker
        try {
          newBookmark = await _secureBookmarks.bookmark(File(filePath));
          debugPrint('Created new bookmark for file');
        } catch (e) {
          debugPrint('Failed to create bookmark: $e');
          // Continue without bookmark
        }
      }

      // Add to recent files
      final RecentFile recentFile = RecentFile.fromPath(filePath, bookmark: newBookmark);
      await _recentFilesRepository.addRecentFile(recentFile);

      // Load bookmarks/outline
      List<PdfOutlineNode> bookmarks = [];
      try {
        bookmarks = await document.loadOutline();
        debugPrint('Loaded ${bookmarks.length} top-level bookmarks');
      } catch (e) {
        debugPrint('Failed to load bookmarks: $e');
        // Continue without bookmarks - not all PDFs have them
      }

      // Store references
      _currentDocument = document;

      debugPrint('PDF loaded successfully!');
      emit(
        PdfViewerLoaded(
          document: document,
          filePath: filePath,
          fileName: fileName,
          currentPage: 1,
          totalPages: totalPages,
          bookmarks: bookmarks,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading PDF: $e');
      debugPrint('Stack trace: $stackTrace');

      // If this is from recent files and first attempt, retry once after a delay
      if (isFromRecentFiles && retryCount < 1) {
        debugPrint('Retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 500));
        return _loadPdfFile(
          filePath,
          emit,
          isFromRecentFiles: isFromRecentFiles,
          retryCount: retryCount + 1,
          bookmark: bookmark,
        );
      }

      // Enhanced error message with more context
      final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();

      String errorMessage = 'Failed to load PDF: ${e.toString()}';

      // Add helpful context for common errors
      if (e.toString().contains('RENDER_ERROR') || e.toString().contains('Invalid PDF Format')) {
        errorMessage =
            'Unable to open PDF file.\n\n'
            'Please try using the "Open PDF" button to select the file again.';
      } else if (e.toString().contains('Operation not permitted')) {
        errorMessage =
            'Permission denied to access this file.\n\n'
            'Please use the "Open PDF" button to grant access to the file again.';
      }

      emit(PdfViewerError(message: errorMessage, recentFiles: recentFiles));
    }
  }

  /// Helper method to add a page to navigation history
  PdfViewerLoaded _addToNavigationHistory(PdfViewerLoaded currentState, int newPage) {
    // Don't add if we're just re-navigating to the same page
    if (currentState.navigationHistoryIndex >= 0 &&
        currentState.navigationHistoryIndex < currentState.navigationHistory.length &&
        currentState.navigationHistory[currentState.navigationHistoryIndex] == newPage) {
      return currentState.copyWith(currentPage: newPage);
    }

    // Remove any forward history if we're navigating from middle of history
    List<int> newHistory = currentState.navigationHistory.sublist(0, currentState.navigationHistoryIndex + 1);

    // Add new page to history
    newHistory.add(newPage);

    return currentState.copyWith(
      currentPage: newPage,
      navigationHistory: newHistory,
      navigationHistoryIndex: newHistory.length - 1,
    );
  }

  /// Navigates to the next page
  Future<void> _onNextPageRequested(NextPageRequested event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;

      // Advance by 1 page
      if (currentState.currentPage < currentState.totalPages) {
        final int nextPage = currentState.currentPage + 1;
        emit(_addToNavigationHistory(currentState, nextPage));
      }
    }
  }

  /// Navigates to the previous page
  Future<void> _onPreviousPageRequested(PreviousPageRequested event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;

      // Go back by 1 page
      if (currentState.currentPage > 1) {
        final int previousPage = currentState.currentPage - 1;
        emit(_addToNavigationHistory(currentState, previousPage));
      }
    }
  }

  /// Jumps to a specific page number
  Future<void> _onPageNumberChanged(PageNumberChanged event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;
      if (event.pageNumber >= 1 && event.pageNumber <= currentState.totalPages) {
        emit(_addToNavigationHistory(currentState, event.pageNumber));
      }
    }
  }

  /// Handles page changes from PageView (swipe gestures)
  Future<void> _onPageViewChanged(PageViewChanged event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;
      if (event.pageNumber >= 1 && event.pageNumber <= currentState.totalPages) {
        emit(_addToNavigationHistory(currentState, event.pageNumber));
      }
    }
  }

  /// Closes the current PDF file
  Future<void> _onFileClosed(FileClosed event, Emitter<PdfViewerState> emit) async {
    try {
      await _currentDocument?.dispose();
      _currentDocument = null;

      final List<RecentFile> recentFiles = await _recentFilesRepository.getRecentFiles();
      emit(PdfViewerInitial(recentFiles: recentFiles));
    } catch (e) {
      emit(PdfViewerError(message: 'Failed to close file: ${e.toString()}'));
    }
  }

  /// Handles bookmark tap event - navigates to the bookmark's page
  Future<void> _onBookmarkTapped(BookmarkTapped event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded loadedState = state as PdfViewerLoaded;

      // Validate page number
      if (event.pageNumber >= 1 && event.pageNumber <= loadedState.totalPages) {
        emit(_addToNavigationHistory(loadedState, event.pageNumber));
      }
    }
  }

  /// Handles bookmark sidebar toggle event
  Future<void> _onBookmarkSidebarToggled(BookmarkSidebarToggled event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded loadedState = state as PdfViewerLoaded;
      emit(loadedState.copyWith(isBookmarkSidebarOpen: !loadedState.isBookmarkSidebarOpen));
    }
  }

  /// Navigates back in history
  Future<void> _onNavigateBackRequested(NavigateBackRequested event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;

      if (currentState.canGoBack) {
        final int newIndex = currentState.navigationHistoryIndex - 1;
        final int targetPage = currentState.navigationHistory[newIndex];

        emit(currentState.copyWith(currentPage: targetPage, navigationHistoryIndex: newIndex));
      }
    }
  }

  /// Navigates forward in history
  Future<void> _onNavigateForwardRequested(NavigateForwardRequested event, Emitter<PdfViewerState> emit) async {
    if (state is PdfViewerLoaded) {
      final PdfViewerLoaded currentState = state as PdfViewerLoaded;

      if (currentState.canGoForward) {
        final int newIndex = currentState.navigationHistoryIndex + 1;
        final int targetPage = currentState.navigationHistory[newIndex];

        emit(currentState.copyWith(currentPage: targetPage, navigationHistoryIndex: newIndex));
      }
    }
  }

  @override
  Future<void> close() async {
    await _currentDocument?.dispose();
    return super.close();
  }
}
