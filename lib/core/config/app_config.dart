/// Application-wide configuration constants
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Tab Management
  static const int maxTabs = 10;
  static const int maxRecentFiles = 10;

  // UI Dimensions
  static const double minSidebarWidth = 200.0;
  static const double maxSidebarWidth = 600.0;
  static const double defaultSidebarWidth = 300.0;

  // Animation Durations
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 250);
  static const Duration tabSwitchDelay = Duration(milliseconds: 100);

  // Search Configuration
  static const int searchBufferPages = 2;

  // Page Navigation
  static const double pageGap = 8.0;
  static const double pagePadding = 16.0;

  // Zoom Configuration
  static const double minZoomLevel = 0.25;
  static const double maxZoomLevel = 4.0;
  static const double defaultZoomLevel = 1.0;
  static const double zoomStep = 0.25;

  // File Access
  static const Duration fileAccessRetryDelay = Duration(milliseconds: 500);
  static const int maxFileAccessRetries = 1;

  // Page Caching Configuration
  static const int maxCachedPages = 10; // Maximum number of pages to keep in cache
  static const int preRenderBufferPages = 2; // Number of pages to pre-render ahead/behind
  static const Duration cacheEvictionDelay = Duration(seconds: 30); // Delay before evicting old pages
  static const int memoryPressureThresholdMB = 500; // Memory threshold for cache eviction (MB)
}
