import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/logging/log_files.dart';
import 'package:path/path.dart' as p;

final appLogRepositoryProvider = Provider<AppLogRepository>((ref) {
  return const AppLogRepository(directoryLoader: defaultLogDirectory);
});

final appLogEntriesProvider = FutureProvider.autoDispose<List<AppLogEntry>>((ref) {
  return ref.watch(appLogRepositoryProvider).listEntries();
});

class AppLogRepository {
  const AppLogRepository({required Future<Directory> Function() directoryLoader}) : _directoryLoader = directoryLoader;

  final Future<Directory> Function() _directoryLoader;

  Future<List<AppLogEntry>> listEntries() async {
    final files = await listLogFiles();
    final entries = <AppLogEntry>[];
    for (final file in files.reversed) {
      if (!await file.exists()) {
        continue;
      }
      final lines = await file.readAsLines();
      for (final line in lines) {
        final entry = AppLogEntry.tryParse(line, sourceFile: p.basename(file.path));
        if (entry != null) {
          entries.add(entry);
        }
      }
    }
    entries.sort((left, right) => left.time.compareTo(right.time));
    return entries;
  }

  Future<List<File>> listLogFiles() async {
    final directory = await _directoryLoader();
    if (!await directory.exists()) {
      return const [];
    }
    final files = await directory.list().where(isLogFile).cast<File>().toList();
    files.sort((left, right) => logFileSortIndex(left).compareTo(logFileSortIndex(right)));
    return files;
  }
}

enum AppLogLevel {
  trace,
  debug,
  info,
  warning,
  error,
  fatal;

  String get label => switch (this) {
    AppLogLevel.trace => 'Trace',
    AppLogLevel.debug => 'Debug',
    AppLogLevel.info => 'Info',
    AppLogLevel.warning => 'Warn',
    AppLogLevel.error => 'Error',
    AppLogLevel.fatal => 'Fatal',
  };

  int get severity => index;
}

class AppLogEntry {
  const AppLogEntry({
    required this.time,
    required this.level,
    required this.message,
    required this.sourceFile,
    this.error,
    this.stackTrace,
  });

  factory AppLogEntry.fromJson(Map<String, Object?> json, {required String sourceFile}) {
    final level = AppLogLevel.values.byName(json['level'] as String? ?? AppLogLevel.info.name);
    return AppLogEntry(
      time: DateTime.parse(json['time'] as String).toLocal(),
      level: level,
      message: json['message']?.toString() ?? '',
      sourceFile: sourceFile,
      error: json['error']?.toString(),
      stackTrace: json['stackTrace']?.toString(),
    );
  }

  static AppLogEntry? tryParse(String line, {required String sourceFile}) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return AppLogEntry.fromJson(decoded, sourceFile: sourceFile);
    } on Object {
      return null;
    }
  }

  final DateTime time;
  final AppLogLevel level;
  final String message;
  final String sourceFile;
  final String? error;
  final String? stackTrace;

  String toClipboardText() {
    final buffer = StringBuffer()
      ..write(time.toIso8601String())
      ..write(' ')
      ..write(level.label.toUpperCase())
      ..write(' [')
      ..write(sourceFile)
      ..write('] ')
      ..write(message);
    final errorValue = error;
    if (errorValue != null && errorValue.isNotEmpty) {
      buffer
        ..writeln()
        ..write('error: ')
        ..write(errorValue);
    }
    final stackTraceValue = stackTrace;
    if (stackTraceValue != null && stackTraceValue.isNotEmpty) {
      buffer
        ..writeln()
        ..write(stackTraceValue);
    }
    return buffer.toString();
  }
}
