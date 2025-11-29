import 'package:flutter/material.dart';

import '../../models/pdf_bookmark_item.dart';

/// Individual bookmark item widget with hierarchy support
class BookmarkListItem extends StatelessWidget {
  final PdfBookmarkItem bookmark;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;

  const BookmarkListItem({
    super.key,
    required this.bookmark,
    this.isExpanded = false,
    this.isActive = false,
    this.onTap,
    this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Limit indentation to 5 levels max for deep nesting
    final int effectiveLevel = bookmark.level > 5 ? 5 : bookmark.level;
    final double indentation = effectiveLevel * 16.0;

    return Material(
      color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: bookmark.hasValidDestination ? onTap : null,
        child: Padding(
          padding: EdgeInsets.only(
            left: 8.0 + indentation,
            right: 8.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expand/collapse chevron for items with children
              if (bookmark.hasChildren)
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              // Bookmark title
              Expanded(
                child: Text(
                  bookmark.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: bookmark.hasValidDestination
                        ? (isActive ? Colors.blue[700] : Colors.black87)
                        : Colors.grey[500],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Page number (if available)
              if (bookmark.pageNumber != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '${bookmark.pageNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
