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
      color: isActive
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: bookmark.hasValidDestination ? onTap : null,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.0 + indentation,
            right: 12.0,
            top: 6.0,
            bottom: 6.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Expand/collapse chevron for items with children
              if (bookmark.hasChildren)
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(width: 22),
              // Bookmark title
              Expanded(
                child: Text(
                  bookmark.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: bookmark.hasValidDestination
                        ? (isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface)
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Page number (if available)
              if (bookmark.pageNumber != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${bookmark.pageNumber}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
