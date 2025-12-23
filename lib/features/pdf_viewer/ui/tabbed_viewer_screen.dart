import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import '../bloc/tab_manager_bloc.dart';
import '../bloc/tab_manager_event.dart';
import '../bloc/tab_manager_state.dart';
import '../models/base_tab.dart';
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
            final BaseTab? activeTab = tabState.activeTab;

            // First, check if this file is already open in another tab
            final BaseTab? existingTab = tabState.tabs.cast<BaseTab?>().firstWhere(
              (tab) =>
                  tab != null && tab is DocumentTab && tab.filePath == pdfState.filePath && tab.id != activeTab?.id,
              orElse: () => null,
            );

            if (existingTab != null) {
              // File is already open in another tab, switch to it
              context.read<TabManagerBloc>().add(TabSwitched(existingTab.id));
              return;
            }

            // If the active tab is a home tab, transform it into a document tab
            if (activeTab != null && activeTab is HomeTab) {
              // Create a new document tab to replace the home tab
              final DocumentTab documentTab = DocumentTab.fromPath(pdfState.filePath);

              // Update the tab manager - use the same ID to replace the home tab
              context.read<TabManagerBloc>().add(TabOpened(documentTab.copyWith(id: activeTab.id)));
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    if (widget.tabState.activeTab != null && widget.tabState.activeTab is DocumentTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final DocumentTab docTab = widget.tabState.activeTab! as DocumentTab;
        final PdfViewerState pdfState = context.read<PdfViewerBloc>().state;

        // Only load if:
        // 1. No document is currently loaded OR loading, AND
        // 2. The loaded document is different from the active tab
        if (pdfState is PdfViewerInitial) {
          // No document loaded at all, load the active tab's document
          context.read<PdfViewerBloc>().add(RecentFileOpened(docTab.filePath));

          // After loading, restore saved state if it exists
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            final PdfViewerState newState = context.read<PdfViewerBloc>().state;
            if (newState is PdfViewerLoaded) {
              final TabState? savedState = widget.tabState.tabStates[docTab.id];
              if (savedState != null) {
                // Restore saved state
                if (savedState.currentPage != 1) {
                  context.read<PdfViewerBloc>().add(PageNumberChanged(savedState.currentPage));
                }
                if (savedState.zoomLevel != 1.0) {
                  context.read<PdfViewerBloc>().add(ZoomChanged(savedState.zoomLevel));
                }
                if (savedState.isBookmarkSidebarOpen) {
                  context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                }
                if (savedState.isDistractionFreeMode) {
                  context.read<PdfViewerBloc>().add(const DistractionFreeModeToggled());
                }
              }
            }
          });
        } else if (pdfState is PdfViewerLoaded && pdfState.filePath != docTab.filePath) {
          // Different document is loaded, switch to active tab's document
          context.read<PdfViewerBloc>().add(RecentFileOpened(docTab.filePath));
        }
        // If PdfViewerLoading or already loaded correct document, do nothing
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact tab bar with integrated controls
        _TabBar(tabState: widget.tabState),
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
                  isDistractionFreeMode: pdfState.isDistractionFreeMode,
                );
                context.read<TabManagerBloc>().add(TabStateUpdated(currentTabState));
              }
            },
            child: widget.tabState.activeTab is HomeTab
                ? const HomeScreen()
                : widget.tabState.activeTab is ConfigTab
                ? const Center(child: Text('Config Screen - Coming Soon!'))
                : const PdfViewerScreen(),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatefulWidget {
  final BaseTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({required this.tab, required this.isActive, required this.onTap, required this.onClose});

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // Middle mouse button has kMiddleMouseButton = 4
        if (event.buttons == 4) {
          widget.onClose();
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : _isHovered
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // File icon
                    Icon(
                      _getIconForTab(widget.tab),
                      size: 16,
                      color: widget.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    // File name (truncated if too long)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        widget.tab.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                          color: widget.isActive
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close button
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _isHovered || widget.isActive
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTab(BaseTab tab) {
    if (tab is HomeTab) return Icons.home;
    if (tab is ConfigTab) return Icons.settings;
    if (tab is DocumentTab) return Icons.description;
    return Icons.tab;
  }
}

/// Extracted tab bar widget to minimize rebuilds
class _TabBar extends StatelessWidget {
  final TabManagerLoaded tabState;

  const _TabBar({required this.tabState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final BaseTab tab in tabState.tabs)
                    _TabItem(
                      tab: tab,
                      isActive: tab.id == tabState.activeTabId,
                      onTap: () {
                        // Switch to the tab
                        context.read<TabManagerBloc>().add(TabSwitched(tab.id));

                        // If it's a document tab, load the document
                        if (tab is DocumentTab) {
                          final PdfViewerState currentState = context.read<PdfViewerBloc>().state;
                          // Only reload if it's a different document
                          if (currentState is! PdfViewerLoaded || currentState.filePath != tab.filePath) {
                            context.read<PdfViewerBloc>().add(RecentFileOpened(tab.filePath));
                          } else {
                            // Same document (currentState is PdfViewerLoaded), restore saved tab state
                            final TabState? savedState = tabState.tabStates[tab.id];
                            if (savedState != null) {
                              // Restore page, zoom, sidebar state
                              if (savedState.currentPage != currentState.currentPage) {
                                context.read<PdfViewerBloc>().add(PageNumberChanged(savedState.currentPage));
                              }
                              if (savedState.zoomLevel != currentState.zoomLevel) {
                                context.read<PdfViewerBloc>().add(ZoomChanged(savedState.zoomLevel));
                              }
                              if (savedState.isBookmarkSidebarOpen != currentState.isBookmarkSidebarOpen) {
                                context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                              }
                              if (savedState.isDistractionFreeMode != currentState.isDistractionFreeMode) {
                                context.read<PdfViewerBloc>().add(const DistractionFreeModeToggled());
                              }
                            }
                          }
                        } else if (tab is HomeTab) {
                          // Close current document when switching to home tab
                          final PdfViewerState currentState = context.read<PdfViewerBloc>().state;
                          if (currentState is PdfViewerLoaded) {
                            context.read<PdfViewerBloc>().add(const FileClosed());
                          }
                        }
                      },
                      onClose: () {
                        // If closing the active document tab, close the PDF viewer too
                        if (tab.id == tabState.activeTabId && tab is DocumentTab) {
                          final PdfViewerState currentState = context.read<PdfViewerBloc>().state;
                          if (currentState is PdfViewerLoaded && currentState.filePath == tab.filePath) {
                            context.read<PdfViewerBloc>().add(const FileClosed());
                          }
                        }
                        context.read<TabManagerBloc>().add(TabClosed(tab.id));
                      },
                    ),
                ],
              ),
            ),
          ),
          // New tab button
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New home tab',
            onPressed: () {
              context.read<TabManagerBloc>().add(const TabOpenRequested());
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
