import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marker/core/database/app_database.dart';
import 'package:marker/core/database/database_provider.dart';
import 'package:marker/features/browser/application/reader_controller.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(database)]);
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('records per-tab back and forward history', () async {
    final controller = container.read(readerControllerProvider.notifier);

    final firstUrl = controller.beginLoad();
    expect(firstUrl, Uri.parse('https://news.ycombinator.com'));
    await controller.finishLoad(url: firstUrl!, title: 'Hacker News');

    controller.setUrlText('example.com');
    final secondUrl = controller.beginLoad();
    expect(secondUrl, Uri.parse('https://example.com'));
    await controller.finishLoad(url: secondUrl!, title: 'Example');

    expect(container.read(readerControllerProvider).canGoBack, isTrue);
    expect(controller.goBack(), firstUrl);
    expect(container.read(readerControllerProvider).canGoForward, isTrue);
    expect(controller.goForward(), secondUrl);
  });

  test('creates and switches tabs without losing each tab history', () async {
    final controller = container.read(readerControllerProvider.notifier);
    final firstTabId = container.read(readerControllerProvider).activeTabId;

    final firstUrl = controller.beginLoad();
    await controller.finishLoad(url: firstUrl!, title: 'Hacker News');

    final secondUrl = controller.newTab();
    expect(secondUrl, Uri.parse('https://news.ycombinator.com'));
    expect(container.read(readerControllerProvider).tabs, hasLength(2));

    controller.setUrlText('dart.dev');
    final dartUrl = controller.beginLoad();
    await controller.finishLoad(url: dartUrl!, title: 'Dart');

    expect(controller.switchTab(firstTabId), firstUrl);
    expect(container.read(readerControllerProvider).activeTab.history.single, firstUrl);
    expect(controller.closeTab(firstTabId), dartUrl);
    expect(container.read(readerControllerProvider).tabs, hasLength(1));
  });

  test('opens a URL directly in a new tab', () {
    final controller = container.read(readerControllerProvider.notifier);
    final target = Uri.parse('https://example.com/new');

    expect(controller.openInNewTab(target), target);

    final state = container.read(readerControllerProvider);
    expect(state.tabs, hasLength(2));
    expect(state.activeTab.currentUrl, target);
    expect(state.activeTab.urlText, target.toString());
    expect(state.isLoading, isTrue);
  });

  test('keeps loading visible until the page finish callback resolves', () async {
    final controller = container.read(readerControllerProvider.notifier);

    final url = controller.beginLoad();
    controller.updateProgress(100);

    var state = container.read(readerControllerProvider);
    expect(state.progress, 100);
    expect(state.isLoading, isTrue);

    await controller.finishLoad(url: url!, title: 'Hacker News');

    state = container.read(readerControllerProvider);
    expect(state.progress, 100);
    expect(state.isLoading, isFalse);
  });

  test('toggles bookmark for current page', () async {
    final controller = container.read(readerControllerProvider.notifier);
    final url = controller.beginLoad();
    await controller.finishLoad(url: url!, title: 'Hacker News');

    await controller.toggleBookmark();
    expect(container.read(readerControllerProvider).bookmarks.single.url, url);
    expect(container.read(readerControllerProvider).isCurrentPageBookmarked, isTrue);

    await controller.toggleBookmark();
    expect(container.read(readerControllerProvider).bookmarks, isEmpty);
  });

  test('hydrates bookmarks from drift on build', () async {
    await database
        .into(database.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'bookmark-1',
            url: 'https://news.ycombinator.com',
            title: const Value('Hacker News'),
            createdAt: DateTime.utc(2026, 5, 13),
          ),
        );

    final controller = container.read(readerControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(readerControllerProvider).bookmarks.single.url, Uri.parse('https://news.ycombinator.com'));
    expect(controller.beginLoad(), Uri.parse('https://news.ycombinator.com'));
  });
}
