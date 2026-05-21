import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marker/features/browser/data/favicon_cache.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('marker_favicon_cache_test_');
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  test('downloads and stores favicons in the cache directory', () async {
    final cache = FaviconCache(
      cacheDirectory: () async => directory,
      fetcher: (url) async => FaviconFetchResult(bytes: Uint8List.fromList([1, 2, 3]), contentType: 'image/svg+xml'),
    );

    final path = await cache.cacheFavicon(Uri.parse('https://example.com/favicon.svg'));

    expect(path, isNotNull);
    expect(path, endsWith('.svg'));
    expect(await File(path!).readAsBytes(), [1, 2, 3]);
  });

  test('returns null when the favicon cannot be fetched', () async {
    final cache = FaviconCache(cacheDirectory: () async => directory, fetcher: (url) async => null);

    final path = await cache.cacheFavicon(Uri.parse('https://example.com/favicon.ico'));

    expect(path, isNull);
    expect(Directory('${directory.path}/favicons').existsSync(), isFalse);
  });
}
