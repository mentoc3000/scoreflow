import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/text_annotation.dart';

/// Repository for managing text annotations stored as JSON files
class AnnotationRepository {
  /// Gets the annotation file path for a given PDF path
  String _getAnnotationFilePath(String pdfPath) {
    return '$pdfPath.annotations.json';
  }

  /// Loads annotations for a PDF file
  /// Returns empty list if no annotations file exists
  Future<List<TextAnnotation>> loadAnnotations(String pdfPath) async {
    final String annotationPath = _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);

    if (!await file.exists()) {
      return [];
    }

    try {
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
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
    final String annotationPath = _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);

    try {
      final List<Map<String, dynamic>> jsonList =
          annotations.map((a) => a.toJson()).toList();
      final String jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving annotations: $e');
      rethrow;
    }
  }

  /// Deletes the annotation file for a PDF
  Future<void> deleteAnnotations(String pdfPath) async {
    final String annotationPath = _getAnnotationFilePath(pdfPath);
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
    final String annotationPath = _getAnnotationFilePath(pdfPath);
    final File file = File(annotationPath);
    return file.exists();
  }
}

