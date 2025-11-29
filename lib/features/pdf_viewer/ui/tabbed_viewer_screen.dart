import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import '../bloc/tab_manager_bloc.dart';
import '../bloc/tab_manager_event.dart';
import '../bloc/tab_manager_state.dart';
import '../models/document_tab.dart';
import '../models/tab_state.dart';
import 'home_screen.dart';
import 'pdf_viewer_screen.dart';

/// Screen that manages multiple PDF document tabs
class TabbedViewerScreen extends StatelessWidget {
  const TabbedViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PdfViewerBloc, PdfViewerState>(
      listener: (BuildContext context, PdfViewerState pdfState) {
        // When a document is loaded, transform the active home tab into a document tab
        if (pdfState is PdfViewerLoaded) {
          final TabManagerState tabState = context.read<TabManagerBloc>().state;

          if (tabState is TabManagerLoaded) {
            final DocumentTab? activeTab = tabState.activeTab;

            // First, check if this file is already open in another tab
            final DocumentTab? existingTab = tabState.tabs.cast<DocumentTab?>().firstWhere(
              (tab) => tab != null && !tab.isHomeTab && tab.filePath == pdfState.filePath && tab.id != activeTab?.id,
              orElse: () => null,
            );

            if (existingTab != null) {
              // File is already open in another tab, switch to it
              context.read<TabManagerBloc>().add(TabSwitched(existingTab.id));
              return;
            }

            // If the active tab is a home tab, transform it into a document tab
            if (activeTab != null && activeTab.isHomeTab) {
              // Create a new document tab to replace the home tab
              final DocumentTab documentTab = DocumentTab.fromPath(pdfState.filePath);

              // Update the tab manager - use the same ID to replace the home tab
              context.read<TabManagerBloc>().add(
                TabOpened(documentTab.copyWith(id: activeTab.id)),
              );
            }
          }
        }
      },
      child: BlocBuilder<TabManagerBloc, TabManagerState>(
        builder: (BuildContext context, TabManagerState tabState) {
          // Show home screen when no tabs are open (shouldn't happen now)
          if (tabState is TabManagerInitial) {
            return const HomeScreen();
          }

          // Show loading while restoring tabs
          if (tabState is TabManagerLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Show error if tab management fails
          if (tabState is TabManagerError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(tabState.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TabManagerBloc>().add(const AllTabsClosed());
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show tabs when loaded
          if (tabState is TabManagerLoaded) {
            return _TabbedViewerContent(tabState: tabState);
          }

          // Fallback
          return const HomeScreen();
        },
      ),
    );
  }
}

class _TabbedViewerContent extends StatefulWidget {
  final TabManagerLoaded tabState;

  const _TabbedViewerContent({required this.tabState});

  @override
  State<_TabbedViewerContent> createState() => _TabbedViewerContentState();
}

class _TabbedViewerContentState extends State<_TabbedViewerContent> {
  @override
  void initState() {
    super.initState();
    // Load the active tab's document when this screen first appears
    // Only if it's not a home tab
    if (widget.tabState.activeTab != null && !widget.tabState.activeTab!.isHomeTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final PdfViewerState pdfState = context.read<PdfViewerBloc>().state;

        // Only load if:
        // 1. No document is currently loaded OR loading, AND
        // 2. The loaded document is different from the active tab
        if (pdfState is PdfViewerInitial) {
          // No document loaded at all, load the active tab's document
          context.read<PdfViewerBloc>().add(
            RecentFileOpened(widget.tabState.activeTab!.filePath),
          );
        } else if (pdfState is PdfViewerLoaded &&
                   pdfState.filePath != widget.tabState.activeTab!.filePath) {
          // Different document is loaded, switch to active tab's document
          context.read<PdfViewerBloc>().add(
            RecentFileOpened(widget.tabState.activeTab!.filePath),
          );
        }
        // If PdfViewerLoading or already loaded correct document, do nothing
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
              children: [
                // Tabs
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final DocumentTab tab in widget.tabState.tabs)
                          _TabItem(
                            tab: tab,
                            isActive: tab.id == widget.tabState.activeTabId,
                            onTap: () {
                              // Switch to the tab
                              context.read<TabManagerBloc>().add(TabSwitched(tab.id));

                              // If it's not a home tab, load the document
                              if (!tab.isHomeTab) {
                                final PdfViewerState currentState = context.read<PdfViewerBloc>().state;
                                // Only reload if it's a different document
                                if (currentState is! PdfViewerLoaded ||
                                    currentState.filePath != tab.filePath) {
                                  context.read<PdfViewerBloc>().add(RecentFileOpened(tab.filePath));
                                }
                              }
                            },
                            onClose: () {
                              context.read<TabManagerBloc>().add(TabClosed(tab.id));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              // New tab button
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New home tab',
                onPressed: () {
                  context.read<TabManagerBloc>().add(const TabOpenRequested());
                },
              ),
            ],
          ),
        ),
        // Active tab content
        Expanded(
          child: BlocListener<PdfViewerBloc, PdfViewerState>(
            listener: (BuildContext context, PdfViewerState pdfState) {
              // Update tab state when PDF viewer state changes
              if (pdfState is PdfViewerLoaded && widget.tabState.activeTabId != null) {
                final TabState currentTabState = TabState(
                  tabId: widget.tabState.activeTabId!,
                  currentPage: pdfState.currentPage,
                  zoomLevel: pdfState.zoomLevel,
                  isBookmarkSidebarOpen: pdfState.isBookmarkSidebarOpen,
                  searchQuery: pdfState.searchQuery,
                );
                context.read<TabManagerBloc>().add(TabStateUpdated(currentTabState));
              }
            },
            child: widget.tabState.activeTab?.isHomeTab == true
                ? const HomeScreen()
                : const PdfViewerScreen(),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final DocumentTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File icon
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 8),
              // File name (truncated if too long)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  tab.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
