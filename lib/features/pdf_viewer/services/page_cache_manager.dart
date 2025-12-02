import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// Represents a cached rendered page
class CachedPage {
  final int pageNumber;
  final Uint8List imageData;
  final DateTime timestamp;
  final int sizeInBytes;

  CachedPage({
    required this.pageNumber,
    required this.imageData,
    required this.timestamp,
    required this.sizeInBytes,
  });
}

/// LRU cache manager for rendered PDF pages
/// Provides page caching, background pre-rendering, and memory pressure management
/// Note: pdfrx already provides internal caching, this provides additional control
class PageCacheManager {
  final Map<String, CachedPage> _cache = {};
  final List<String> _accessOrder = [];
  Timer? _evictionTimer;

  /// Get cache key for a specific document and page
  String _getCacheKey(String documentId, int pageNumber) {
    return '${documentId}_$pageNumber';
  }

  /// Check if a page is cached
  bool isPageCached(String documentId, int pageNumber) {
    final String key = _getCacheKey(documentId, pageNumber);
    return _cache.containsKey(key);
  }

  /// Get a cached page (returns null if not cached)
  CachedPage? getCachedPage(String documentId, int pageNumber) {
    final String key = _getCacheKey(documentId, pageNumber);
    final CachedPage? page = _cache[key];

    if (page != null) {
      // Update access order for LRU
      _accessOrder.remove(key);
      _accessOrder.add(key);
    }

    return page;
  }

  /// Cache a rendered page
  void cachePage(
    String documentId,
    int pageNumber,
    Uint8List imageData,
  ) {
    final String key = _getCacheKey(documentId, pageNumber);

    // Remove from cache if already exists
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Add to cache
    _cache[key] = CachedPage(
      pageNumber: pageNumber,
      imageData: imageData,
      timestamp: DateTime.now(),
      sizeInBytes: imageData.length,
    );

    // Update access order
    _accessOrder.add(key);

    // Enforce cache size limit
    _enforceCacheLimit();

    // Schedule eviction timer
    _scheduleEviction();

    debugPrint('Page cached: $key (${_cache.length} pages in cache)');
  }

  /// Enforce cache size limit using LRU eviction
  void _enforceCacheLimit() {
    while (_cache.length > AppConfig.maxCachedPages) {
      // Remove least recently used page
      if (_accessOrder.isNotEmpty) {
        final String oldestKey = _accessOrder.first;
        _accessOrder.removeAt(0);
        _cache.remove(oldestKey);
        debugPrint('Evicted page from cache: $oldestKey');
      }
    }
  }

  /// Schedule automatic cache eviction for old pages
  void _scheduleEviction() {
    _evictionTimer?.cancel();

    _evictionTimer = Timer(AppConfig.cacheEvictionDelay, () {
      _evictOldPages();
    });
  }

  /// Evict pages that haven't been accessed recently
  void _evictOldPages() {
    final DateTime now = DateTime.now();
    final List<String> keysToRemove = [];

    for (final String key in _cache.keys) {
      final CachedPage? page = _cache[key];
      if (page != null) {
        final Duration age = now.difference(page.timestamp);
        if (age > AppConfig.cacheEvictionDelay) {
          keysToRemove.add(key);
        }
      }
    }

    for (final String key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
      debugPrint('Auto-evicted old page: $key');
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('Auto-evicted ${keysToRemove.length} old pages');
    }
  }

  /// Clear cache for a specific document
  void clearDocumentCache(String documentId) {
    final List<String> keysToRemove = [];

    for (final String key in _cache.keys) {
      if (key.startsWith('${documentId}_')) {
        keysToRemove.add(key);
      }
    }

    for (final String key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    debugPrint('Cleared cache for document: $documentId (${keysToRemove.length} pages)');
  }

  /// Clear entire cache
  void clearAllCache() {
    final int count = _cache.length;
    _cache.clear();
    _accessOrder.clear();
    debugPrint('Cleared entire cache: $count pages removed');
  }

  /// Handle memory pressure by aggressively clearing cache
  void handleMemoryPressure() {
    debugPrint('Memory pressure detected - clearing cache');

    // Keep only the most recently accessed pages (half of max)
    final int keepCount = AppConfig.maxCachedPages ~/ 2;

    if (_accessOrder.length > keepCount) {
      final int removeCount = _accessOrder.length - keepCount;

      for (int i = 0; i < removeCount; i++) {
        if (_accessOrder.isNotEmpty) {
          final String oldestKey = _accessOrder.first;
          _accessOrder.removeAt(0);
          _cache.remove(oldestKey);
        }
      }

      debugPrint('Memory pressure eviction: removed $removeCount pages');
    }
  }

  /// Get current cache size in bytes
  int getCacheSizeBytes() {
    int totalSize = 0;
    for (final CachedPage page in _cache.values) {
      totalSize += page.sizeInBytes;
    }
    return totalSize;
  }

  /// Get current cache size in MB
  double getCacheSizeMB() {
    return getCacheSizeBytes() / (1024 * 1024);
  }

  /// Dispose and cleanup
  void dispose() {
    _evictionTimer?.cancel();
    clearAllCache();
  }
}
