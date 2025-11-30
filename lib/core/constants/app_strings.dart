/// Application-wide string constants
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // App Name
  static const String appName = 'ScoreFlow';

  // Home Screen
  static const String openPdf = 'Open PDF';
  static const String recentFiles = 'Recent Files';
  static const String noRecentFiles = 'No recent files';
  static const String noRecentFilesSubtitle = 'Open a PDF file to get started';

  // PDF Viewer
  static const String loading = 'Loading...';
  static const String loadingPdf = 'Loading PDF...';
  static const String unexpectedState = 'Unexpected state';

  // Bookmarks
  static const String bookmarks = 'Bookmarks';
  static const String showBookmarks = 'Show bookmarks';
  static const String hideBookmarks = 'Hide bookmarks';
  static const String closeBookmarks = 'Close bookmarks';
  static const String noBookmarks = 'No bookmarks';

  // Search
  static const String search = 'Search';
  static const String searchInDocument = 'Search in document...';
  static const String closeSearch = 'Close search';
  static const String noResults = 'No results';
  static const String searching = 'Searching...';
  static const String previousResult = 'Previous';
  static const String nextResult = 'Next';

  // Navigation
  static const String previousPage = 'Previous page';
  static const String nextPage = 'Next page';
  static const String page = 'Page';
  static const String of = 'of';
  static const String newHomeTab = 'New home tab';

  // Tabs
  static const String home = 'Home';
  static const String settings = 'Settings';
  static const String configComingSoon = 'Config Screen - Coming Soon!';
  static const String returnToHome = 'Return to Home';

  // Error Messages
  static const String errorPrefix = 'Failed to';
  static const String failedToLoadRecentFiles = 'Failed to load recent files';
  static const String failedToOpenFilePicker = 'Failed to open file picker';
  static const String failedToCloseFile = 'Failed to close file';
  static const String failedToRestoreTabs = 'Failed to restore tabs';
  static const String fileNotFound = 'File not found';
  static const String pdfHasNoPages = 'PDF file has no pages';
  static const String failedToLoadPdf = 'Failed to load PDF';
  static const String maxTabsReached = 'Maximum of {0} tabs reached';

  // Specific error messages
  static const String permissionDeniedMessage =
      'Permission denied to access this file.\n\n'
      'Please use the "Open PDF" button to grant access to the file again.';

  static const String invalidPdfFormatMessage =
      'Unable to open PDF file.\n\n'
      'Please try using the "Open PDF" button to select the file again.';

  // Keyboard Shortcuts (for tooltips)
  static const String shortcutCmdF = '⌘F';
  static const String shortcutCmdB = '⌘B';
  static const String shortcutEsc = 'Esc';
  static const String shortcutEnter = 'Enter';
  static const String shortcutShiftEnter = 'Shift+Enter';

  // Validation Messages
  static const String enterPageNumberBetween = 'Please enter a page number between 1 and';

  // Time Formats
  static const String justNow = 'Just now';
  static const String minuteAgo = 'minute ago';
  static const String minutesAgo = 'minutes ago';
  static const String hourAgo = 'hour ago';
  static const String hoursAgo = 'hours ago';
  static const String yesterday = 'Yesterday';
  static const String daysAgo = 'days ago';
  static const String opened = 'Opened';

  /// Helper method to format max tabs error message
  static String maxTabsReachedMessage(int maxTabs) {
    return maxTabsReached.replaceAll('{0}', maxTabs.toString());
  }
}
