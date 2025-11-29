import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Widget that handles internal PDF link detection and navigation
/// Only handles links within the PDF document (page-to-page navigation)
class PdfLinkHandler extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final Size pageSize;
  final Function(int)? onInternalLinkTap;

  const PdfLinkHandler({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.pageSize,
    this.onInternalLinkTap,
  });

  @override
  State<PdfLinkHandler> createState() => _PdfLinkHandlerState();
}

class _PdfLinkHandlerState extends State<PdfLinkHandler> {
  List<PdfLink>? _links;
  bool _isLoading = true;
  PdfPage? _page;
  bool _isHoveringOverLink = false;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  @override
  void didUpdateWidget(PdfLinkHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadLinks();
    }
  }

  Future<void> _loadLinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Access page directly from pages list (page numbers are 1-indexed)
      if (widget.pageNumber <= 0 ||
          widget.pageNumber > widget.document.pages.length) {
        setState(() {
          _links = [];
          _isLoading = false;
          _page = null;
        });
        return;
      }

      final PdfPage page = widget.document.pages[widget.pageNumber - 1];
      final List<PdfLink> links = await page.loadLinks(
        compact: true,
        enableAutoLinkDetection: true,
      );

      debugPrint(
        'Page ${widget.pageNumber}: Found ${links.length} total links',
      );

      // Filter to only internal links
      final List<PdfLink> internalLinks = links
          .where((link) => link.dest != null)
          .toList();

      debugPrint(
        'Page ${widget.pageNumber}: ${internalLinks.length} internal links',
      );

      // Debug: print link details
      for (int i = 0; i < internalLinks.length; i++) {
        final link = internalLinks[i];
        debugPrint(
          '  Link $i: dest page=${link.dest?.pageNumber}, rects=${link.rects.length}',
        );
        for (final rect in link.rects) {
          debugPrint(
            '    Rect: L=${rect.left}, T=${rect.top}, R=${rect.right}, B=${rect.bottom}',
          );
        }
      }

      if (mounted) {
        setState(() {
          _links = internalLinks;
          _page = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading links for page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() {
          _links = [];
          _page = null;
          _isLoading = false;
        });
      }
    }
  }

  void _handleLinkTap(PdfLink link) {
    // Only handle internal PDF links (page navigation)
    if (link.dest != null) {
      final int? targetPage = link.dest?.pageNumber;
      if (targetPage != null && widget.onInternalLinkTap != null) {
        debugPrint(
          'Navigating from page ${widget.pageNumber} to page $targetPage',
        );
        widget.onInternalLinkTap!(targetPage);
      }
    }
  }

  bool _isPointInLink(Offset widgetPoint, PdfLink link) {
    if (_page == null) return false;

    // Get the PDF page dimensions
    final double pageWidth = _page!.width;
    final double pageHeight = _page!.height;

    // Calculate the scale factor - PdfPageView fits the page to the widget size
    final double scaleX = widget.pageSize.width / pageWidth;
    final double scaleY = widget.pageSize.height / pageHeight;

    // Use the smaller scale to maintain aspect ratio (fit mode)
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate the actual rendered size
    final double renderedWidth = pageWidth * scale;
    final double renderedHeight = pageHeight * scale;

    // Calculate offsets for centering
    final double offsetX = (widget.pageSize.width - renderedWidth) / 2;
    final double offsetY = (widget.pageSize.height - renderedHeight) / 2;

    // Convert widget coordinates to PDF page coordinates
    final double pdfX = (widgetPoint.dx - offsetX) / scale;
    final double pdfY = (widgetPoint.dy - offsetY) / scale;

    debugPrint('Widget tap at (${widgetPoint.dx}, ${widgetPoint.dy})');
    debugPrint('Converted to PDF coords: ($pdfX, $pdfY)');
    debugPrint(
      'Page size: ${pageWidth}x$pageHeight, Widget size: ${widget.pageSize.width}x${widget.pageSize.height}',
    );
    debugPrint('Scale: $scale, Offset: ($offsetX, $offsetY)');

    for (final PdfRect rect in link.rects) {
      // PdfRect coordinates: origin is bottom-left, Y increases upward
      // We need to convert to Flutter coordinates: origin is top-left, Y increases downward
      final double rectLeft = rect.left;
      final double rectRight = rect.right;
      final double rectTop = pageHeight - rect.top; // Flip Y coordinate
      final double rectBottom = pageHeight - rect.bottom; // Flip Y coordinate

      debugPrint(
        '  Checking rect: L=$rectLeft, T=$rectTop, R=$rectRight, B=$rectBottom (Flutter coords)',
      );

      if (pdfX >= rectLeft &&
          pdfX <= rectRight &&
          pdfY >= rectTop &&
          pdfY <= rectBottom) {
        debugPrint('  HIT!');
        return true;
      }
    }

    return false;
  }

  PdfLink? _findLinkAtPosition(Offset position) {
    if (_links == null || _page == null) return null;

    for (final PdfLink link in _links!) {
      if (_isPointInLink(position, link)) {
        return link;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _links == null || _links!.isEmpty || _page == null) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      cursor: _isHoveringOverLink
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onHover: (PointerEvent event) {
        final bool wasHovering = _isHoveringOverLink;
        final bool isHovering =
            _findLinkAtPosition(event.localPosition) != null;

        if (wasHovering != isHovering) {
          setState(() {
            _isHoveringOverLink = isHovering;
          });
        }
      },
      onExit: (PointerEvent event) {
        if (_isHoveringOverLink) {
          setState(() {
            _isHoveringOverLink = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (TapUpDetails details) {
          final Offset localPosition = details.localPosition;

          debugPrint('\n=== Link tap detected ===');

          // Find which internal link was tapped
          final PdfLink? link = _findLinkAtPosition(localPosition);
          if (link != null) {
            _handleLinkTap(link);
            return;
          }

          debugPrint('No link found at tap location');
        },
        child: IgnorePointer(
          child: SizedBox(
            width: widget.pageSize.width,
            height: widget.pageSize.height,
          ),
        ),
      ),
    );
  }
}
