import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/shared/utils/text_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef FaviconFetcher = Future<FaviconFetchResult?> Function(Uri url);

final faviconCacheProvider = Provider<FaviconCache>((ref) {
  return FaviconCache();
});

class FaviconCache {
  FaviconCache({Future<Directory> Function()? cacheDirectory, FaviconFetcher? fetcher})
    : _cacheDirectory = cacheDirectory ?? getApplicationCacheDirectory,
      _fetcher = fetcher ?? _fetchFavicon;

  final Future<Directory> Function() _cacheDirectory;
  final FaviconFetcher _fetcher;

  Future<String?> cacheFavicon(Uri? faviconUrl) async {
    if (faviconUrl == null || !faviconUrl.hasScheme || !faviconUrl.hasAuthority) {
      return null;
    }

    final result = await _fetcher(faviconUrl);
    if (result == null || result.bytes.isEmpty) {
      return null;
    }

    final directory = Directory(p.join((await _cacheDirectory()).path, 'favicons'));
    await directory.create(recursive: true);

    final extension = _extensionFor(faviconUrl, result.contentType);
    final h = stableFnv1a64Hash(faviconUrl.toString());
    final file = File(p.join(directory.path, '$h$extension'));
    await file.writeAsBytes(result.bytes, flush: true);
    return file.path;
  }

  String _extensionFor(Uri faviconUrl, String? contentType) {
    final normalizedType = contentType?.toLowerCase();
    if (normalizedType == 'image/svg+xml') {
      return '.svg';
    }
    if (normalizedType == 'image/png') {
      return '.png';
    }
    if (normalizedType == 'image/jpeg') {
      return '.jpg';
    }
    if (normalizedType == 'image/webp') {
      return '.webp';
    }
    if (normalizedType == 'image/x-icon' || normalizedType == 'image/vnd.microsoft.icon') {
      return '.ico';
    }

    final extension = p.extension(faviconUrl.path).toLowerCase();
    return extension.isEmpty ? '.ico' : extension;
  }
}

class FaviconFetchResult {
  const FaviconFetchResult({required this.bytes, this.contentType});

  final Uint8List bytes;
  final String? contentType;
}

Future<FaviconFetchResult?> _fetchFavicon(Uri url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final chunks = <int>[];
    await for (final chunk in response) {
      chunks.addAll(chunk);
    }
    return FaviconFetchResult(bytes: Uint8List.fromList(chunks), contentType: response.headers.contentType?.mimeType);
  } finally {
    client.close(force: true);
  }
}
