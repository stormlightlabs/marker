import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marker/src/core/logging/app_logger.dart';
import 'package:marker/src/core/logging/log_files.dart';
import 'package:marker/src/features/settings/data/app_log_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  test('writes structured logs and rotates files by size', () async {
    final directory = await Directory.systemTemp.createTemp('marker_logs_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final logger = await AppLogger.initialize(directory: directory, maxBytes: 180, maxFiles: 3);
    addTearDown(logger.close);

    logger.info('first message');
    logger.warning('second message');
    logger.error('third message', error: StateError('broken'));

    final repository = AppLogRepository(directoryLoader: () async => directory);
    final files = await repository.listLogFiles();
    final entries = await repository.listEntries();

    expect(files.map((file) => p.basename(file.path)), contains(activeLogFileName));
    expect(files.map((file) => p.basename(file.path)), contains(rotatedLogFileName(1)));
    expect(entries.map((entry) => entry.message), containsAll(['first message', 'second message', 'third message']));
    expect(entries.last.level, AppLogLevel.error);
    expect(entries.last.error, contains('broken'));
  });

  test('ignores malformed log lines when reading entries', () async {
    final directory = await Directory.systemTemp.createTemp('marker_logs_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    await File(p.join(directory.path, activeLogFileName)).writeAsString(
      'not json\n'
      '{"time":"2026-05-16T12:00:00.000Z","level":"info","message":"valid"}\n',
    );

    final entries = await AppLogRepository(directoryLoader: () async => directory).listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.message, 'valid');
    expect(entries.single.level, AppLogLevel.info);
  });
}
