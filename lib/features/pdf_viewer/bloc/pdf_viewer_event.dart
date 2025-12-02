import 'package:equatable/equatable.dart';

/// Base class for all PDF viewer events
abstract class PdfViewerEvent extends Equatable {
  const PdfViewerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to open file picker dialog
class OpenFileRequested extends PdfViewerEvent {
  const OpenFileRequested();
}

/// Event when user selects a PDF file
class FileSelected extends PdfViewerEvent {
  final String filePath;

  const FileSelected(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Event when user opens a recent file
class RecentFileOpened extends PdfViewerEvent {
  final String filePath;

  const RecentFileOpened(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Event to navigate to the next page
class NextPageRequested extends PdfViewerEvent {
  const NextPageRequested();
}

/// Event to navigate to the previous page
class PreviousPageRequested extends PdfViewerEvent {
  const PreviousPageRequested();
}

/// Event to jump to a specific page number
class PageNumberChanged extends PdfViewerEvent {
  final int pageNumber;

  const PageNumberChanged(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event to close the current PDF file
class FileClosed extends PdfViewerEvent {
  const FileClosed();
}

/// Event to load recent files from repository
class RecentFilesRequested extends PdfViewerEvent {
  const RecentFilesRequested();
}

/// Event when PageView changes page (from swipe gesture)
class PageViewChanged extends PdfViewerEvent {
  final int pageNumber;

  const PageViewChanged(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Event when a bookmark is tapped
class BookmarkTapped extends PdfViewerEvent {
  final int pageNumber;

  const BookmarkTapped({required this.pageNumber});

  @override
  List<Object?> get props => [pageNumber];
}

/// Event to toggle bookmark sidebar open/closed
class BookmarkSidebarToggled extends PdfViewerEvent {
  const BookmarkSidebarToggled();
}

/// Event to navigate back in history
class NavigateBackRequested extends PdfViewerEvent {
  const NavigateBackRequested();
}

/// Event to navigate forward in history
class NavigateForwardRequested extends PdfViewerEvent {
  const NavigateForwardRequested();
}

/// Event to change zoom level to a specific value
class ZoomChanged extends PdfViewerEvent {
  final double zoomLevel;

  const ZoomChanged(this.zoomLevel);

  @override
  List<Object?> get props => [zoomLevel];
}

/// Event to zoom in (increase by 0.25)
class ZoomInRequested extends PdfViewerEvent {
  const ZoomInRequested();
}

/// Event to zoom out (decrease by 0.25)
class ZoomOutRequested extends PdfViewerEvent {
  const ZoomOutRequested();
}

/// Event to reset zoom to default (1.0)
class ZoomResetRequested extends PdfViewerEvent {
  const ZoomResetRequested();
}

/// Event when search query changes
class SearchQueryChanged extends PdfViewerEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to go to next search result
class SearchNextRequested extends PdfViewerEvent {
  const SearchNextRequested();
}

/// Event to go to previous search result
class SearchPreviousRequested extends PdfViewerEvent {
  const SearchPreviousRequested();
}

/// Event to close search and clear search state
class SearchClosed extends PdfViewerEvent {
  const SearchClosed();
}

/// Event to remove a file from recent files list
class RecentFileRemoved extends PdfViewerEvent {
  final String filePath;

  const RecentFileRemoved(this.filePath);

  @override
  List<Object?> get props => [filePath];
}
