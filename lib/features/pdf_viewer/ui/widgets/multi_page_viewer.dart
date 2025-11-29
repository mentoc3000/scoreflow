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

  const MultiPageViewer({
    super.key,
    required this.document,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.onLinkTap,
  });

  @override
  State<MultiPageViewer> createState() => _MultiPageViewerState();
}

class _MultiPageViewerState extends State<MultiPageViewer> {
  late ScrollController _scrollController;
  bool _isUpdatingFromExternal = false;
  double _pageWidth = 0;
  double _lastPageWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentPage > 1 && _pageWidth > 0) {
        _scrollToPage(widget.currentPage, animate: false);
      }
    });
  }

  @override
  void didUpdateWidget(MultiPageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentPage != widget.currentPage &&
        !_isUpdatingFromExternal) {
      _scrollToPage(widget.currentPage, animate: true);
    }
  }

  void _scrollToPage(int pageNumber, {required bool animate}) {
    if (!_scrollController.hasClients || _pageWidth == 0) return;

    // Scroll so that the current page is on the left and next page is on the right
    // However, use max scroll extent if we're at or near the end
    final double targetScroll = (pageNumber - 1) * _pageWidth;
    final double maxScroll = _scrollController.position.maxScrollExtent;

    // Use maxScroll for the last page to show it properly positioned
    final double clampedScroll = targetScroll >= maxScroll
        ? maxScroll
        : targetScroll;

    if (animate) {
      _scrollController.animateTo(
        clampedScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      // Round to nearest page based on scroll position
      newPage = (scrollPosition / _pageWidth).round() + 1;
    }

    if (newPage != widget.currentPage &&
        newPage >= 1 &&
        newPage <= widget.totalPages) {
      setState(() {
        _isUpdatingFromExternal = true;
      });
      widget.onPageChanged(newPage);
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
    // Single page: show centered
    if (widget.totalPages == 1) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 8.5 / 11,
              child: PdfPageWidget(
                document: widget.document,
                pageNumber: 1,
                isCurrentPage: true,
                onLinkTap: widget.onLinkTap,
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
            // Calculate page width based on available height and aspect ratio
            final double availableHeight =
                constraints.maxHeight - 32; // Account for vertical padding
            final double pageWidth =
                availableHeight * (8.5 / 11); // Width based on aspect ratio
            final double gap = 8.0; // Gap between pages

            // Detect page width change (screen resize) and update scroll position
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

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.only(
                  left:
                      (constraints.maxWidth - (2 * pageWidth + gap)) /
                      2, // Center two pages
                  right: (constraints.maxWidth - (2 * pageWidth + gap)) / 2,
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: Row(
                  children: List.generate(widget.totalPages, (index) {
                    final int pageNumber = index + 1;
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
                          ),
                        ),
                        if (index < widget.totalPages - 1) SizedBox(width: gap),
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
