import 'package:equatable/equatable.dart';

/// Base class for all tab types
abstract class BaseTab extends Equatable {
  final String id;
  final String displayName;
  final DateTime openedAt;

  const BaseTab({required this.id, required this.displayName, required this.openedAt});

  /// Creates a tab from JSON
  factory BaseTab.fromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String;

    switch (type) {
      case 'home':
        return HomeTab.fromJson(json);
      case 'document':
        return DocumentTab.fromJson(json);
      case 'config':
        return ConfigTab.fromJson(json);
      default:
        throw Exception('Unknown tab type: $type');
    }
  }

  /// Converts the tab to JSON
  Map<String, dynamic> toJson();

  /// Returns the tab type identifier
  String get type;

  @override
  List<Object?> get props => [id, displayName, openedAt];
}

/// Home tab for opening new documents
class HomeTab extends BaseTab {
  const HomeTab({required super.id, required super.openedAt}) : super(displayName: 'Home');

  /// Creates a new home tab
  factory HomeTab.create() {
    return HomeTab(id: 'home_${DateTime.now().millisecondsSinceEpoch}', openedAt: DateTime.now());
  }

  /// Creates a HomeTab from JSON
  factory HomeTab.fromJson(Map<String, dynamic> json) {
    return HomeTab(id: json['id'] as String, openedAt: DateTime.parse(json['openedAt'] as String));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'id': id, 'openedAt': openedAt.toIso8601String()};
  }

  @override
  String get type => 'home';
}

/// Document tab for viewing PDF files
class DocumentTab extends BaseTab {
  final String filePath;
  final String? bookmark; // Security-scoped bookmark for file access

  const DocumentTab({
    required super.id,
    required this.filePath,
    required String fileName,
    this.bookmark,
    required super.openedAt,
  }) : super(displayName: fileName);

  /// Creates a DocumentTab from a file path
  factory DocumentTab.fromPath(String filePath, {String? bookmark}) {
    final String fileName = filePath.split('/').last;
    return DocumentTab(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      filePath: filePath,
      fileName: fileName,
      bookmark: bookmark,
      openedAt: DateTime.now(),
    );
  }

  /// Creates a DocumentTab from JSON
  factory DocumentTab.fromJson(Map<String, dynamic> json) {
    return DocumentTab(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      bookmark: json['bookmark'] as String?,
      openedAt: DateTime.parse(json['openedAt'] as String),
    );
  }

  /// Creates a copy with updated values
  DocumentTab copyWith({String? id, String? filePath, String? fileName, String? bookmark, DateTime? openedAt}) {
    return DocumentTab(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? displayName,
      bookmark: bookmark ?? this.bookmark,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'filePath': filePath,
      'fileName': displayName,
      'bookmark': bookmark,
      'openedAt': openedAt.toIso8601String(),
    };
  }

  @override
  String get type => 'document';

  @override
  List<Object?> get props => [id, displayName, openedAt, filePath, bookmark];
}

/// Configuration tab for app settings
class ConfigTab extends BaseTab {
  const ConfigTab({required super.id, required super.openedAt}) : super(displayName: 'Settings');

  /// Creates a new config tab
  factory ConfigTab.create() {
    return ConfigTab(id: 'config_${DateTime.now().millisecondsSinceEpoch}', openedAt: DateTime.now());
  }

  /// Creates a ConfigTab from JSON
  factory ConfigTab.fromJson(Map<String, dynamic> json) {
    return ConfigTab(id: json['id'] as String, openedAt: DateTime.parse(json['openedAt'] as String));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'id': id, 'openedAt': openedAt.toIso8601String()};
  }

  @override
  String get type => 'config';
}
