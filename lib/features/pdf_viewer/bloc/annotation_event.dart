import 'package:equatable/equatable.dart';
import 'package:replay_bloc/replay_bloc.dart';

import '../models/text_annotation.dart';

/// Base class for all annotation events
abstract class AnnotationEvent extends ReplayEvent with EquatableMixin {
  const AnnotationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load annotations for a PDF file
class AnnotationsLoadRequested extends AnnotationEvent {
  final String pdfPath;

  const AnnotationsLoadRequested(this.pdfPath);

  @override
  List<Object?> get props => [pdfPath];
}

/// Event to add a new annotation
class AnnotationAdded extends AnnotationEvent {
  final TextAnnotation annotation;

  const AnnotationAdded(this.annotation);

  @override
  List<Object?> get props => [annotation];
}

/// Event to update an existing annotation
class AnnotationUpdated extends AnnotationEvent {
  final TextAnnotation annotation;

  const AnnotationUpdated(this.annotation);

  @override
  List<Object?> get props => [annotation];
}

/// Event to delete an annotation
class AnnotationDeleted extends AnnotationEvent {
  final String annotationId;

  const AnnotationDeleted(this.annotationId);

  @override
  List<Object?> get props => [annotationId];
}

/// Event to select an annotation
class AnnotationSelected extends AnnotationEvent {
  final String? annotationId;

  const AnnotationSelected(this.annotationId);

  @override
  List<Object?> get props => [annotationId];
}

/// Event to toggle add mode on/off
class AddModeToggled extends AnnotationEvent {
  const AddModeToggled();
}

/// Event to change the default font size for new annotations
class DefaultFontSizeChanged extends AnnotationEvent {
  final double fontSize;

  const DefaultFontSizeChanged(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

/// Event to change font size of selected annotation
class SelectedAnnotationFontSizeChanged extends AnnotationEvent {
  final double fontSize;

  const SelectedAnnotationFontSizeChanged(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

/// Event to save annotations to file
class AnnotationsSaveRequested extends AnnotationEvent {
  const AnnotationsSaveRequested();
}

/// Event to clear all annotations (when closing file)
class AnnotationsCleared extends AnnotationEvent {
  const AnnotationsCleared();
}

/// Event to undo the last annotation change
class AnnotationUndoRequested extends AnnotationEvent {
  const AnnotationUndoRequested();
}

/// Event to redo the last undone annotation change
class AnnotationRedoRequested extends AnnotationEvent {
  const AnnotationRedoRequested();
}
