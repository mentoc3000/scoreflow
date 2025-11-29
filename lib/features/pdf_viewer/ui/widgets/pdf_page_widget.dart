import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

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
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
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
