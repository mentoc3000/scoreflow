import 'package:equatable/equatable.dart';

/// Represents a text annotation on a PDF page
class TextAnnotation extends Equatable {
  final String id;
  final int pageNumber;
  final double x; // 0.0-1.0 relative to page width
  final double y; // 0.0-1.0 relative to page height
  final String text;
  final double fontSize;

  const TextAnnotation({
    required this.id,
    required this.pageNumber,
    required this.x,
    required this.y,
    required this.text,
    this.fontSize = 14.0,
  });

  /// Creates a TextAnnotation from JSON
  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    return TextAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      text: json['text'] as String,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
    );
  }

  /// Converts the TextAnnotation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'x': x,
      'y': y,
      'text': text,
      'fontSize': fontSize,
    };
  }

  /// Creates a copy with updated values
  TextAnnotation copyWith({
    String? id,
    int? pageNumber,
    double? x,
    double? y,
    String? text,
    double? fontSize,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  List<Object?> get props => [id, pageNumber, x, y, text, fontSize];
}

