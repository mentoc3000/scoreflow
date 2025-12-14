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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page button
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: canGoToFirst ? () => widget.onPageChanged(1) : null,
            tooltip: 'First page (Home)',
          ),

          const SizedBox(width: 8),

          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoPrevious ? widget.onPreviousPage : null,
            tooltip: 'Previous page (← or PgUp)',
          ),

          const SizedBox(width: 16),

          // Page indicator and input
          Row(
            children: [
              const Text('Page ', style: TextStyle(fontSize: 16)),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    setState(() => _isEditingPage = true);
                    _pageController.selection = TextSelection(baseOffset: 0, extentOffset: _pageController.text.length);
                  },
                  onSubmitted: (String value) => _handlePageSubmit(),
                  onEditingComplete: _handlePageSubmit,
                ),
              ),
              Text(' of ${widget.totalPages}', style: const TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(width: 16),

          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? widget.onNextPage : null,
            tooltip: 'Next page (→ or PgDn)',
          ),

          const SizedBox(width: 8),

          // Last page button
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: canGoToLast ? () => widget.onPageChanged(widget.totalPages) : null,
            tooltip: 'Last page (End)',
          ),
        ],
      ),
    );
  }
}
