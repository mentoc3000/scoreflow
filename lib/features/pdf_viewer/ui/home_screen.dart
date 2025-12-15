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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<PdfViewerBloc, PdfViewerState>(
        builder: (BuildContext context, PdfViewerState state) {
          if (state is PdfViewerInitial) {
            return Column(
              children: [
                // Header section with Open button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'ScoreFlow',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const OpenPdfButton(),
                    ],
                  ),
                ),

                // Recent files section
                if (state.recentFiles.isNotEmpty) ...[
                  const SectionDivider(title: 'Recent Files'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RecentFilesList(
                      recentFiles: state.recentFiles,
                      onFileSelected: (String path) {
                        context.read<PdfViewerBloc>().add(RecentFileOpened(path));
                      },
                      onFileRemoved: (String path) {
                        context.read<PdfViewerBloc>().add(RecentFileRemoved(path));
                      },
                    ),
                  ),
                ],
              ],
            );
          } else if (state is PdfViewerError) {
            return Column(
              children: [
                // Header section with Open button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'ScoreFlow',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const OpenPdfButton(),
                    ],
                  ),
                ),

                // Error message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Recent files (if available)
                if (state.recentFiles.isNotEmpty) ...[
                  const SectionDivider(title: 'Recent Files'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RecentFilesList(
                      recentFiles: state.recentFiles,
                      onFileSelected: (String path) {
                        context.read<PdfViewerBloc>().add(RecentFileOpened(path));
                      },
                      onFileRemoved: (String path) {
                        context.read<PdfViewerBloc>().add(RecentFileRemoved(path));
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
