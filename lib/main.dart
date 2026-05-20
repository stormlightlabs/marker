import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/app/marker_app.dart';
import 'package:marker/core/logging/app_logger.dart';

void main() {
  AppLogger? logger;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      logger = await AppLogger.initialize();
      final defaultDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null && message.isNotEmpty) {
          logger?.debug(message);
        }
        defaultDebugPrint(message, wrapWidth: wrapWidth);
      };

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        logger?.error('Unhandled Flutter error', error: details.exception, stackTrace: details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        logger?.error('Unhandled platform error', error: error, stackTrace: stackTrace);
        return false;
      };

      logger?.info('Marker started');
      runApp(ProviderScope(overrides: [appLoggerProvider.overrideWithValue(logger!)], child: const MarkerApp()));
    },
    (error, stackTrace) {
      logger?.fatal('Unhandled zone error', error: error, stackTrace: stackTrace);
    },
  );
}
