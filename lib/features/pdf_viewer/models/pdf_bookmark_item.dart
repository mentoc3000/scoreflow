import 'package:pdfrx/pdfrx.dart';

/// Simplified bookmark model for UI display
/// Wraps PdfOutlineNode with additional UI-friendly properties
class PdfBookmarkItem {
  final String title;
  final int? pageNumber;
  final PdfDest? destination;
  final List<PdfBookmarkItem> children;
  final int level; // Depth in hierarchy for indentation

  const PdfBookmarkItem({
    required this.title,
    this.pageNumber,
    this.destination,
    this.children = const [],
    this.level = 0,
  });

  /// Creates a PdfBookmarkItem from a PdfOutlineNode
  factory PdfBookmarkItem.fromOutlineNode(PdfOutlineNode node, int level) {
    // Extract page number from destination
    final PdfDest? dest = node.dest;
    final int? pageNumber = dest?.pageNumber;

    // Recursively convert children
    final List<PdfBookmarkItem> children = node.children
        .map(
          (PdfOutlineNode child) =>
              PdfBookmarkItem.fromOutlineNode(child, level + 1),
        )
        .toList();

    return PdfBookmarkItem(
      title: node.title,
      pageNumber: pageNumber,
      destination: dest,
      children: children,
      level: level,
    );
  }

  /// Converts a list of PdfOutlineNodes to PdfBookmarkItems
  static List<PdfBookmarkItem> fromOutlineNodes(List<PdfOutlineNode> nodes) {
    return nodes
        .map((PdfOutlineNode node) => PdfBookmarkItem.fromOutlineNode(node, 0))
        .toList();
  }

  /// Checks if this bookmark has a valid destination
  bool get hasValidDestination => pageNumber != null && pageNumber! > 0;

  /// Checks if this bookmark has children
  bool get hasChildren => children.isNotEmpty;

  /// Flattens the bookmark tree into a list (for display purposes)
  List<PdfBookmarkItem> flatten() {
    final List<PdfBookmarkItem> result = [this];
    for (final PdfBookmarkItem child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }
}
