import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/theme/app_theme.dart';
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
          return Stack(
            children: [
              // PDF page with text selection enabled
              SelectionArea(
                child: PdfPageView(
                  document: document,
                  pageNumber: pageNumber,
                  alignment: Alignment.center,
                ),
              ),
              // Only load link handler if shouldLoadLinks is true
              if (shouldLoadLinks)
                PdfLinkHandler(
                  document: document,
                  pageNumber: pageNumber,
                  pageSize: Size(constraints.maxWidth, constraints.maxHeight),
                  onInternalLinkTap: onLinkTap,
                ),
            ],
          );
        },
      ),
    );
  }
}
