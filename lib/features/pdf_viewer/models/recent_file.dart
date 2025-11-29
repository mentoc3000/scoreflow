import 'package:equatable/equatable.dart';

/// Model representing a recently opened PDF file
class RecentFile extends Equatable {
  /// Full path to the PDF file
  final String path;

  /// Display name of the file (extracted from path)
  final String name;

  /// Timestamp when the file was last opened
  final DateTime lastOpened;

  /// Security-scoped bookmark data for macOS file access (base64 encoded)
  final String? bookmark;

  const RecentFile({
    required this.path,
    required this.name,
    required this.lastOpened,
    this.bookmark,
  });

  /// Creates a RecentFile from a file path
  factory RecentFile.fromPath(String filePath, {String? bookmark}) {
    final fileName = filePath.split('/').last;
    return RecentFile(
      path: filePath,
      name: fileName,
      lastOpened: DateTime.now(),
      bookmark: bookmark,
    );
  }

  /// Creates a RecentFile from JSON
  factory RecentFile.fromJson(Map<String, dynamic> json) {
    return RecentFile(
      path: json['path'] as String,
      name: json['name'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      bookmark: json['bookmark'] as String?,
    );
  }

  /// Converts the RecentFile to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'lastOpened': lastOpened.toIso8601String(),
      if (bookmark != null) 'bookmark': bookmark,
    };
  }

  /// Creates a copy of this RecentFile with updated lastOpened timestamp
  RecentFile copyWithNewTimestamp() {
    return RecentFile(
      path: path,
      name: name,
      lastOpened: DateTime.now(),
      bookmark: bookmark,
    );
  }

  @override
  List<Object?> get props => [path, name, lastOpened, bookmark];
}
