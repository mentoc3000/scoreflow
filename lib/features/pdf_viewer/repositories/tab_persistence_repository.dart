import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_tab.dart';
import '../models/tab_state.dart';

/// Repository for persisting and restoring tab state
class TabPersistenceRepository {
  final SharedPreferences _prefs;

  static const String _tabsKey = 'open_tabs';
  static const String _tabStatesKey = 'tab_states';
  static const String _activeTabIdKey = 'active_tab_id';

  TabPersistenceRepository(this._prefs);

  /// Saves the list of open tabs
  Future<void> saveTabs(List<DocumentTab> tabs) async {
    final List<Map<String, dynamic>> tabsJson = tabs.map((tab) => tab.toJson()).toList();
    await _prefs.setString(_tabsKey, jsonEncode(tabsJson));
  }

  /// Loads the list of open tabs
  Future<List<DocumentTab>> loadTabs() async {
    final String? tabsJson = _prefs.getString(_tabsKey);

    if (tabsJson == null || tabsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(tabsJson) as List<dynamic>;
      return decoded
          .map((json) => DocumentTab.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  /// Saves the tab states map
  Future<void> saveTabStates(Map<String, TabState> tabStates) async {
    final Map<String, dynamic> statesJson = {};
    tabStates.forEach((key, value) {
      statesJson[key] = value.toJson();
    });
    await _prefs.setString(_tabStatesKey, jsonEncode(statesJson));
  }

  /// Loads the tab states map
  Future<Map<String, TabState>> loadTabStates() async {
    final String? statesJson = _prefs.getString(_tabStatesKey);

    if (statesJson == null || statesJson.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(statesJson) as Map<String, dynamic>;
      final Map<String, TabState> tabStates = {};

      decoded.forEach((key, value) {
        tabStates[key] = TabState.fromJson(value as Map<String, dynamic>);
      });

      return tabStates;
    } catch (e) {
      // If there's an error parsing, return empty map
      return {};
    }
  }

  /// Saves the active tab ID
  Future<void> saveActiveTabId(String tabId) async {
    await _prefs.setString(_activeTabIdKey, tabId);
  }

  /// Loads the active tab ID
  Future<String?> loadActiveTabId() async {
    return _prefs.getString(_activeTabIdKey);
  }

  /// Clears all tab data
  Future<void> clearTabs() async {
    await _prefs.remove(_tabsKey);
    await _prefs.remove(_tabStatesKey);
    await _prefs.remove(_activeTabIdKey);
  }

  /// Updates a single tab state without rewriting all states
  Future<void> updateTabState(TabState tabState) async {
    final Map<String, TabState> currentStates = await loadTabStates();
    currentStates[tabState.tabId] = tabState;
    await saveTabStates(currentStates);
  }
}
