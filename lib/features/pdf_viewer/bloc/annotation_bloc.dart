import 'package:flutter/foundation.dart';
import 'package:replay_bloc/replay_bloc.dart';

import '../models/text_annotation.dart';
import '../repositories/annotation_repository.dart';
import 'annotation_event.dart';
import 'annotation_state.dart';

/// Bloc for managing text annotations on PDF pages with undo/redo support
class AnnotationBloc extends ReplayBloc<AnnotationEvent, AnnotationState> {
  final AnnotationRepository _repository;

  AnnotationBloc({required AnnotationRepository repository})
      : _repository = repository,
        super(const AnnotationState()) {
    on<AnnotationsLoadRequested>(_onAnnotationsLoadRequested);
    on<AnnotationAdded>(_onAnnotationAdded);
    on<AnnotationUpdated>(_onAnnotationUpdated);
    on<AnnotationDeleted>(_onAnnotationDeleted);
    on<AnnotationSelected>(_onAnnotationSelected);
    on<AddModeToggled>(_onAddModeToggled);
    on<DefaultFontSizeChanged>(_onDefaultFontSizeChanged);
    on<SelectedAnnotationFontSizeChanged>(_onSelectedAnnotationFontSizeChanged);
    on<AnnotationsSaveRequested>(_onAnnotationsSaveRequested);
    on<AnnotationsCleared>(_onAnnotationsCleared);
    on<AnnotationUndoRequested>(_onAnnotationUndoRequested);
    on<AnnotationRedoRequested>(_onAnnotationRedoRequested);
  }

  /// Loads annotations from file
  Future<void> _onAnnotationsLoadRequested(
    AnnotationsLoadRequested event,
    Emitter<AnnotationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, pdfPath: event.pdfPath));

    try {
      final List<TextAnnotation> annotations =
          await _repository.loadAnnotations(event.pdfPath);
      emit(state.copyWith(
        annotations: annotations,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error loading annotations: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Adds a new annotation and saves
  Future<void> _onAnnotationAdded(
    AnnotationAdded event,
    Emitter<AnnotationState> emit,
  ) async {
    final List<TextAnnotation> updatedAnnotations = [
      ...state.annotations,
      event.annotation,
    ];

    emit(state.copyWith(
      annotations: updatedAnnotations,
      selectedAnnotationId: event.annotation.id,
      isAddMode: false,
    ));

    await _saveAnnotations(emit);
  }

  /// Updates an existing annotation and saves
  Future<void> _onAnnotationUpdated(
    AnnotationUpdated event,
    Emitter<AnnotationState> emit,
  ) async {
    final List<TextAnnotation> updatedAnnotations = state.annotations.map((a) {
      return a.id == event.annotation.id ? event.annotation : a;
    }).toList();

    emit(state.copyWith(annotations: updatedAnnotations));

    await _saveAnnotations(emit);
  }

  /// Deletes an annotation and saves
  Future<void> _onAnnotationDeleted(
    AnnotationDeleted event,
    Emitter<AnnotationState> emit,
  ) async {
    final List<TextAnnotation> updatedAnnotations =
        state.annotations.where((a) => a.id != event.annotationId).toList();

    emit(state.copyWith(
      annotations: updatedAnnotations,
      clearSelectedAnnotation:
          state.selectedAnnotationId == event.annotationId,
    ));

    await _saveAnnotations(emit);
  }

  /// Selects an annotation
  void _onAnnotationSelected(
    AnnotationSelected event,
    Emitter<AnnotationState> emit,
  ) {
    if (event.annotationId == null) {
      emit(state.copyWith(clearSelectedAnnotation: true));
    } else {
      emit(state.copyWith(selectedAnnotationId: event.annotationId));
    }
  }

  /// Toggles add mode
  void _onAddModeToggled(
    AddModeToggled event,
    Emitter<AnnotationState> emit,
  ) {
    emit(state.copyWith(
      isAddMode: !state.isAddMode,
      clearSelectedAnnotation: true,
    ));
  }

  /// Changes default font size
  void _onDefaultFontSizeChanged(
    DefaultFontSizeChanged event,
    Emitter<AnnotationState> emit,
  ) {
    emit(state.copyWith(defaultFontSize: event.fontSize));
  }

  /// Changes font size of selected annotation
  Future<void> _onSelectedAnnotationFontSizeChanged(
    SelectedAnnotationFontSizeChanged event,
    Emitter<AnnotationState> emit,
  ) async {
    if (state.selectedAnnotationId == null) return;

    final List<TextAnnotation> updatedAnnotations = state.annotations.map((a) {
      if (a.id == state.selectedAnnotationId) {
        return a.copyWith(fontSize: event.fontSize);
      }
      return a;
    }).toList();

    emit(state.copyWith(
      annotations: updatedAnnotations,
      defaultFontSize: event.fontSize,
    ));

    await _saveAnnotations(emit);
  }

  /// Saves annotations to file
  Future<void> _onAnnotationsSaveRequested(
    AnnotationsSaveRequested event,
    Emitter<AnnotationState> emit,
  ) async {
    await _saveAnnotations(emit);
  }

  /// Clears all annotations (when closing file)
  void _onAnnotationsCleared(
    AnnotationsCleared event,
    Emitter<AnnotationState> emit,
  ) {
    emit(const AnnotationState());
  }

  /// Helper to save annotations to file
  Future<void> _saveAnnotations(Emitter<AnnotationState> emit) async {
    if (state.pdfPath == null) return;

    emit(state.copyWith(isSaving: true));

    try {
      await _repository.saveAnnotations(state.pdfPath!, state.annotations);
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }

    emit(state.copyWith(isSaving: false));
  }

  /// Handles undo request
  void _onAnnotationUndoRequested(
    AnnotationUndoRequested event,
    Emitter<AnnotationState> emit,
  ) {
    undo();
  }

  /// Handles redo request
  void _onAnnotationRedoRequested(
    AnnotationRedoRequested event,
    Emitter<AnnotationState> emit,
  ) {
    redo();
  }
}
