import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../models/recent_file.dart';

/// Repository for managing recently opened PDF files
class RecentFilesRepository {
  static const String _recentFilesKey = 'recent_files';
  static const String _lastDirectoryKey = 'last_directory';

  final SharedPreferences _prefs;

  RecentFilesRepository(this._prefs);

  /// Gets the list of recently opened files
  Future<List<RecentFile>> getRecentFiles() async {
    final String? jsonString = _prefs.getString(_recentFilesKey);
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RecentFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Adds a file to the recent files list
  /// If the file already exists, it moves it to the top with updated timestamp
  Future<void> addRecentFile(RecentFile file) async {
    final List<RecentFile> recentFiles = await getRecentFiles();

    // Remove the file if it already exists
    recentFiles.removeWhere((f) => f.path == file.path);

    // Add the file at the beginning
    recentFiles.insert(0, file);

    // Keep only the last N files
    if (recentFiles.length > AppConfig.maxRecentFiles) {
      recentFiles.removeRange(AppConfig.maxRecentFiles, recentFiles.length);
    }

    // Save to preferences
    final List<Map<String, dynamic>> jsonList = recentFiles
        .map((f) => f.toJson())
        .toList();
    await _prefs.setString(_recentFilesKey, json.encode(jsonList));
  }

  /// Clears all recent files
  Future<void> clearRecentFiles() async {
    await _prefs.remove(_recentFilesKey);
  }

  /// Removes a specific file from the recent files list
  Future<void> removeRecentFile(String path) async {
    final List<RecentFile> recentFiles = await getRecentFiles();
    recentFiles.removeWhere((f) => f.path == path);

    final List<Map<String, dynamic>> jsonList = recentFiles
        .map((f) => f.toJson())
        .toList();
    await _prefs.setString(_recentFilesKey, json.encode(jsonList));
  }

  /// Gets the last directory used in the file picker
  Future<String?> getLastDirectory() async {
    return _prefs.getString(_lastDirectoryKey);
  }

  /// Saves the last directory used in the file picker
  Future<void> setLastDirectory(String directory) async {
    await _prefs.setString(_lastDirectoryKey, directory);
  }
}
