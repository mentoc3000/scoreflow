import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/theme/app_theme.dart';
import '../../bloc/annotation_bloc.dart';
import '../../bloc/annotation_state.dart';
import 'annotation_overlay.dart';
import 'pdf_link_handler.dart';

/// Widget for rendering a single PDF page with text selection support
class PdfPageWidget extends StatelessWidget {
  final PdfDocument document;
  final int pageNumber;
  final bool isCurrentPage;
  final Function(int)? onLinkTap;
  final bool shouldLoadLinks;

  const PdfPageWidget({
    super.key,
    required this.document,
    required this.pageNumber,
    this.isCurrentPage = false,
    this.onLinkTap,
    this.shouldLoadLinks = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: isCurrentPage
            ? [
                BoxShadow(
                  color: AppColors.pdfShadow.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.pdfShadow.withValues(alpha: 0.08),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return BlocBuilder<AnnotationBloc, AnnotationState>(
            builder: (context, annotationState) {
              return Stack(
                children: [
                  // PDF page with text selection enabled
                  // Disable pointer events when in annotation add mode so taps pass through to the annotation overlay
                  IgnorePointer(
                    ignoring: annotationState.isAddMode,
                    child: SelectionArea(
                      child: PdfPageView(
                        document: document,
                        pageNumber: pageNumber,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  // Only load link handler if shouldLoadLinks is true
                  // Also disable when in annotation add mode
                  if (shouldLoadLinks)
                    IgnorePointer(
                      ignoring: annotationState.isAddMode,
                      child: PdfLinkHandler(
                        document: document,
                        pageNumber: pageNumber,
                        pageSize: Size(constraints.maxWidth, constraints.maxHeight),
                        onInternalLinkTap: onLinkTap,
                      ),
                    ),
                  // Annotation overlay for text annotations
                  AnnotationOverlay(
                    pageNumber: pageNumber,
                    pageSize: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
