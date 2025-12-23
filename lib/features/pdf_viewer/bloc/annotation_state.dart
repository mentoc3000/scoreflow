import 'package:equatable/equatable.dart';

import '../models/text_annotation.dart';

/// State for the annotation system
class AnnotationState extends Equatable {
  final String? pdfPath;
  final List<TextAnnotation> annotations;
  final String? selectedAnnotationId;
  final bool isAddMode;
  final double defaultFontSize;
  final bool isSaving;
  final bool isLoading;

  const AnnotationState({
    this.pdfPath,
    this.annotations = const [],
    this.selectedAnnotationId,
    this.isAddMode = false,
    this.defaultFontSize = 14.0,
    this.isSaving = false,
    this.isLoading = false,
  });

  /// Gets annotations for a specific page
  List<TextAnnotation> getAnnotationsForPage(int pageNumber) {
    return annotations.where((a) => a.pageNumber == pageNumber).toList();
  }

  /// Gets the currently selected annotation
  TextAnnotation? get selectedAnnotation {
    if (selectedAnnotationId == null) return null;
    try {
      return annotations.firstWhere((a) => a.id == selectedAnnotationId);
    } catch (_) {
      return null;
    }
  }

  /// Creates a copy with updated values
  AnnotationState copyWith({
    String? pdfPath,
    List<TextAnnotation>? annotations,
    String? selectedAnnotationId,
    bool? isAddMode,
    double? defaultFontSize,
    bool? isSaving,
    bool? isLoading,
    bool clearSelectedAnnotation = false,
    bool clearPdfPath = false,
  }) {
    return AnnotationState(
      pdfPath: clearPdfPath ? null : (pdfPath ?? this.pdfPath),
      annotations: annotations ?? this.annotations,
      selectedAnnotationId: clearSelectedAnnotation
          ? null
          : (selectedAnnotationId ?? this.selectedAnnotationId),
      isAddMode: isAddMode ?? this.isAddMode,
      defaultFontSize: defaultFontSize ?? this.defaultFontSize,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        pdfPath,
        annotations,
        selectedAnnotationId,
        isAddMode,
        defaultFontSize,
        isSaving,
        isLoading,
      ];
}

