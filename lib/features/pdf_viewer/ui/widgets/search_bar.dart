import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pdf_viewer_bloc.dart';
import '../../bloc/pdf_viewer_event.dart';

/// Widget for search bar with controls
class SearchBar extends StatefulWidget {
  final String? query;
  final int currentResultIndex;
  final int totalResults;
  final bool isSearching;
  final VoidCallback onClose;

  const SearchBar({
    super.key,
    this.query,
    required this.currentResultIndex,
    required this.totalResults,
    required this.isSearching,
    required this.onClose,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query ?? '');
    // Auto-focus search field when search bar is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text if the query from the state is different from what's in the controller
    // AND it's not null/empty (to prevent clearing user input)
    if (widget.query != oldWidget.query &&
        widget.query != null &&
        widget.query!.isNotEmpty &&
        widget.query != _searchController.text) {
      _searchController.text = widget.query!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<PdfViewerBloc>().add(SearchQueryChanged(query));
      // Keep focus in the search field after submitting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasResults = widget.totalResults > 0;
    final bool canNavigate = hasResults && !widget.isSearching;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          Icon(
            Icons.search,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),

          // Search input field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: Theme.of(context).textTheme.bodyMedium,
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Search in document...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _handleSubmit(),
              onChanged: (String value) {
                if (value.isEmpty) {
                  context.read<PdfViewerBloc>().add(const SearchClosed());
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // Loading indicator or result count
          if (widget.isSearching)
            SizedBox(
              width: 70,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (hasResults)
            SizedBox(
              width: 70,
              child: Text(
                '${widget.currentResultIndex + 1} of ${widget.totalResults}',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            )
          else if (_searchController.text.isNotEmpty)
            SizedBox(
              width: 70,
              child: Text(
                'No results',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            const SizedBox(width: 70),

          // Previous result button
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
            tooltip: 'Previous (Shift+Enter)',
            onPressed: canNavigate ? () => context.read<PdfViewerBloc>().add(const SearchPreviousRequested()) : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Next result button
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            tooltip: 'Next (Enter)',
            onPressed: canNavigate ? () => context.read<PdfViewerBloc>().add(const SearchNextRequested()) : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close search (Esc)',
            onPressed: widget.onClose,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
