import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import '../models/pdf_bookmark_item.dart';
import 'widgets/bookmark_sidebar.dart';
import 'widgets/multi_page_viewer.dart';
import 'widgets/page_navigation_controls.dart';

/// Screen for viewing PDF files
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final PdfViewerBloc bloc = context.read<PdfViewerBloc>();

      // Handle Cmd/Ctrl+B to toggle bookmarks
      if (event.logicalKey == LogicalKeyboardKey.keyB &&
          (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
        bloc.add(const BookmarkSidebarToggled());
        return;
      }

      // Handle Cmd/Ctrl+Left for back navigation
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
        bloc.add(const NavigateBackRequested());
        return;
      }

      // Handle Cmd/Ctrl+Right for forward navigation
      if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
        bloc.add(const NavigateForwardRequested());
        return;
      }

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.pageUp:
          bloc.add(const PreviousPageRequested());
          break;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.pageDown:
          bloc.add(const NextPageRequested());
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: BlocBuilder<PdfViewerBloc, PdfViewerState>(
        builder: (BuildContext context, PdfViewerState state) {
          if (state is PdfViewerLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Loading...'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading PDF...')],
                ),
              ),
            );
          }

          if (state is PdfViewerLoaded) {
            // Convert bookmarks to UI-friendly format
            final List<PdfBookmarkItem> bookmarkItems = PdfBookmarkItem.fromOutlineNodes(state.bookmarks);

            return Scaffold(
              appBar: AppBar(
                title: Text(state.fileName),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Close',
                  onPressed: () {
                    context.read<PdfViewerBloc>().add(const FileClosed());
                  },
                ),
                actions: [
                  // Bookmark icon button
                  IconButton(
                    icon: Icon(state.isBookmarkSidebarOpen ? Icons.bookmark : Icons.bookmark_border),
                    tooltip: state.isBookmarkSidebarOpen ? 'Hide bookmarks (⌘B)' : 'Show bookmarks (⌘B)',
                    onPressed: () {
                      context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  // PDF Display with Sidebar
                  Expanded(
                    child: Row(
                      children: [
                        // Bookmark Sidebar
                        BookmarkSidebar(
                          bookmarks: bookmarkItems,
                          isOpen: state.isBookmarkSidebarOpen,
                          onToggle: () {
                            context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                          },
                          onBookmarkTap: (int pageNumber) {
                            context.read<PdfViewerBloc>().add(BookmarkTapped(pageNumber: pageNumber));
                          },
                          currentPage: state.currentPage,
                        ),
                        // PDF Viewer
                        Expanded(
                          child: MultiPageViewer(
                            document: state.document,
                            currentPage: state.currentPage,
                            totalPages: state.totalPages,
                            onPageChanged: (int pageNumber) {
                              context.read<PdfViewerBloc>().add(PageViewChanged(pageNumber));
                            },
                            onLinkTap: (int pageNumber) {
                              context.read<PdfViewerBloc>().add(BookmarkTapped(pageNumber: pageNumber));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page Navigation Controls
                  PageNavigationControls(
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onPreviousPage: () {
                      context.read<PdfViewerBloc>().add(const PreviousPageRequested());
                    },
                    onNextPage: () {
                      context.read<PdfViewerBloc>().add(const NextPageRequested());
                    },
                    onPageChanged: (int pageNumber) {
                      context.read<PdfViewerBloc>().add(PageNumberChanged(pageNumber));
                    },
                  ),
                ],
              ),
            );
          }

          // Fallback for unexpected states
          return const Scaffold(body: Center(child: Text('Unexpected state')));
        },
      ),
    );
  }
}
