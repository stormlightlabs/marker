import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

typedef NativeUrlShare = Future<void> Function({required Uri url, required String title, Rect? sharePositionOrigin});

final nativeUrlShareProvider = Provider<NativeUrlShare>((ref) {
  return ({required url, required title, sharePositionOrigin}) {
    return SharePlus.instance.share(
      ShareParams(uri: url, title: title, subject: title, sharePositionOrigin: sharePositionOrigin),
    );
  };
});
