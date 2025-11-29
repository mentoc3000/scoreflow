import 'package:equatable/equatable.dart';

/// Represents the state of a single tab (per-document state)
class TabState extends Equatable {
  final String tabId;
  final int currentPage;
  final double zoomLevel;
  final bool isBookmarkSidebarOpen;
  final String? searchQuery;

  const TabState({
    required this.tabId,
    this.currentPage = 1,
    this.zoomLevel = 1.0,
    this.isBookmarkSidebarOpen = false,
    this.searchQuery,
  });

  /// Creates a TabState from JSON
  factory TabState.fromJson(Map<String, dynamic> json) {
    return TabState(
      tabId: json['tabId'] as String,
      currentPage: json['currentPage'] as int? ?? 1,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      isBookmarkSidebarOpen: json['isBookmarkSidebarOpen'] as bool? ?? false,
      searchQuery: json['searchQuery'] as String?,
    );
  }

  /// Converts the TabState to JSON
  Map<String, dynamic> toJson() {
    return {
      'tabId': tabId,
      'currentPage': currentPage,
      'zoomLevel': zoomLevel,
      'isBookmarkSidebarOpen': isBookmarkSidebarOpen,
      'searchQuery': searchQuery,
    };
  }

  /// Creates a copy with updated values
  TabState copyWith({
    String? tabId,
    int? currentPage,
    double? zoomLevel,
    bool? isBookmarkSidebarOpen,
    String? searchQuery,
  }) {
    return TabState(
      tabId: tabId ?? this.tabId,
      currentPage: currentPage ?? this.currentPage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isBookmarkSidebarOpen: isBookmarkSidebarOpen ?? this.isBookmarkSidebarOpen,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        tabId,
        currentPage,
        zoomLevel,
        isBookmarkSidebarOpen,
        searchQuery,
      ];
}
