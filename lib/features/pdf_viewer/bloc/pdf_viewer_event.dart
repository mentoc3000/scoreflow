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
