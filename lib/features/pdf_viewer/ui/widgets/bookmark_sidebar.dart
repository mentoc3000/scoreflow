import 'package:flutter/material.dart';

import '../../models/pdf_bookmark_item.dart';
import 'bookmark_list_item.dart';

/// Collapsible sidebar for displaying PDF bookmarks
class BookmarkSidebar extends StatefulWidget {
  final List<PdfBookmarkItem> bookmarks;
  final bool isOpen;
  final double width;
  final VoidCallback onToggle;
  final Function(int pageNumber) onBookmarkTap;
  final int currentPage;

  const BookmarkSidebar({
    super.key,
    required this.bookmarks,
    required this.isOpen,
    required this.width,
    required this.onToggle,
    required this.onBookmarkTap,
    required this.currentPage,
  });

  @override
  State<BookmarkSidebar> createState() => _BookmarkSidebarState();
}

class _BookmarkSidebarState extends State<BookmarkSidebar> {
  final Set<String> _expandedNodes = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getNodeId(PdfBookmarkItem bookmark, int index) {
    return '${bookmark.level}_${index}_${bookmark.title}';
  }

  bool _isExpanded(PdfBookmarkItem bookmark, int index) {
    return _expandedNodes.contains(_getNodeId(bookmark, index));
  }

  void _toggleExpanded(PdfBookmarkItem bookmark, int index) {
    setState(() {
      final String nodeId = _getNodeId(bookmark, index);
      if (_expandedNodes.contains(nodeId)) {
        _expandedNodes.remove(nodeId);
      } else {
        _expandedNodes.add(nodeId);
      }
    });
  }

  bool _isBookmarkActive(PdfBookmarkItem bookmark) {
    return bookmark.pageNumber == widget.currentPage;
  }

  List<Widget> _buildBookmarkTree(List<PdfBookmarkItem> bookmarks, int startIndex) {
    final List<Widget> widgets = [];

    for (int i = 0; i < bookmarks.length; i++) {
      final PdfBookmarkItem bookmark = bookmarks[i];
      final int index = startIndex + i;
      final bool isExpanded = _isExpanded(bookmark, index);
      final bool isActive = _isBookmarkActive(bookmark);

      widgets.add(
        BookmarkListItem(
          bookmark: bookmark,
          isExpanded: isExpanded,
          isActive: isActive,
          onTap: bookmark.hasValidDestination ? () => widget.onBookmarkTap(bookmark.pageNumber!) : null,
          onExpandToggle: bookmark.hasChildren ? () => _toggleExpanded(bookmark, index) : null,
        ),
      );

      // Add children if expanded
      if (isExpanded && bookmark.hasChildren) {
        widgets.addAll(_buildBookmarkTree(bookmark.children, index * 1000));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: widget.isOpen ? widget.width : 0,
      child: widget.isOpen
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bookmarks',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: widget.onToggle,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Close bookmarks (⌘B)',
                        ),
                      ],
                    ),
                  ),
                  // Bookmark list
                  Expanded(
                    child: widget.bookmarks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No bookmarks',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: _buildBookmarkTree(widget.bookmarks, 0),
                          ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
