import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pdf_viewer_bloc.dart';
import '../../bloc/pdf_viewer_event.dart';

/// Reusable Open PDF button widget
class OpenPdfButton extends StatelessWidget {
  const OpenPdfButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<PdfViewerBloc>().add(const OpenFileRequested());
        },
        icon: const Icon(Icons.folder_open, size: 20),
        label: const Text('Open PDF'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
