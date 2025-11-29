import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_bloc.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_event.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_state.dart';
import 'features/pdf_viewer/repositories/recent_files_repository.dart';
import 'features/pdf_viewer/ui/home_screen.dart';
import 'features/pdf_viewer/ui/pdf_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final RecentFilesRepository recentFilesRepository =
      RecentFilesRepository(prefs);

  runApp(ScoreFlowApp(recentFilesRepository: recentFilesRepository));
}

class ScoreFlowApp extends StatelessWidget {
  final RecentFilesRepository recentFilesRepository;

  const ScoreFlowApp({
    super.key,
    required this.recentFilesRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => PdfViewerBloc(
        recentFilesRepository: recentFilesRepository,
      )..add(const RecentFilesRequested()),
      child: MaterialApp(
        title: 'ScoreFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ScoreFlowHome(),
      ),
    );
  }
}

class ScoreFlowHome extends StatelessWidget {
  const ScoreFlowHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      builder: (BuildContext context, PdfViewerState state) {
        // Show home screen when no PDF is loaded
        if (state is PdfViewerInitial || state is PdfViewerError) {
          return const HomeScreen();
        }

        // Show PDF viewer screen when loading or loaded
        if (state is PdfViewerLoading || state is PdfViewerLoaded) {
          return const PdfViewerScreen();
        }

        // Fallback
        return const HomeScreen();
      },
    );
  }
}
