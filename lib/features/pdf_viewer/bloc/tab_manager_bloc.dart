import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../models/base_tab.dart';
import '../models/tab_state.dart';
import '../repositories/tab_persistence_repository.dart';
import 'tab_manager_event.dart';
import 'tab_manager_state.dart';

/// BLoC for managing multiple document tabs
class TabManagerBloc extends Bloc<TabManagerEvent, TabManagerState> {
  final TabPersistenceRepository _persistenceRepository;

  TabManagerBloc({required TabPersistenceRepository persistenceRepository})
    : _persistenceRepository = persistenceRepository,
      super(const TabManagerInitial()) {
    on<TabsRestoreRequested>(_onTabsRestoreRequested);
    on<TabOpenRequested>(_onTabOpenRequested);
    on<TabOpened>(_onTabOpened);
    on<TabSwitched>(_onTabSwitched);
    on<TabClosed>(_onTabClosed);
    on<TabStateUpdated>(_onTabStateUpdated);
    on<AllTabsClosed>(_onAllTabsClosed);
    on<ConfigTabRequested>(_onConfigTabRequested);
    on<TabsReordered>(_onTabsReordered);
  }

  /// Restores tabs from persistence on app startup
  Future<void> _onTabsRestoreRequested(TabsRestoreRequested event, Emitter<TabManagerState> emit) async {
    emit(const TabManagerLoading());

    try {
      final List<BaseTab> tabs = await _persistenceRepository.loadTabs();
      final Map<String, TabState> tabStates = await _persistenceRepository.loadTabStates();

      if (tabs.isEmpty) {
        // No tabs, create a home tab
        final HomeTab homeTab = HomeTab.create();
        emit(
          TabManagerLoaded(
            tabs: [homeTab],
            activeTabId: homeTab.id,
            tabStates: {homeTab.id: TabState(tabId: homeTab.id)},
          ),
        );
      } else {
        // Set the first tab as active
        emit(TabManagerLoaded(tabs: tabs, activeTabId: tabs.first.id, tabStates: tabStates));
      }
    } catch (e) {
      emit(TabManagerError('Failed to restore tabs: ${e.toString()}'));
    }
  }

  /// Handles request to open a new tab
  Future<void> _onTabOpenRequested(TabOpenRequested event, Emitter<TabManagerState> emit) async {
    final TabManagerState currentState = state;

    // Check if we're at max tabs
    if (currentState is TabManagerLoaded && currentState.tabs.length >= AppConfig.maxTabs) {
      emit(TabManagerError('Maximum of ${AppConfig.maxTabs} tabs reached'));
      // Restore the previous state after showing error
      emit(currentState);
      return;
    }

    // Create the tab
    final BaseTab newTab;
    if (event.filePath.isEmpty) {
      // Create home tab
      newTab = HomeTab.create();
    } else {
      // Create document tab
      newTab = DocumentTab.fromPath(event.filePath, bookmark: event.bookmark);
    }

    add(TabOpened(newTab));
  }

  /// Handles a tab being successfully opened
  Future<void> _onTabOpened(TabOpened event, Emitter<TabManagerState> emit) async {
    final TabManagerState currentState = state;

    List<BaseTab> tabs = [];
    Map<String, TabState> tabStates = {};
    String? activeTabId;

    if (currentState is TabManagerLoaded) {
      // Check if we're replacing an existing tab (same ID)
      final int existingIndex = currentState.tabs.indexWhere((tab) => tab.id == event.tab.id);

      if (existingIndex != -1) {
        // Replace the tab at this index
        tabs = List.from(currentState.tabs);
        tabs[existingIndex] = event.tab;
        tabStates = Map.from(currentState.tabStates);
        activeTabId = event.tab.id;

        // Keep or create tab state
        if (!tabStates.containsKey(event.tab.id)) {
          tabStates[event.tab.id] = TabState(tabId: event.tab.id);
        }
      } else {
        // Check if tab with same file path already exists (for document tabs)
        if (event.tab is DocumentTab) {
          final DocumentTab docTab = event.tab as DocumentTab;
          final int pathIndex = currentState.tabs.indexWhere(
            (tab) => tab is DocumentTab && tab.filePath == docTab.filePath,
          );

          if (pathIndex != -1) {
            // Tab with same file already exists, just switch to it
            activeTabId = currentState.tabs[pathIndex].id;
            emit(currentState.copyWith(activeTabId: activeTabId));
            await _persistenceRepository.saveActiveTabId(activeTabId);
            return;
          }
        }

        // Add new tab
        tabs = List.from(currentState.tabs);
        tabs.add(event.tab);
        tabStates = Map.from(currentState.tabStates);
        tabStates[event.tab.id] = TabState(tabId: event.tab.id);
        activeTabId = event.tab.id;
      }
    } else {
      // First tab
      tabs = [event.tab];
      tabStates = {event.tab.id: TabState(tabId: event.tab.id)};
      activeTabId = event.tab.id;
    }

    final TabManagerLoaded newState = TabManagerLoaded(tabs: tabs, activeTabId: activeTabId, tabStates: tabStates);

    emit(newState);

    // Persist the changes
    await _persistenceRepository.saveTabs(tabs);
    await _persistenceRepository.saveTabStates(tabStates);
    await _persistenceRepository.saveActiveTabId(activeTabId);
  }

  /// Handles switching to a different tab
  Future<void> _onTabSwitched(TabSwitched event, Emitter<TabManagerState> emit) async {
    if (state is TabManagerLoaded) {
      final TabManagerLoaded currentState = state as TabManagerLoaded;

      // Verify the tab exists
      final bool tabExists = currentState.tabs.any((tab) => tab.id == event.tabId);

      if (!tabExists) {
        return;
      }

      emit(currentState.copyWith(activeTabId: event.tabId));

      // Persist the active tab change
      await _persistenceRepository.saveActiveTabId(event.tabId);
    }
  }

  /// Handles closing a tab
  Future<void> _onTabClosed(TabClosed event, Emitter<TabManagerState> emit) async {
    if (state is TabManagerLoaded) {
      final TabManagerLoaded currentState = state as TabManagerLoaded;

      // Remove the tab
      final List<BaseTab> updatedTabs = currentState.tabs.where((tab) => tab.id != event.tabId).toList();

      // Remove the tab's state
      final Map<String, TabState> updatedTabStates = Map.from(currentState.tabStates);
      updatedTabStates.remove(event.tabId);

      // Determine new active tab
      String? newActiveTabId;
      if (updatedTabs.isEmpty) {
        // No tabs left, create a new home tab
        final HomeTab homeTab = HomeTab.create();
        final Map<String, TabState> newTabStates = {homeTab.id: TabState(tabId: homeTab.id)};

        emit(TabManagerLoaded(tabs: [homeTab], activeTabId: homeTab.id, tabStates: newTabStates));

        await _persistenceRepository.saveTabs([homeTab]);
        await _persistenceRepository.saveTabStates(newTabStates);
        await _persistenceRepository.saveActiveTabId(homeTab.id);
        return;
      } else if (currentState.activeTabId == event.tabId) {
        // Closed the active tab, switch to the last tab
        newActiveTabId = updatedTabs.last.id;
      } else {
        // Keep the current active tab
        newActiveTabId = currentState.activeTabId;
      }

      emit(TabManagerLoaded(tabs: updatedTabs, activeTabId: newActiveTabId, tabStates: updatedTabStates));

      // Persist the changes
      await _persistenceRepository.saveTabs(updatedTabs);
      await _persistenceRepository.saveTabStates(updatedTabStates);
      if (newActiveTabId != null) {
        await _persistenceRepository.saveActiveTabId(newActiveTabId);
      }
    }
  }

  /// Handles updating a tab's state
  Future<void> _onTabStateUpdated(TabStateUpdated event, Emitter<TabManagerState> emit) async {
    if (state is TabManagerLoaded) {
      final TabManagerLoaded currentState = state as TabManagerLoaded;

      // Update the tab state
      final Map<String, TabState> updatedTabStates = Map.from(currentState.tabStates);
      updatedTabStates[event.tabState.tabId] = event.tabState;

      emit(currentState.copyWith(tabStates: updatedTabStates));

      // Persist the updated state
      await _persistenceRepository.saveTabStates(updatedTabStates);
    }
  }

  /// Handles closing all tabs
  Future<void> _onAllTabsClosed(AllTabsClosed event, Emitter<TabManagerState> emit) async {
    emit(const TabManagerInitial());
    await _persistenceRepository.clearTabs();
  }

  /// Handles request to open a config tab
  Future<void> _onConfigTabRequested(ConfigTabRequested event, Emitter<TabManagerState> emit) async {
    final TabManagerState currentState = state;

    // Check if we're at max tabs
    if (currentState is TabManagerLoaded && currentState.tabs.length >= AppConfig.maxTabs) {
      emit(TabManagerError('Maximum of ${AppConfig.maxTabs} tabs reached'));
      // Restore the previous state after showing error
      emit(currentState);
      return;
    }

    // Check if config tab already exists
    if (currentState is TabManagerLoaded) {
      final int configIndex = currentState.tabs.indexWhere((tab) => tab is ConfigTab);

      if (configIndex != -1) {
        // Config tab already open, just switch to it
        final String configTabId = currentState.tabs[configIndex].id;
        emit(currentState.copyWith(activeTabId: configTabId));
        await _persistenceRepository.saveActiveTabId(configTabId);
        return;
      }
    }

    // Create new config tab
    final ConfigTab configTab = ConfigTab.create();
    add(TabOpened(configTab));
  }

  /// Handles reordering tabs
  Future<void> _onTabsReordered(TabsReordered event, Emitter<TabManagerState> emit) async {
    if (state is TabManagerLoaded) {
      final TabManagerLoaded currentState = state as TabManagerLoaded;

      // Create a new list with the reordered tabs
      final List<BaseTab> reorderedTabs = List.from(currentState.tabs);

      // Remove the tab from the old position
      final BaseTab movedTab = reorderedTabs.removeAt(event.oldIndex);

      // Insert it at the new position
      reorderedTabs.insert(event.newIndex, movedTab);

      emit(currentState.copyWith(tabs: reorderedTabs));

      // Persist the changes
      await _persistenceRepository.saveTabs(reorderedTabs);
    }
  }
}
