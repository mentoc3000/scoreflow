import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/config/app_config.dart';

/// Service for background rendering of PDF pages
/// Pre-renders pages adjacent to the current page for smooth navigation
/// Note: This service tracks which pages should be pre-loaded.
/// The actual rendering is handled by pdfrx's internal caching system.
class BackgroundPageRenderer {
  Timer? _renderTimer;
  bool _isRendering = false;

  // Current rendering context
  PdfDocument? _currentDocument;
  String? _currentDocumentId;
  int? _currentPage;
  int? _totalPages;

  // Track pages that have been accessed for pre-loading
  final Set<int> _accessedPages = {};

  BackgroundPageRenderer();

  /// Schedule background rendering for pages around the current page
  void scheduleRendering({
    required PdfDocument document,
    required String documentId,
    required int currentPage,
    required int totalPages,
  }) {
    // Cancel any existing timer
    _renderTimer?.cancel();

    // Update context
    _currentDocument = document;
    _currentDocumentId = documentId;
    _currentPage = currentPage;
    _totalPages = totalPages;

    // Schedule rendering with a small delay to avoid blocking UI
    _renderTimer = Timer(const Duration(milliseconds: 300), () {
      _performBackgroundRendering();
    });
  }

  /// Perform background rendering
  Future<void> _performBackgroundRendering() async {
    if (_isRendering || _currentDocument == null || _currentDocumentId == null || _currentPage == null || _totalPages == null) {
      return;
    }

    _isRendering = true;

    try {
      debugPrint('Background pre-loading pages around page $_currentPage');

      // Determine pages to pre-load
      final List<int> pagesToLoad = _getPagesToRender(
        _currentPage!,
        _totalPages!,
      );

      // Mark pages as accessed for pre-loading
      for (final int pageNumber in pagesToLoad) {
        if (!_accessedPages.contains(pageNumber)) {
          _accessedPages.add(pageNumber);
          debugPrint('Pre-loading page $pageNumber');

          // Simply access the page to trigger pdfrx's internal caching
          try {
            if (pageNumber > 0 && pageNumber <= _currentDocument!.pages.length) {
              // Access page to trigger internal caching
              final PdfPage page = _currentDocument!.pages[pageNumber - 1];
              // Accessing page properties triggers internal caching
              debugPrint('Page $pageNumber size: ${page.width}x${page.height}');
            }
          } catch (e) {
            debugPrint('Error pre-loading page $pageNumber: $e');
          }

          // Add a small delay between loads to avoid blocking
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      debugPrint('Background pre-loading completed');
    } finally {
      _isRendering = false;
    }
  }

  /// Get list of pages to render in priority order
  List<int> _getPagesToRender(int currentPage, int totalPages) {
    final List<int> pages = [];
    final int buffer = AppConfig.preRenderBufferPages;

    // Priority: current page first, then alternating ahead and behind
    pages.add(currentPage);

    for (int i = 1; i <= buffer; i++) {
      // Add pages ahead first (more likely to navigate forward)
      final int nextPage = currentPage + i;
      if (nextPage <= totalPages) {
        pages.add(nextPage);
      }

      // Then add pages behind
      final int prevPage = currentPage - i;
      if (prevPage >= 1) {
        pages.add(prevPage);
      }
    }

    return pages;
  }

  /// Cancel any pending rendering
  void cancelRendering() {
    _renderTimer?.cancel();
    _renderTimer = null;
    _isRendering = false;
  }

  /// Clear current rendering context
  void clearContext() {
    cancelRendering();
    _currentDocument = null;
    _currentDocumentId = null;
    _currentPage = null;
    _totalPages = null;
    _accessedPages.clear();
  }

  /// Dispose and cleanup
  void dispose() {
    cancelRendering();
    clearContext();
  }
}
