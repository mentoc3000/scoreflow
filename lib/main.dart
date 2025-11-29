import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_bloc.dart';
import 'features/pdf_viewer/bloc/tab_manager_bloc.dart';
import 'features/pdf_viewer/bloc/tab_manager_event.dart';
import 'features/pdf_viewer/repositories/recent_files_repository.dart';
import 'features/pdf_viewer/repositories/tab_persistence_repository.dart';
import 'features/pdf_viewer/ui/tabbed_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final RecentFilesRepository recentFilesRepository =
      RecentFilesRepository(prefs);
  final TabPersistenceRepository tabPersistenceRepository =
      TabPersistenceRepository(prefs);

  runApp(ScoreFlowApp(
    recentFilesRepository: recentFilesRepository,
    tabPersistenceRepository: tabPersistenceRepository,
  ));
}

class ScoreFlowApp extends StatelessWidget {
  final RecentFilesRepository recentFilesRepository;
  final TabPersistenceRepository tabPersistenceRepository;

  const ScoreFlowApp({
    super.key,
    required this.recentFilesRepository,
    required this.tabPersistenceRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) => PdfViewerBloc(
            recentFilesRepository: recentFilesRepository,
          ),
        ),
        BlocProvider(
          create: (BuildContext context) => TabManagerBloc(
            persistenceRepository: tabPersistenceRepository,
          )..add(const TabsRestoreRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'ScoreFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const TabbedViewerScreen(),
      ),
    );
  }
}
