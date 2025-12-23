import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/annotation_bloc.dart';
import '../../bloc/annotation_event.dart';
import '../../bloc/annotation_state.dart';

/// Minimal toolbar for annotation controls
/// Shows: Add button, font size controls
class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({super.key});

  static const double _minFontSize = 8.0;
  static const double _maxFontSize = 48.0;
  static const double _fontSizeStep = 2.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationBloc, AnnotationState>(
      builder: (context, state) {
        final bool hasSelection = state.selectedAnnotationId != null;
        final double currentFontSize =
            state.selectedAnnotation?.fontSize ?? state.defaultFontSize;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add button
              _ToolbarButton(
                icon: Icons.add,
                label: 'Add',
                isActive: state.isAddMode,
                onPressed: () {
                  context.read<AnnotationBloc>().add(const AddModeToggled());
                },
              ),

              const SizedBox(width: 24),

              // Divider
              Container(
                width: 1,
                height: 24,
                color: Theme.of(context).dividerColor,
              ),

              const SizedBox(width: 24),

              // Font size decrease
              _ToolbarButton(
                icon: Icons.text_decrease,
                label: 'A-',
                isEnabled: hasSelection && currentFontSize > _minFontSize,
                onPressed: () {
                  final double newSize =
                      (currentFontSize - _fontSizeStep).clamp(_minFontSize, _maxFontSize);
                  context
                      .read<AnnotationBloc>()
                      .add(SelectedAnnotationFontSizeChanged(newSize));
                },
              ),

              const SizedBox(width: 8),

              // Font size display
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  currentFontSize.toInt().toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasSelection
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Font size increase
              _ToolbarButton(
                icon: Icons.text_increase,
                label: 'A+',
                isEnabled: hasSelection && currentFontSize < _maxFontSize,
                onPressed: () {
                  final double newSize =
                      (currentFontSize + _fontSizeStep).clamp(_minFontSize, _maxFontSize);
                  context
                      .read<AnnotationBloc>()
                      .add(SelectedAnnotationFontSizeChanged(newSize));
                },
              ),

              const SizedBox(width: 24),

              // Divider
              Container(
                width: 1,
                height: 24,
                color: Theme.of(context).dividerColor,
              ),

              const SizedBox(width: 24),

              // Delete button (only enabled when annotation is selected)
              _ToolbarButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                isEnabled: hasSelection,
                onPressed: () {
                  if (state.selectedAnnotationId != null) {
                    context
                        .read<AnnotationBloc>()
                        .add(AnnotationDeleted(state.selectedAnnotationId!));
                  }
                },
              ),

              // Saving indicator
              if (state.isSaving) ...[
                const SizedBox(width: 16),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Individual toolbar button
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color defaultColor = Theme.of(context).colorScheme.onSurface;
    final Color disabledColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: activeColor.withValues(alpha: 0.3))
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? activeColor
                : (isEnabled ? defaultColor : disabledColor),
          ),
        ),
      ),
    );
  }
}
