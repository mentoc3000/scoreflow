import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pdf_viewer_bloc.dart';
import '../bloc/pdf_viewer_event.dart';
import '../bloc/pdf_viewer_state.dart';
import 'widgets/recent_files_list.dart';

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
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PdfViewerBloc>().add(const OpenFileRequested());
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                // Divider
                if (state.recentFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Recent Files',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

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
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PdfViewerBloc>().add(const OpenFileRequested());
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Recent Files',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
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
