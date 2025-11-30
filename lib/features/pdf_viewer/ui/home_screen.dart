import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import 'widgets/open_pdf_button.dart';
import 'widgets/recent_files_list.dart';
import 'widgets/section_divider.dart';

/// Home screen showing recent files and open button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Request recent files when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PdfViewerBloc>().add(const RecentFilesRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScoreFlow'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocBuilder<PdfViewerBloc, PdfViewerState>(
        builder: (BuildContext context, PdfViewerState state) {
          if (state is PdfViewerInitial) {
            return Column(
              children: [
                // Open PDF button section
                const OpenPdfButton(),

                // Divider
                if (state.recentFiles.isNotEmpty) const SectionDivider(title: 'Recent Files'),

                // Recent files list
                Expanded(
                  child: RecentFilesList(
                    recentFiles: state.recentFiles,
                    onFileSelected: (String path) {
                      context.read<PdfViewerBloc>().add(RecentFileOpened(path));
                    },
                  ),
                ),
              ],
            );
          } else if (state is PdfViewerError) {
            return Column(
              children: [
                // Open PDF button
                const OpenPdfButton(),

                // Error message
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(state.message, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Recent files (if available)
                if (state.recentFiles.isNotEmpty) ...[
                  const SectionDivider(title: 'Recent Files'),
                  Expanded(
                    child: RecentFilesList(
                      recentFiles: state.recentFiles,
                      onFileSelected: (String path) {
                        context.read<PdfViewerBloc>().add(RecentFileOpened(path));
                      },
                    ),
                  ),
                ],
              ],
            );
          }

          // Default fallback (shouldn't normally reach here)
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
