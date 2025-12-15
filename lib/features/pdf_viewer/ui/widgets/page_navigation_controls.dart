import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for page navigation controls
class PageNavigationControls extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final Function(int) onPageChanged;

  const PageNavigationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageChanged,
  });

  @override
  State<PageNavigationControls> createState() => _PageNavigationControlsState();
}

class _PageNavigationControlsState extends State<PageNavigationControls> {
  final TextEditingController _pageController = TextEditingController();
  bool _isEditingPage = false;

  @override
  void initState() {
    super.initState();
    _pageController.text = widget.currentPage.toString();
  }

  @override
  void didUpdateWidget(PageNavigationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingPage && widget.currentPage != oldWidget.currentPage) {
      _pageController.text = widget.currentPage.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageSubmit() {
    final String text = _pageController.text.trim();
    if (text.isEmpty) {
      _pageController.text = widget.currentPage.toString();
      setState(() => _isEditingPage = false);
      return;
    }

    final int? pageNumber = int.tryParse(text);
    if (pageNumber != null && pageNumber >= 1 && pageNumber <= widget.totalPages) {
      widget.onPageChanged(pageNumber);
      setState(() => _isEditingPage = false);
    } else {
      // Invalid page number, reset to current
      _pageController.text = widget.currentPage.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a page number between 1 and ${widget.totalPages}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoPrevious = widget.currentPage > 1;
    final bool canGoNext = widget.currentPage < widget.totalPages;
    final bool canGoToFirst = widget.currentPage > 1;
    final bool canGoToLast = widget.currentPage < widget.totalPages;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page button
          IconButton(
            icon: const Icon(Icons.first_page, size: 20),
            onPressed: canGoToFirst ? () => widget.onPageChanged(1) : null,
            tooltip: 'First page (Home)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 4),

          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: canGoPrevious ? widget.onPreviousPage : null,
            tooltip: 'Previous page (← or PgUp)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 12),

          // Page indicator and input
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page ',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                width: 45,
                height: 28,
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() => _isEditingPage = true);
                    _pageController.selection = TextSelection(baseOffset: 0, extentOffset: _pageController.text.length);
                  },
                  onSubmitted: (String value) => _handlePageSubmit(),
                  onEditingComplete: _handlePageSubmit,
                ),
              ),
              Text(
                ' of ${widget.totalPages}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: canGoNext ? widget.onNextPage : null,
            tooltip: 'Next page (→ or PgDn)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 4),

          // Last page button
          IconButton(
            icon: const Icon(Icons.last_page, size: 20),
            onPressed: canGoToLast ? () => widget.onPageChanged(widget.totalPages) : null,
            tooltip: 'Last page (End)',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
