// This is a basic Flutter widget test for ScoreFlow PDF viewer app.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoreflow/main.dart';
import 'package:scoreflow/features/pdf_viewer/repositories/annotation_repository.dart';
import 'package:scoreflow/features/pdf_viewer/repositories/recent_files_repository.dart';
import 'package:scoreflow/features/pdf_viewer/repositories/tab_persistence_repository.dart';

void main() {
  testWidgets('ScoreFlow app smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final RecentFilesRepository recentFilesRepository =
        RecentFilesRepository(prefs);
    final TabPersistenceRepository tabPersistenceRepository =
        TabPersistenceRepository(prefs);
    final AnnotationRepository annotationRepository = AnnotationRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(ScoreFlowApp(
      recentFilesRepository: recentFilesRepository,
      tabPersistenceRepository: tabPersistenceRepository,
      annotationRepository: annotationRepository,
    ));

    // Verify that the home screen shows up with the Open PDF button
    expect(find.text('ScoreFlow'), findsOneWidget);
    expect(find.text('Open PDF'), findsOneWidget);
  });
}
