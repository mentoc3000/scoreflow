import 'package:equatable/equatable.dart';

/// Represents a single open document tab
class DocumentTab extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final String? bookmark; // Security-scoped bookmark for file access
  final DateTime openedAt;
  final bool isHomeTab; // True if this is the home screen tab

  const DocumentTab({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.bookmark,
    required this.openedAt,
    this.isHomeTab = false,
  });

  /// Creates a home tab
  factory DocumentTab.home() {
    return DocumentTab(
      id: 'home_${DateTime.now().millisecondsSinceEpoch}',
      filePath: '',
      fileName: 'Home',
      openedAt: DateTime.now(),
      isHomeTab: true,
    );
  }

  /// Creates a DocumentTab from a file path
  factory DocumentTab.fromPath(String filePath, {String? bookmark}) {
    final String fileName = filePath.split('/').last;
    return DocumentTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      fileName: fileName,
      bookmark: bookmark,
      openedAt: DateTime.now(),
      isHomeTab: false,
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
      isHomeTab: json['isHomeTab'] as bool? ?? false,
    );
  }

  /// Converts the DocumentTab to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'bookmark': bookmark,
      'openedAt': openedAt.toIso8601String(),
      'isHomeTab': isHomeTab,
    };
  }

  /// Creates a copy with updated values
  DocumentTab copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? bookmark,
    DateTime? openedAt,
    bool? isHomeTab,
  }) {
    return DocumentTab(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      bookmark: bookmark ?? this.bookmark,
      openedAt: openedAt ?? this.openedAt,
      isHomeTab: isHomeTab ?? this.isHomeTab,
    );
  }

  @override
  List<Object?> get props => [id, filePath, fileName, bookmark, openedAt, isHomeTab];
}
