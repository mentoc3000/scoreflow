import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/text_annotation.dart';

/// Repository for managing text annotations stored as JSON files
class AnnotationRepository {
  /// Gets a safe filename from a PDF path by hashing it
  String _getSafeFileName(String pdfPath) {
    // Create a hash of the full path to use as filename
    final bytes = utf8.encode(pdfPath);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets the annotation file path in the app's support directory
  Future<String> _getAnnotationFilePath(String pdfPath) async {
    // Get app support directory
    String supportDir;
    if (Platform.isMacOS) {
      final String home = Platform.environment['HOME'] ?? '';
      supportDir = p.join(home, 'Library', 'Application Support', 'com.scoreflow.app', 'annotations');
    } else if (Platform.isLinux) {
      final String home = Platform.environment['HOME'] ?? '';
      supportDir = p.join(home, '.local', 'share', 'scoreflow', 'annotations');
    } else if (Platform.isWindows) {
      final String appData = Platform.environment['APPDATA'] ?? '';
      supportDir = p.join(appData, 'scoreflow', 'annotations');
    } else {
      supportDir = Directory.systemTemp.path;
    }

    // Ensure directory exists
    final Directory dir = Directory(supportDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Use hash of PDF path as filename
    final String safeFileName = _getSafeFileName(pdfPath);
    return p.join(supportDir, '$safeFileName.json');
  }

  /// Loads annotations for a PDF file
  /// Returns empty list if no annotations file exists
  Future<List<TextAnnotation>> loadAnnotations(String pdfPath) async {
    final String annotationPath = await _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);

    if (!await file.exists()) {
      return [];
    }

    try {
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate that the stored PDF path matches (in case of hash collision)
      if (data['pdfPath'] != pdfPath) {
        debugPrint('PDF path mismatch in annotations file');
        return [];
      }

      final List<dynamic> jsonList = data['annotations'] as List<dynamic>;
      return jsonList
          .map((item) => TextAnnotation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading annotations: $e');
      return [];
    }
  }

  /// Saves annotations for a PDF file
  Future<void> saveAnnotations(
    String pdfPath,
    List<TextAnnotation> annotations,
  ) async {
    final String annotationPath = await _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);

    try {
      final Map<String, dynamic> data = {
        'pdfPath': pdfPath,
        'lastModified': DateTime.now().toIso8601String(),
        'annotations': annotations.map((a) => a.toJson()).toList(),
      };
      final String jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving annotations: $e');
      rethrow;
    }
  }

  /// Deletes the annotation file for a PDF
  Future<void> deleteAnnotations(String pdfPath) async {
    final String annotationPath = await _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);

    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Error deleting annotations: $e');
      }
    }
  }

  /// Checks if annotations exist for a PDF
  Future<bool> hasAnnotations(String pdfPath) async {
    final String annotationPath = await _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);
    return file.exists();
  }
}
