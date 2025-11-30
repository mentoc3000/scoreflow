import 'package:equatable/equatable.dart';

/// Model representing a search result within a PDF document
class SearchResult extends Equatable {
  /// The page number where the result was found (1-indexed)
  final int pageNumber;

  /// The character index within the page text where the match starts
  final int textIndex;

  /// The matched text string
  final String text;

  const SearchResult({
    required this.pageNumber,
    required this.textIndex,
    required this.text,
  });

  /// Creates a SearchResult from JSON
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      pageNumber: json['pageNumber'] as int,
      textIndex: json['textIndex'] as int,
      text: json['text'] as String,
    );
  }

  /// Converts the SearchResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'textIndex': textIndex,
      'text': text,
    };
  }

  @override
  List<Object?> get props => [pageNumber, textIndex, text];
}
