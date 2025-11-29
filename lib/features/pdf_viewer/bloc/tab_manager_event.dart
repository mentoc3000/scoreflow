import 'package:equatable/equatable.dart';

import '../models/document_tab.dart';
import '../models/tab_state.dart';

/// Base class for all tab manager events
abstract class TabManagerEvent extends Equatable {
  const TabManagerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to restore tabs from persistence on app startup
class TabsRestoreRequested extends TabManagerEvent {
  const TabsRestoreRequested();
}

/// Event to open a new tab
class TabOpenRequested extends TabManagerEvent {
  final String filePath; // Empty string for home tab
  final String? bookmark;

  const TabOpenRequested({
    this.filePath = '',
    this.bookmark,
  });

  @override
  List<Object?> get props => [filePath, bookmark];
}

/// Event when a tab is successfully opened with a document
class TabOpened extends TabManagerEvent {
  final DocumentTab tab;

  const TabOpened(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Event to switch to a different tab
class TabSwitched extends TabManagerEvent {
  final String tabId;

  const TabSwitched(this.tabId);

  @override
  List<Object?> get props => [tabId];
}

/// Event to close a tab
class TabClosed extends TabManagerEvent {
  final String tabId;

  const TabClosed(this.tabId);

  @override
  List<Object?> get props => [tabId];
}

/// Event to update a tab's state
class TabStateUpdated extends TabManagerEvent {
  final TabState tabState;

  const TabStateUpdated(this.tabState);

  @override
  List<Object?> get props => [tabState];
}

/// Event to close all tabs and return to home screen
class AllTabsClosed extends TabManagerEvent {
  const AllTabsClosed();
}
