import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// Callback type for memory pressure events
typedef MemoryPressureCallback = void Function();

/// Service for monitoring app memory usage and detecting pressure
class MemoryMonitor {
  Timer? _monitorTimer;
  final List<MemoryPressureCallback> _callbacks = [];
  bool _isMonitoring = false;

  /// Start monitoring memory usage
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkMemoryUsage();
    });

    debugPrint('Memory monitoring started');
  }

  /// Stop monitoring memory usage
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    debugPrint('Memory monitoring stopped');
  }

  /// Register a callback for memory pressure events
  void registerCallback(MemoryPressureCallback callback) {
    _callbacks.add(callback);
  }

  /// Unregister a callback
  void unregisterCallback(MemoryPressureCallback callback) {
    _callbacks.remove(callback);
  }

  /// Check current memory usage
  void _checkMemoryUsage() {
    if (!kIsWeb) {
      try {
        // Get process info (this is platform-dependent)
        final int rssBytes = ProcessInfo.currentRss;
        final double rssMB = rssBytes / (1024 * 1024);

        debugPrint('Current memory usage: ${rssMB.toStringAsFixed(2)} MB');

        // Check if memory usage exceeds threshold
        if (rssMB > AppConfig.memoryPressureThresholdMB) {
          debugPrint('Memory pressure detected! Usage: ${rssMB.toStringAsFixed(2)} MB');
          _notifyMemoryPressure();
        }
      } catch (e) {
        // Memory monitoring not available on this platform
        debugPrint('Memory monitoring error: $e');
      }
    }
  }

  /// Notify all registered callbacks of memory pressure
  void _notifyMemoryPressure() {
    for (final MemoryPressureCallback callback in _callbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in memory pressure callback: $e');
      }
    }
  }

  /// Manually trigger memory pressure handling (for testing)
  void triggerMemoryPressure() {
    _notifyMemoryPressure();
  }

  /// Dispose and cleanup
  void dispose() {
    stopMonitoring();
    _callbacks.clear();
  }
}
