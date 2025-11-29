import 'package:equatable/equatable.dart';

import '../models/document_tab.dart';
import '../models/tab_state.dart';

/// Base class for all tab manager states
abstract class TabManagerState extends Equatable {
  const TabManagerState();

  @override
  List<Object?> get props => [];
}

/// Initial state with no tabs open
class TabManagerInitial extends TabManagerState {
  const TabManagerInitial();
}

/// State when tabs are being loaded from persistence
class TabManagerLoading extends TabManagerState {
  const TabManagerLoading();
}

/// State when tabs are open and being managed
class TabManagerLoaded extends TabManagerState {
  final List<DocumentTab> tabs;
  final String? activeTabId;
  final Map<String, TabState> tabStates; // Map of tabId to its state

  const TabManagerLoaded({
    required this.tabs,
    this.activeTabId,
    this.tabStates = const {},
  });

  /// Gets the active tab
  DocumentTab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the state for a specific tab
  TabState? getTabState(String tabId) {
    return tabStates[tabId];
  }

  /// Gets the active tab's state
  TabState? get activeTabState {
    if (activeTabId == null) return null;
    return tabStates[activeTabId];
  }

  /// Checks if any tabs are open
  bool get hasTabs => tabs.isNotEmpty;

  /// Creates a copy with updated values
  TabManagerLoaded copyWith({
    List<DocumentTab>? tabs,
    String? activeTabId,
    Map<String, TabState>? tabStates,
  }) {
    return TabManagerLoaded(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      tabStates: tabStates ?? this.tabStates,
    );
  }

  @override
  List<Object?> get props => [tabs, activeTabId, tabStates];
}

/// State when there's an error with tab management
class TabManagerError extends TabManagerState {
  final String message;

  const TabManagerError(this.message);

  @override
  List<Object?> get props => [message];
}
