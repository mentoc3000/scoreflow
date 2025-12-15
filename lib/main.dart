import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/pdf_viewer/bloc/pdf_viewer_bloc.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_event.dart';
import 'features/pdf_viewer/bloc/pdf_viewer_state.dart';
import 'features/pdf_viewer/bloc/tab_manager_bloc.dart';
import 'features/pdf_viewer/bloc/tab_manager_event.dart';
import 'features/pdf_viewer/repositories/recent_files_repository.dart';
import 'features/pdf_viewer/repositories/tab_persistence_repository.dart';
import 'features/pdf_viewer/ui/tabbed_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache directory for pdfrx
  await _initializePdfrxCache();

  // Initialize SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final RecentFilesRepository recentFilesRepository = RecentFilesRepository(prefs);
  final TabPersistenceRepository tabPersistenceRepository = TabPersistenceRepository(prefs);

  runApp(
    ScoreFlowApp(recentFilesRepository: recentFilesRepository, tabPersistenceRepository: tabPersistenceRepository),
  );
}

Future<void> _initializePdfrxCache() async {
  // Set up cache directory for pdfrx
  Pdfrx.getCacheDirectory = () async {
    if (Platform.isMacOS) {
      final String home = Platform.environment['HOME'] ?? '';
      final String cacheDir = path.join(home, 'Library', 'Caches', 'com.scoreflow.app', 'pdfrx_cache');
      final Directory dir = Directory(cacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return cacheDir;
    } else if (Platform.isLinux) {
      final String home = Platform.environment['HOME'] ?? '';
      final String cacheDir = path.join(home, '.cache', 'scoreflow', 'pdfrx_cache');
      final Directory dir = Directory(cacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return cacheDir;
    } else if (Platform.isWindows) {
      final String temp = Platform.environment['TEMP'] ?? '';
      final String cacheDir = path.join(temp, 'scoreflow', 'pdfrx_cache');
      final Directory dir = Directory(cacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return cacheDir;
    }
    // Fallback to system temp directory
    return Directory.systemTemp.path;
  };
}

class ScoreFlowApp extends StatelessWidget {
  final RecentFilesRepository recentFilesRepository;
  final TabPersistenceRepository tabPersistenceRepository;

  const ScoreFlowApp({super.key, required this.recentFilesRepository, required this.tabPersistenceRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => PdfViewerBloc(recentFilesRepository: recentFilesRepository)),
        BlocProvider(
          create: (BuildContext context) =>
              TabManagerBloc(persistenceRepository: tabPersistenceRepository)..add(const TabsRestoreRequested()),
        ),
      ],
      child: BlocBuilder<PdfViewerBloc, PdfViewerState>(
        builder: (context, pdfState) {
          return PlatformMenuBar(
            menus: [
              PlatformMenu(
                label: 'ScoreFlow',
                menus: [
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.servicesSubmenu))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.servicesSubmenu),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.hide))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.hideOtherApplications))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hideOtherApplications),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.showAllApplications))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.showAllApplications),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
                ],
              ),
              PlatformMenu(
                label: 'View',
                menus: [
                  PlatformMenuItem(
                    label: 'Focus Mode',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyF, shift: true, meta: true),
                    onSelected: pdfState is PdfViewerLoaded
                        ? () {
                            context.read<PdfViewerBloc>().add(const DistractionFreeModeToggled());
                          }
                        : null,
                  ),
                  PlatformMenuItem(
                    label: 'Toggle Bookmarks',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyB, meta: true),
                    onSelected: pdfState is PdfViewerLoaded
                        ? () {
                            context.read<PdfViewerBloc>().add(const BookmarkSidebarToggled());
                          }
                        : null,
                  ),
                ],
              ),
              PlatformMenu(
                label: 'Window',
                menus: [
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.minimizeWindow))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.minimizeWindow),
                  if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.zoomWindow))
                    const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.zoomWindow),
                ],
              ),
            ],
            child: MaterialApp(
              title: 'ScoreFlow',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
              home: const TabbedViewerScreen(),
            ),
          );
        },
      ),
    );
  }
}
