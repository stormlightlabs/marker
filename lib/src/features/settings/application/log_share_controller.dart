import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/settings/data/app_log_repository.dart';
import 'package:share_plus/share_plus.dart';

typedef NativeLogShare = Future<void> Function({Rect? sharePositionOrigin});

final nativeLogShareProvider = Provider<NativeLogShare>((ref) {
  return ({sharePositionOrigin}) async {
    final files = await ref.read(appLogRepositoryProvider).listLogFiles();
    if (files.isEmpty) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: files.map((file) => XFile(file.path, mimeType: 'text/plain')).toList(growable: false),
        title: 'Marker logs',
        subject: 'Marker logs',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  };
});
