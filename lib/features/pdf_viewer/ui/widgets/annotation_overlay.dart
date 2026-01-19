import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../bloc/annotation_bloc.dart';
import '../../bloc/annotation_event.dart';
import '../../bloc/annotation_state.dart';
import '../../models/text_annotation.dart';

/// Overlay widget that renders and manages text annotations on a PDF page
class AnnotationOverlay extends StatelessWidget {
  final int pageNumber;
  final Size pageSize;

  const AnnotationOverlay({
    super.key,
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationBloc, AnnotationState>(
      builder: (context, state) {
        final List<TextAnnotation> pageAnnotations =
            state.getAnnotationsForPage(pageNumber);

        return GestureDetector(
          behavior: state.isAddMode
              ? HitTestBehavior.opaque
              : HitTestBehavior.translucent,
          onTapUp: state.isAddMode
              ? (details) => _onTapToAdd(context, details, state)
              : null,
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: Stack(
              children: [
                // Render each annotation
                for (final annotation in pageAnnotations)
                  _AnnotationWidget(
                    key: ValueKey(annotation.id),
                    annotation: annotation,
                    pageSize: pageSize,
                    isSelected: state.selectedAnnotationId == annotation.id,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapToAdd(
    BuildContext context,
    TapUpDetails details,
    AnnotationState state,
  ) {
    // Convert tap position to normalized coordinates (0-1)
    final double x = details.localPosition.dx / pageSize.width;
    final double y = details.localPosition.dy / pageSize.height;

    // Create new annotation
    final TextAnnotation newAnnotation = TextAnnotation(
      id: const Uuid().v4(),
      pageNumber: pageNumber,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      text: '',
      fontSize: state.defaultFontSize,
    );

    context.read<AnnotationBloc>().add(AnnotationAdded(newAnnotation));
  }
}

/// Widget for rendering a single annotation
class _AnnotationWidget extends StatefulWidget {
  final TextAnnotation annotation;
  final Size pageSize;
  final bool isSelected;

  const _AnnotationWidget({
    super.key,
    required this.annotation,
    required this.pageSize,
    required this.isSelected,
  });

  @override
  State<_AnnotationWidget> createState() => _AnnotationWidgetState();
}

class _AnnotationWidgetState extends State<_AnnotationWidget> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Offset? _dragOffset;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.annotation.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Auto-focus if this is a new empty annotation
    if (widget.annotation.text.isEmpty && widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_AnnotationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.annotation.text != widget.annotation.text && !_isEditing) {
      _textController.text = widget.annotation.text;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  void _finishEditing() {
    setState(() => _isEditing = false);

    final String newText = _textController.text;
    if (newText != widget.annotation.text) {
      context.read<AnnotationBloc>().add(
            AnnotationUpdated(widget.annotation.copyWith(text: newText)),
          );
    }

    // Delete if empty
    if (newText.isEmpty) {
      context.read<AnnotationBloc>().add(AnnotationDeleted(widget.annotation.id));
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset ?? Offset.zero) + details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset == null || _dragOffset == Offset.zero) {
      setState(() => _dragOffset = null);
      return;
    }

    // Calculate new normalized position
    final double currentX = widget.annotation.x * widget.pageSize.width;
    final double currentY = widget.annotation.y * widget.pageSize.height;

    final double newX = (currentX + _dragOffset!.dx) / widget.pageSize.width;
    final double newY = (currentY + _dragOffset!.dy) / widget.pageSize.height;

    final double clampedX = newX.clamp(0.0, 1.0);
    final double clampedY = newY.clamp(0.0, 1.0);

    // Only update if position actually changed
    if (clampedX != widget.annotation.x || clampedY != widget.annotation.y) {
      context.read<AnnotationBloc>().add(
            AnnotationUpdated(widget.annotation.copyWith(
              x: clampedX,
              y: clampedY,
            )),
          );
    }

    setState(() => _dragOffset = null);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pixel position from normalized coordinates
    double left = widget.annotation.x * widget.pageSize.width;
    double top = widget.annotation.y * widget.pageSize.height;

    // Apply drag offset if dragging
    if (_dragOffset != null) {
      left += _dragOffset!.dx;
      top += _dragOffset!.dy;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          context
              .read<AnnotationBloc>()
              .add(AnnotationSelected(widget.annotation.id));
        },
        onDoubleTap: () {
          context
              .read<AnnotationBloc>()
              .add(AnnotationSelected(widget.annotation.id));
          setState(() => _isEditing = true);
          _focusNode.requestFocus();
        },
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            // Handle delete key when selected
            if (widget.isSelected &&
                !_isEditing &&
                event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.delete ||
                    event.logicalKey == LogicalKeyboardKey.backspace)) {
              context
                  .read<AnnotationBloc>()
                  .add(AnnotationDeleted(widget.annotation.id));
            }
          },
          child: Container(
            constraints: BoxConstraints(
              minWidth: 20,
              maxWidth: widget.pageSize.width * 0.5,
            ),
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  )
                : null,
            child: _isEditing
                ? IntrinsicWidth(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: widget.annotation.fontSize,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _finishEditing(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      widget.annotation.text.isEmpty
                          ? ' '
                          : widget.annotation.text,
                      style: TextStyle(
                        fontSize: widget.annotation.fontSize,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
