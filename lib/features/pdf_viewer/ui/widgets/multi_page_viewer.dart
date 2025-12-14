import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/config/app_config.dart';
import 'pdf_page_widget.dart';

/// Custom scroll behavior that enables mouse drag scrolling on desktop
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

/// Widget for displaying PDF with two-page sliding view
/// Single page PDFs show one centered page
/// Multi-page PDFs show two pages side by side with smooth individual page sliding
class MultiPageViewer extends StatefulWidget {
  final PdfDocument document;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Function(int)? onLinkTap;
  final double zoomLevel;

  const MultiPageViewer({
    super.key,
    required this.document,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.onLinkTap,
    this.zoomLevel = 1.0,
  });

  @override
  State<MultiPageViewer> createState() => _MultiPageViewerState();
}

/// Determines which pages should have links loaded based on viewport visibility
/// Loads links for current page +/- buffer pages
class _PageVisibilityTracker {
  final int totalPages;
  final int bufferPages;

  _PageVisibilityTracker({required this.totalPages, this.bufferPages = 2});

  /// Returns set of page numbers that should have links loaded
  Set<int> getVisiblePages(int currentPage) {
    final Set<int> visiblePages = {};

    // Add current page
    visiblePages.add(currentPage);

    // Add buffer pages before and after
    for (int i = 1; i <= bufferPages; i++) {
      final int prevPage = currentPage - i;
      final int nextPage = currentPage + i;

      if (prevPage >= 1) {
        visiblePages.add(prevPage);
      }

      if (nextPage <= totalPages) {
        visiblePages.add(nextPage);
      }
    }

    return visiblePages;
  }
}

class _MultiPageViewerState extends State<MultiPageViewer> {
  late ScrollController _scrollController;
  bool _isUpdatingFromExternal = false;
  double _pageWidth = 0;
  double _lastPageWidth = 0;
  late _PageVisibilityTracker _visibilityTracker;
  Set<int> _visiblePages = {};
  final double _gap = AppConfig.pageGap;
  int? _pendingScrollPage; // Page to scroll to once layout is complete
  bool _pendingScrollAnimate = false; // Whether pending scroll should animate
  bool _initialLayoutComplete = false; // Track if initial layout is done
  bool _userIsDragging = false; // Track if user is actively dragging
  final List<_QueuedScroll> _scrollQueue = []; // Queue for rapid page advances
  bool _isProcessingQueue = false; // Whether we're currently processing the queue

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _visibilityTracker = _PageVisibilityTracker(
      totalPages: widget.totalPages,
      bufferPages: AppConfig.searchBufferPages,
    );

    // Initialize visible pages
    _updateVisiblePages(widget.currentPage);
  }

  void _updateVisiblePages(int currentPage) {
    final Set<int> newVisiblePages = _visibilityTracker.getVisiblePages(currentPage);
    if (_visiblePages != newVisiblePages) {
      setState(() {
        _visiblePages = newVisiblePages;
      });
    }
  }

  @override
  void didUpdateWidget(MultiPageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentPage != widget.currentPage && !_isUpdatingFromExternal) {
      final bool goingForward = widget.currentPage > oldWidget.currentPage;
      _scrollToPage(widget.currentPage, animate: true, goingForward: goingForward);
      _updateVisiblePages(widget.currentPage);
    }

    // Handle zoom level changes
    if (oldWidget.zoomLevel != widget.zoomLevel && _pageWidth > 0) {
      // Recalculate scroll position after zoom change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPage(widget.currentPage, animate: false);
      });
    }
  }

  /// Scrolls to the specified page number.
  ///
  /// When [goingForward] is provided, corrects the scroll position before animating
  /// to ensure smooth directional scrolling even when auto-scroll has moved the view.
  /// Animated scrolls are queued if an animation is already in progress.
  void _scrollToPage(int pageNumber, {required bool animate, bool? goingForward}) {
    if (!_scrollController.hasClients) return;

    // If page width isn't ready yet, queue the scroll for later
    if (_pageWidth == 0) {
      _pendingScrollPage = pageNumber;
      _pendingScrollAnimate = animate;
      return;
    }

    // If already animating, queue this scroll request for sequential execution
    if (animate && _isProcessingQueue) {
      _scrollQueue.add(_QueuedScroll(pageNumber, goingForward));
      return;
    }

    _executeScroll(pageNumber, animate: animate, goingForward: goingForward);
  }

  /// Executes a scroll immediately without queueing.
  void _executeScroll(int pageNumber, {required bool animate, bool? goingForward}) {
    final double step = _pageWidth + _gap;
    final double targetScroll = (pageNumber - 1) * step;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clampedScroll = targetScroll >= maxScroll ? maxScroll : targetScroll;
    final double currentOffset = _scrollController.offset;

    // Already at target position
    if ((currentOffset - clampedScroll).abs() < 1.0) {
      _pendingScrollPage = null;
      _processNextInQueue();
      return;
    }

    if (animate) {
      // If direction is known, correct scroll position before animating
      // This handles cases where auto-scroll moved the view to the wrong position
      if (goingForward != null) {
        final double expectedStart = goingForward
            ? (clampedScroll - step).clamp(0.0, maxScroll)
            : (clampedScroll + step).clamp(0.0, maxScroll);

        // If current position is off by more than half a page, fix it first
        if ((currentOffset - expectedStart).abs() > step * 0.5) {
          _scrollController.jumpTo(expectedStart);
        }
      }

      _isProcessingQueue = true;
      _scrollController
          .animateTo(clampedScroll, duration: AppConfig.scrollAnimationDuration, curve: Curves.easeInOut)
          .then((_) => _processNextInQueue());
    } else {
      _scrollController.jumpTo(clampedScroll);
    }

    _pendingScrollPage = null;
  }

  /// Processes the next queued scroll, if any.
  void _processNextInQueue() {
    if (_scrollQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }

    final _QueuedScroll next = _scrollQueue.removeAt(0);
    _executeScroll(next.pageNumber, animate: true, goingForward: next.goingForward);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _pageWidth == 0) return;

    // Don't process scroll events until initial layout is complete
    if (!_initialLayoutComplete) return;

    // Only change pages when USER is dragging, not during programmatic animations
    // During animations, the page is already set by the parent widget
    if (!_userIsDragging) return;

    final double scrollPosition = _scrollController.offset;

    // Calculate current page based on scroll position
    final int newPage = ((scrollPosition / (_pageWidth + _gap)).round() + 1).clamp(1, widget.totalPages);

    if (newPage != widget.currentPage && newPage >= 1 && newPage <= widget.totalPages) {
      setState(() {
        _isUpdatingFromExternal = true;
      });
      widget.onPageChanged(newPage);
      _updateVisiblePages(newPage);
      Future.delayed(AppConfig.tabSwitchDelay, () {
        if (mounted) {
          setState(() {
            _isUpdatingFromExternal = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the actual page aspect ratio from the first page
    final double pageAspectRatio = widget.document.pages.isNotEmpty
        ? widget.document.pages[0].width / widget.document.pages[0].height
        : 8.5 / 11; // Fallback to standard letter size

    // Single page: show centered
    if (widget.totalPages == 1) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: pageAspectRatio,
              child: PdfPageWidget(
                document: widget.document,
                pageNumber: 1,
                isCurrentPage: true,
                onLinkTap: widget.onLinkTap,
                shouldLoadLinks: true, // Always load links for single page
              ),
            ),
          ),
        ),
      );
    }

    // Multi-page: use custom horizontal scroll with precise control
    return Container(
      color: Colors.grey[300],
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Track user drag state for scroll event filtering
          if (notification is ScrollStartNotification) {
            if (notification.dragDetails != null) {
              _userIsDragging = true;
            }
          } else if (notification is ScrollEndNotification) {
            _userIsDragging = false;
          }

          if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
            _onScroll();
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate page width based on available height and actual PDF page aspect ratio
            final double availableHeight = constraints.maxHeight - (2 * AppConfig.pagePadding);
            final double basePageWidth = availableHeight * pageAspectRatio; // Width based on actual aspect ratio
            final double pageWidth = basePageWidth * widget.zoomLevel; // Apply zoom level

            // Detect page width change (screen resize or zoom) and update scroll position
            if (pageWidth != _lastPageWidth) {
              final bool isFirstLayout = _lastPageWidth == 0;
              _lastPageWidth = pageWidth;
              _pageWidth = pageWidth;

              if (isFirstLayout) {
                // On first layout, wait for rendering to complete then set correct position
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initialLayoutComplete = true;

                    // Delay to let any auto-scroll settle, then correct position if needed
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && _pendingScrollPage == null) {
                        final double correctPosition = (widget.currentPage - 1) * (_pageWidth + _gap);
                        if ((_scrollController.offset - correctPosition).abs() > 1.0) {
                          _scrollController.jumpTo(correctPosition);
                        }
                      } else if (_pendingScrollPage != null) {
                        _scrollToPage(_pendingScrollPage!, animate: _pendingScrollAnimate);
                      }
                    });
                  });
                });
              } else {
                // For resize/zoom, update scroll position immediately
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pendingScrollPage != null) {
                    _scrollToPage(_pendingScrollPage!, animate: _pendingScrollAnimate);
                  } else {
                    _scrollToPage(widget.currentPage, animate: false);
                  }
                });
              }
            }

            // Store the left padding for scroll calculations
            // Ensure padding is never negative (when viewport is too narrow)
            final double leftPadding = (constraints.maxWidth - (2 * pageWidth + _gap)) / 2;
            final double clampedLeftPadding = leftPadding > 0 ? leftPadding : 0;

            return ScrollConfiguration(
              behavior: _DragScrollBehavior(),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: clampedLeftPadding, // Center two pages
                    right: clampedLeftPadding,
                    top: AppConfig.pagePadding,
                    bottom: AppConfig.pagePadding,
                  ),
                  child: Row(
                    children: List.generate(widget.totalPages, (index) {
                      final int pageNumber = index + 1;
                      final bool shouldLoadLinks = _visiblePages.contains(pageNumber);

                      return Row(
                        children: [
                          SizedBox(
                            width: pageWidth,
                            height: availableHeight,
                            child: PdfPageWidget(
                              document: widget.document,
                              pageNumber: pageNumber,
                              isCurrentPage: pageNumber == widget.currentPage,
                              onLinkTap: widget.onLinkTap,
                              shouldLoadLinks: shouldLoadLinks,
                            ),
                          ),
                          if (index < widget.totalPages - 1) SizedBox(width: _gap),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Represents a queued scroll request for rapid page advances.
class _QueuedScroll {
  final int pageNumber;
  final bool? goingForward;

  _QueuedScroll(this.pageNumber, this.goingForward);
}
