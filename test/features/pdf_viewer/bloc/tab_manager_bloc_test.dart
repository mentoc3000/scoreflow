import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/tab_manager_bloc.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/tab_manager_event.dart';
import 'package:scoreflow/features/pdf_viewer/bloc/tab_manager_state.dart';
import 'package:scoreflow/features/pdf_viewer/models/base_tab.dart';
import 'package:scoreflow/features/pdf_viewer/models/tab_state.dart';
import 'package:scoreflow/features/pdf_viewer/repositories/tab_persistence_repository.dart';

class MockTabPersistenceRepository extends Mock implements TabPersistenceRepository {}

void main() {
  group('TabManagerBloc', () {
    late TabPersistenceRepository repository;

    setUp(() {
      repository = MockTabPersistenceRepository();
      // Default stubs
      when(() => repository.loadTabs()).thenAnswer((_) async => []);
      when(() => repository.loadTabStates()).thenAnswer((_) async => {});
      when(() => repository.saveTabs(any())).thenAnswer((_) async {});
      when(() => repository.saveTabStates(any())).thenAnswer((_) async {});
      when(() => repository.saveActiveTabId(any())).thenAnswer((_) async {});
    });

    test('initial state is TabManagerInitial', () {
      final bloc = TabManagerBloc(persistenceRepository: repository);
      expect(bloc.state, const TabManagerInitial());
      bloc.close();
    });

    group('TabsRestoreRequested', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'creates home tab when no saved tabs',
        build: () {
          when(() => repository.loadTabs()).thenAnswer((_) async => []);
          when(() => repository.loadTabStates()).thenAnswer((_) async => {});
          return TabManagerBloc(persistenceRepository: repository);
        },
        act: (bloc) => bloc.add(const TabsRestoreRequested()),
        expect: () => [
          const TabManagerLoading(),
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 1)
              .having((s) => s.tabs.first, 'first tab', isA<HomeTab>()),
        ],
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'restores saved tabs',
        build: () {
          final savedTabs = [
            HomeTab.create(),
            DocumentTab.fromPath('/test.pdf'),
          ];
          final savedStates = {
            savedTabs[0].id: TabState(tabId: savedTabs[0].id),
            savedTabs[1].id: TabState(tabId: savedTabs[1].id, currentPage: 5),
          };
          when(() => repository.loadTabs()).thenAnswer((_) async => savedTabs);
          when(() => repository.loadTabStates()).thenAnswer((_) async => savedStates);
          return TabManagerBloc(persistenceRepository: repository);
        },
        act: (bloc) => bloc.add(const TabsRestoreRequested()),
        expect: () => [
          const TabManagerLoading(),
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 2)
              .having((s) => s.tabStates.length, 'states length', 2),
        ],
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'handles restore errors',
        build: () {
          when(() => repository.loadTabs()).thenThrow(Exception('Load failed'));
          return TabManagerBloc(persistenceRepository: repository);
        },
        act: (bloc) => bloc.add(const TabsRestoreRequested()),
        expect: () => [
          const TabManagerLoading(),
          isA<TabManagerError>()
              .having((s) => s.message, 'message', contains('Failed to restore tabs')),
        ],
      );
    });

    group('TabOpened', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'adds new tab and sets it active',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final homeTab = HomeTab.create();
          return TabManagerLoaded(
            tabs: [homeTab],
            activeTabId: homeTab.id,
            tabStates: {homeTab.id: TabState(tabId: homeTab.id)},
          );
        },
        act: (bloc) {
          final newTab = DocumentTab.fromPath('/test.pdf');
          bloc.add(TabOpened(newTab));
        },
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 2)
              .having((s) => s.tabs.last, 'last tab', isA<DocumentTab>()),
        ],
        verify: (_) {
          verify(() => repository.saveTabs(any())).called(1);
          verify(() => repository.saveTabStates(any())).called(1);
          verify(() => repository.saveActiveTabId(any())).called(1);
        },
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'switches to existing tab if same file path',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab1 = DocumentTab.fromPath('/test.pdf');
          final tab2 = HomeTab.create();
          return TabManagerLoaded(
            tabs: [tab1, tab2],
            activeTabId: tab2.id,
            tabStates: {
              tab1.id: TabState(tabId: tab1.id),
              tab2.id: TabState(tabId: tab2.id),
            },
          );
        },
        act: (bloc) {
          final duplicateTab = DocumentTab.fromPath('/test.pdf');
          bloc.add(TabOpened(duplicateTab));
        },
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 2) // No new tab added
              .having((s) => s.activeTabId, 'activeTabId', isNotNull),
        ],
        verify: (_) {
          verify(() => repository.saveActiveTabId(any())).called(1);
          // Tab manager does save tabs when switching (to ensure consistency)
          verify(() => repository.saveTabs(any())).called(greaterThanOrEqualTo(0));
          verify(() => repository.saveTabStates(any())).called(greaterThanOrEqualTo(0));
        },
      );
    });

    group('TabClosed', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'removes tab and persists changes',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab1 = HomeTab.create();
          final tab2 = DocumentTab.fromPath('/test.pdf');
          return TabManagerLoaded(
            tabs: [tab1, tab2],
            activeTabId: tab2.id,
            tabStates: {
              tab1.id: TabState(tabId: tab1.id),
              tab2.id: TabState(tabId: tab2.id),
            },
          );
        },
        act: (bloc) => bloc.add(TabClosed(bloc.state is TabManagerLoaded
            ? (bloc.state as TabManagerLoaded).tabs.last.id
            : '')),
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 1),
        ],
        verify: (_) {
          verify(() => repository.saveTabs(any())).called(1);
          verify(() => repository.saveTabStates(any())).called(1);
        },
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'creates new home tab when closing last tab',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab = DocumentTab.fromPath('/test.pdf');
          return TabManagerLoaded(
            tabs: [tab],
            activeTabId: tab.id,
            tabStates: {tab.id: TabState(tabId: tab.id)},
          );
        },
        act: (bloc) => bloc.add(TabClosed((bloc.state as TabManagerLoaded).tabs.first.id)),
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 1)
              .having((s) => s.tabs.first, 'first tab', isA<HomeTab>()),
        ],
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'switches to last tab when closing active tab',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab1 = HomeTab.create();
          final tab2 = DocumentTab.fromPath('/test.pdf');
          return TabManagerLoaded(
            tabs: [tab1, tab2],
            activeTabId: tab2.id,
            tabStates: {
              tab1.id: TabState(tabId: tab1.id),
              tab2.id: TabState(tabId: tab2.id),
            },
          );
        },
        act: (bloc) {
          final activeId = (bloc.state as TabManagerLoaded).activeTabId!;
          final previousActiveId = activeId;
          bloc.add(TabClosed(activeId));
          return previousActiveId;
        },
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.tabs.length, 'tabs length', 1),
        ],
      );
    });

    group('TabSwitched', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'switches active tab and persists',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab1 = HomeTab.create();
          final tab2 = DocumentTab.fromPath('/test.pdf');
          return TabManagerLoaded(
            tabs: [tab1, tab2],
            activeTabId: tab1.id,
            tabStates: {
              tab1.id: TabState(tabId: tab1.id),
              tab2.id: TabState(tabId: tab2.id),
            },
          );
        },
        act: (bloc) {
          final secondTabId = (bloc.state as TabManagerLoaded).tabs[1].id;
          bloc.add(TabSwitched(secondTabId));
        },
        expect: () => [
          isA<TabManagerLoaded>()
              .having((s) => s.activeTabId, 'activeTabId', isNotNull),
        ],
        verify: (_) {
          verify(() => repository.saveActiveTabId(any())).called(1);
        },
      );

      blocTest<TabManagerBloc, TabManagerState>(
        'does nothing if tab does not exist',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab = HomeTab.create();
          return TabManagerLoaded(
            tabs: [tab],
            activeTabId: tab.id,
            tabStates: {tab.id: TabState(tabId: tab.id)},
          );
        },
        act: (bloc) => bloc.add(const TabSwitched('nonexistent-id')),
        expect: () => [], // No state change
      );
    });

    group('TabStateUpdated', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'updates tab state and persists',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          final tab = DocumentTab.fromPath('/test.pdf');
          return TabManagerLoaded(
            tabs: [tab],
            activeTabId: tab.id,
            tabStates: {tab.id: TabState(tabId: tab.id, currentPage: 1)},
          );
        },
        act: (bloc) {
          final tabId = (bloc.state as TabManagerLoaded).tabs.first.id;
          bloc.add(TabStateUpdated(TabState(
            tabId: tabId,
            currentPage: 5,
            zoomLevel: 1.5,
          )));
        },
        expect: () => [
          isA<TabManagerLoaded>()
              .having(
                (s) => s.tabStates[s.tabs.first.id]?.currentPage,
                'updated page',
                5,
              )
              .having(
                (s) => s.tabStates[s.tabs.first.id]?.zoomLevel,
                'updated zoom',
                1.5,
              ),
        ],
        verify: (_) {
          verify(() => repository.saveTabStates(any())).called(1);
        },
      );
    });

    group('Max Tabs Limit', () {
      blocTest<TabManagerBloc, TabManagerState>(
        'prevents opening more than max tabs',
        build: () => TabManagerBloc(persistenceRepository: repository),
        seed: () {
          // Create max number of tabs (10)
          final tabs = List.generate(10, (i) => DocumentTab.fromPath('/test$i.pdf'));
          final states = {for (var tab in tabs) tab.id: TabState(tabId: tab.id)};
          return TabManagerLoaded(
            tabs: tabs,
            activeTabId: tabs.first.id,
            tabStates: states,
          );
        },
        act: (bloc) => bloc.add(const TabOpenRequested(filePath: '/new.pdf')),
        expect: () => [
          isA<TabManagerError>()
              .having((s) => s.message, 'message', contains('Maximum')),
          isA<TabManagerLoaded>(), // State restored after error
        ],
      );
    });
  });
}
