import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'pdf_page_widget.dart';

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
  final double _gap = 8.0; // Gap between pages

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _visibilityTracker = _PageVisibilityTracker(
      totalPages: widget.totalPages,
      bufferPages: 2, // Load links for current page +/- 2 pages
    );
    _updateVisiblePages(widget.currentPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentPage > 1 && _pageWidth > 0) {
        _scrollToPage(widget.currentPage, animate: false);
      }
    });
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
      _scrollToPage(widget.currentPage, animate: true);
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

  void _scrollToPage(int pageNumber, {required bool animate}) {
    if (!_scrollController.hasClients || _pageWidth == 0) return;

    // Calculate scroll position so current page is on left, next page on right, both centered
    // Each page position = (page_index * pageWidth) + (page_index * gap)
    // For page N (1-indexed), we want to scroll to position (N-1) * (pageWidth + gap)
    final double targetScroll = (pageNumber - 1) * (_pageWidth + _gap);
    final double maxScroll = _scrollController.position.maxScrollExtent;

    // Use maxScroll for the last page to show it properly positioned
    final double clampedScroll = targetScroll >= maxScroll ? maxScroll : targetScroll;

    if (animate) {
      _scrollController.animateTo(clampedScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _scrollController.jumpTo(clampedScroll);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _pageWidth == 0) return;

    final double scrollPosition = _scrollController.offset;
    final double maxScroll = _scrollController.position.maxScrollExtent;

    // If we're at max scroll, we're on the last page
    int newPage;
    if ((maxScroll - scrollPosition).abs() < 1.0) {
      newPage = widget.totalPages;
    } else {
      // Calculate page based on scroll position accounting for gaps
      // Each page takes up (pageWidth + gap) of horizontal space
      newPage = (scrollPosition / (_pageWidth + _gap)).round() + 1;
    }

    if (newPage != widget.currentPage && newPage >= 1 && newPage <= widget.totalPages) {
      setState(() {
        _isUpdatingFromExternal = true;
      });
      widget.onPageChanged(newPage);
      _updateVisiblePages(newPage);
      Future.delayed(const Duration(milliseconds: 100), () {
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
          if (notification is ScrollEndNotification) {
            _onScroll();
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate page width based on available height and actual PDF page aspect ratio
            final double availableHeight = constraints.maxHeight - 32; // Account for vertical padding
            final double basePageWidth = availableHeight * pageAspectRatio; // Width based on actual aspect ratio
            final double pageWidth = basePageWidth * widget.zoomLevel; // Apply zoom level

            // Detect page width change (screen resize or zoom) and update scroll position
            if (pageWidth != _lastPageWidth && _lastPageWidth > 0) {
              _lastPageWidth = pageWidth;
              _pageWidth = pageWidth;
              // Schedule scroll position update after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToPage(widget.currentPage, animate: false);
              });
            } else {
              _lastPageWidth = pageWidth;
              _pageWidth = pageWidth;
            }

            // Store the left padding for scroll calculations
            // Ensure padding is never negative (when viewport is too narrow)
            final double leftPadding = math.max(0, (constraints.maxWidth - (2 * pageWidth + _gap)) / 2);

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.only(
                  left: leftPadding, // Center two pages
                  right: leftPadding,
                  top: 16.0,
                  bottom: 16.0,
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
            );
          },
        ),
      ),
    );
  }
}
