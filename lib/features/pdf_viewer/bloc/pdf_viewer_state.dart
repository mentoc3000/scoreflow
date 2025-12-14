import 'package:equatable/equatable.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/recent_file.dart';
import '../models/search_result.dart';

/// Base class for all PDF viewer states
abstract class PdfViewerState extends Equatable {
  const PdfViewerState();

  @override
  List<Object?> get props => [];
}

/// Initial state with no PDF loaded
class PdfViewerInitial extends PdfViewerState {
  final List<RecentFile> recentFiles;

  const PdfViewerInitial({this.recentFiles = const []});

  @override
  List<Object?> get props => [recentFiles];
}

/// State when loading a PDF file
class PdfViewerLoading extends PdfViewerState {
  final String filePath;

  const PdfViewerLoading(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// State when PDF is successfully loaded and ready to display
class PdfViewerLoaded extends PdfViewerState {
  final PdfDocument document;
  final String filePath;
  final String fileName;
  final int currentPage;
  final int totalPages;
  final List<PdfOutlineNode> bookmarks;
  final bool isBookmarkSidebarOpen;
  final List<int> navigationHistory;
  final int navigationHistoryIndex;
  final double zoomLevel;
  final String? searchQuery;
  final List<SearchResult> searchResults;
  final int currentSearchResultIndex;
  final bool isSearching;
  final bool isDistractionFreeMode;

  const PdfViewerLoaded({
    required this.document,
    required this.filePath,
    required this.fileName,
    required this.currentPage,
    required this.totalPages,
    this.bookmarks = const [],
    this.isBookmarkSidebarOpen = false,
    this.navigationHistory = const [],
    this.navigationHistoryIndex = -1,
    this.zoomLevel = 1.0,
    this.searchQuery,
    this.searchResults = const [],
    this.currentSearchResultIndex = -1,
    this.isSearching = false,
    this.isDistractionFreeMode = false,
  });

  /// Creates a copy of this state with updated values
  PdfViewerLoaded copyWith({
    PdfDocument? document,
    String? filePath,
    String? fileName,
    int? currentPage,
    int? totalPages,
    List<PdfOutlineNode>? bookmarks,
    bool? isBookmarkSidebarOpen,
    List<int>? navigationHistory,
    int? navigationHistoryIndex,
    double? zoomLevel,
    String? searchQuery,
    List<SearchResult>? searchResults,
    int? currentSearchResultIndex,
    bool? isSearching,
    bool? isDistractionFreeMode,
  }) {
    return PdfViewerLoaded(
      document: document ?? this.document,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      bookmarks: bookmarks ?? this.bookmarks,
      isBookmarkSidebarOpen: isBookmarkSidebarOpen ?? this.isBookmarkSidebarOpen,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      navigationHistoryIndex: navigationHistoryIndex ?? this.navigationHistoryIndex,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      currentSearchResultIndex: currentSearchResultIndex ?? this.currentSearchResultIndex,
      isSearching: isSearching ?? this.isSearching,
      isDistractionFreeMode: isDistractionFreeMode ?? this.isDistractionFreeMode,
    );
  }

  bool get canGoBack => navigationHistoryIndex > 0;
  bool get canGoForward => navigationHistoryIndex < navigationHistory.length - 1;
  bool get hasSearchResults => searchResults.isNotEmpty;
  bool get isSearchActive => searchQuery != null && searchQuery!.isNotEmpty;

  @override
  List<Object?> get props => [
    document,
    filePath,
    fileName,
    currentPage,
    totalPages,
    bookmarks,
    isBookmarkSidebarOpen,
    navigationHistory,
    navigationHistoryIndex,
    zoomLevel,
    searchQuery,
    searchResults,
    currentSearchResultIndex,
    isSearching,
    isDistractionFreeMode,
  ];
}

/// State when there's an error loading or displaying the PDF
class PdfViewerError extends PdfViewerState {
  final String message;
  final List<RecentFile> recentFiles;

  const PdfViewerError({required this.message, this.recentFiles = const []});

  @override
  List<Object?> get props => [message, recentFiles];
}
