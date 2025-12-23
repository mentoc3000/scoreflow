import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../bloc/annotation_bloc.dart';
import '../bloc/annotation_event.dart';
import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import '../models/pdf_bookmark_item.dart';
import 'widgets/annotation_toolbar.dart';
import 'widgets/bookmark_sidebar.dart';
import 'widgets/multi_page_viewer.dart';
import 'widgets/page_navigation_controls.dart';
import 'widgets/search_bar.dart' as custom;

/// Screen for viewing PDF files
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final FocusNode _focusNode = FocusNode();
  double _sidebarWidth = AppConfig.defaultSidebarWidth;
  bool _isSearchOpen = false;
  bool _isAnnotationToolbarOpen = false;

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
      final bool isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;

      // Handle Cmd+Shift+F to toggle distraction-free mode
      if (event.logicalKey == LogicalKeyboardKey.keyF && isMetaOrCtrl && HardwareKeyboard.instance.isShiftPressed) {
        bloc.add(const DistractionFreeModeToggled());
        return;
      }

      // Handle Cmd/Ctrl+F to open search (without Shift)
      if (event.logicalKey == LogicalKeyboardKey.keyF && isMetaOrCtrl && !HardwareKeyboard.instance.isShiftPressed) {
        setState(() {
          _isSearchOpen = true;
        });
        return;
      }

      // Handle Cmd/Ctrl+Z for undo
      if (event.logicalKey == LogicalKeyboardKey.keyZ && isMetaOrCtrl && !HardwareKeyboard.instance.isShiftPressed) {
        context.read<AnnotationBloc>().add(const AnnotationUndoRequested());
        return;
      }

      // Handle Cmd/Ctrl+Shift+Z for redo
      if (event.logicalKey == LogicalKeyboardKey.keyZ && isMetaOrCtrl && HardwareKeyboard.instance.isShiftPressed) {
        context.read<AnnotationBloc>().add(const AnnotationRedoRequested());
        return;
      }

      // Handle Esc to close search, annotations, or exit distraction-free mode
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        final PdfViewerState state = bloc.state;
        if (state is PdfViewerLoaded && state.isDistractionFreeMode) {
          bloc.add(const DistractionFreeModeToggled());
          // Request focus back after toggling
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
          return;
        }
        if (_isAnnotationToolbarOpen) {
          setState(() {
            _isAnnotationToolbarOpen = false;
          });
          context.read<AnnotationBloc>().add(const AnnotationSelected(null));
          // Request focus back after closing annotations
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
          return;
        }
        if (_isSearchOpen) {
          setState(() {
            _isSearchOpen = false;
          });
          bloc.add(const SearchClosed());
          // Request focus back after closing search
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
          return;
        }
      }

      // Handle Cmd/Ctrl+B to toggle bookmarks
      if (event.logicalKey == LogicalKeyboardKey.keyB && isMetaOrCtrl) {
        bloc.add(const BookmarkSidebarToggled());
        return;
      }

      // Handle Cmd/Ctrl+Left for back navigation
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && isMetaOrCtrl) {
        bloc.add(const NavigateBackRequested());
        return;
      }

      // Handle Cmd/Ctrl+Right for forward navigation
      if (event.logicalKey == LogicalKeyboardKey.arrowRight && isMetaOrCtrl) {
        bloc.add(const NavigateForwardRequested());
        return;
      }

      // Regular navigation keys (without modifiers)
      if (!isMetaOrCtrl) {
        final PdfViewerState state = bloc.state;
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
          case LogicalKeyboardKey.home:
            // Jump to first page
            if (state is PdfViewerLoaded) {
              bloc.add(const PageNumberChanged(1));
            }
            break;
          case LogicalKeyboardKey.end:
            // Jump to last page
            if (state is PdfViewerLoaded) {
              bloc.add(PageNumberChanged(state.totalPages));
            }
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Request focus when user taps anywhere in the viewer
          _focusNode.requestFocus();
        },
        child: BlocListener<PdfViewerBloc, PdfViewerState>(
          listener: (context, state) {
            // Load annotations when PDF is loaded
            if (state is PdfViewerLoaded) {
              context.read<AnnotationBloc>().add(
                    AnnotationsLoadRequested(state.filePath),
                  );
            }
            // Clear annotations when file is closed
            if (state is PdfViewerInitial || state is PdfViewerError) {
              context.read<AnnotationBloc>().add(const AnnotationsCleared());
            }
          },
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
                // No AppBar - controls are integrated in tab bar
                body: Stack(
                  children: [
                    // Main content
                    Column(
                      children: [
                        // Search bar (shown when search is active and not in distraction-free mode)
                        if (_isSearchOpen && !state.isDistractionFreeMode)
                          custom.SearchBar(
                            query: state.searchQuery,
                            currentResultIndex: state.currentSearchResultIndex,
                            totalResults: state.searchResults.length,
                            isSearching: state.isSearching,
                            onClose: () {
                              setState(() {
                                _isSearchOpen = false;
                              });
                              context.read<PdfViewerBloc>().add(const SearchClosed());
                              // Request focus back after closing search
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _focusNode.requestFocus();
                              });
                            },
                          ),

                        // Annotation toolbar (shown when annotation mode is active and not in distraction-free mode)
                        if (_isAnnotationToolbarOpen && !state.isDistractionFreeMode)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: const AnnotationToolbar()),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _isAnnotationToolbarOpen = false;
                                    });
                                    context.read<AnnotationBloc>().add(const AnnotationSelected(null));
                                    // Request focus back after closing
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _focusNode.requestFocus();
                                    });
                                  },
                                  tooltip: 'Close annotations',
                                ),
                              ],
                            ),
                          ),

                        // PDF Display with Sidebar
                        Expanded(
                          child: Row(
                            children: [
                              // Bookmark Sidebar (hidden in distraction-free mode)
                              if (!state.isDistractionFreeMode)
                                BookmarkSidebar(
                                  bookmarks: bookmarkItems,
                                  isOpen: state.isBookmarkSidebarOpen,
                                  width: _sidebarWidth,
                                  onToggle: () {
                                    context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                                  },
                                  onBookmarkTap: (int pageNumber) {
                                    context.read<PdfViewerBloc>().add(BookmarkTapped(pageNumber: pageNumber));
                                  },
                                  currentPage: state.currentPage,
                                ),
                              // Resizable divider (only visible when sidebar is open and not in distraction-free mode)
                              if (state.isBookmarkSidebarOpen && !state.isDistractionFreeMode)
                                MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                                      setState(() {
                                        _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(
                                          AppConfig.minSidebarWidth,
                                          AppConfig.maxSidebarWidth,
                                        );
                                      });
                                    },
                                    child: Container(
                                      width: 8,
                                      color: Colors.transparent,
                                      child: Center(child: Container(width: 1, color: Colors.grey[300])),
                                    ),
                                  ),
                                ),
                              // PDF Viewer
                              Expanded(
                                child: Container(
                                  color: state.isDistractionFreeMode ? Colors.black : null,
                                  child: MultiPageViewer(
                                    document: state.document,
                                    currentPage: state.currentPage,
                                    totalPages: state.totalPages,
                                    zoomLevel: 1.0,
                                    onPageChanged: (int pageNumber) {
                                      context.read<PdfViewerBloc>().add(PageViewChanged(pageNumber));
                                    },
                                    onLinkTap: (int pageNumber) {
                                      context.read<PdfViewerBloc>().add(BookmarkTapped(pageNumber: pageNumber));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Page Navigation Controls with buttons (hidden in distraction-free mode)
                        if (!state.isDistractionFreeMode)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Bookmark button (left)
                                IconButton(
                                  icon: Icon(state.isBookmarkSidebarOpen ? Icons.bookmark : Icons.bookmark_border),
                                  onPressed: () {
                                    context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                                  },
                                  tooltip: state.isBookmarkSidebarOpen ? 'Hide bookmarks (⌘B)' : 'Show bookmarks (⌘B)',
                                  isSelected: state.isBookmarkSidebarOpen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: PageNavigationControls(
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
                                ),
                                const SizedBox(width: 8),
                                // Annotation button (right)
                                IconButton(
                                  icon: const Icon(Icons.edit_note),
                                  onPressed: () {
                                    setState(() {
                                      _isAnnotationToolbarOpen = !_isAnnotationToolbarOpen;
                                      if (_isAnnotationToolbarOpen) {
                                        _isSearchOpen = false;
                                      }
                                    });
                                  },
                                  tooltip: 'Annotations',
                                  isSelected: _isAnnotationToolbarOpen,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Distraction-free mode hint overlay (shows briefly when entering the mode)
                    if (state.isDistractionFreeMode)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                              child: const Text(
                                'Focus Mode • Press ⌘⇧F or Esc to exit',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            // Fallback for unexpected states
            return const Scaffold(body: Center(child: Text('Unexpected state')));
          },
          ),
        ),
      ),
    );
  }
}
