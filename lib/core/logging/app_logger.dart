import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:marker/core/logging/log_files.dart';
import 'package:path/path.dart' as p;

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.console());

class AppLogger {
  AppLogger._(this._logger);

  factory AppLogger.console() => AppLogger._(
    Logger(filter: _AlwaysLogFilter(), printer: _PassThroughPrinter(), output: _StdIoLogOutput(), level: Level.trace),
  );

  static Future<AppLogger> initialize({Directory? directory, int maxBytes = 1024 * 1024, int maxFiles = 5}) async {
    final logDirectory = directory ?? await defaultLogDirectory();
    final logger = Logger(
      filter: _AlwaysLogFilter(),
      printer: _PassThroughPrinter(),
      output: MultiOutput([
        _StdIoLogOutput(),
        RotatingJsonFileLogOutput(directory: logDirectory, maxBytes: maxBytes, maxFiles: maxFiles),
      ]),
      level: Level.trace,
    );
    await logger.init;
    return AppLogger._(logger);
  }

  final Logger _logger;

  void trace(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  Future<void> close() {
    return _logger.close();
  }
}

class RotatingJsonFileLogOutput extends LogOutput {
  RotatingJsonFileLogOutput({required this.directory, this.maxBytes = 1024 * 1024, this.maxFiles = 5});

  final Directory directory;
  final int maxBytes;
  final int maxFiles;

  late final File _activeFile;

  @override
  Future<void> init() async {
    await directory.create(recursive: true);
    _activeFile = File(p.join(directory.path, activeLogFileName));
    if (await _activeFile.exists() && await _activeFile.length() >= maxBytes) {
      await _rotate();
    }
    if (!await _activeFile.exists()) {
      await _activeFile.create(recursive: true);
    }
  }

  @override
  void output(OutputEvent event) {
    final line = '${jsonEncode(_jsonFor(event))}\n';
    final bytes = utf8.encode(line).length;
    try {
      if (_activeFile.existsSync() && _activeFile.lengthSync() + bytes > maxBytes) {
        _rotateSync();
      }
      _activeFile.writeAsStringSync(line, mode: FileMode.append, flush: true);
    } on Object catch (error, stackTrace) {
      stderr.writeln('Failed to write log file: $error');
      stderr.writeln(stackTrace);
    }
  }

  Map<String, Object?> _jsonFor(OutputEvent event) {
    final origin = event.origin;
    return {
      'time': origin.time.toUtc().toIso8601String(),
      'level': levelName(origin.level),
      'message': _stringify(origin.message),
      if (origin.error != null) 'error': origin.error.toString(),
      if (origin.stackTrace != null) 'stackTrace': origin.stackTrace.toString(),
    };
  }

  Future<void> _rotate() async {
    for (var index = maxFiles - 1; index >= 1; index -= 1) {
      final source = File(p.join(directory.path, rotatedLogFileName(index)));
      if (!await source.exists()) {
        continue;
      }
      if (index == maxFiles - 1) {
        await source.delete();
      } else {
        await source.rename(p.join(directory.path, rotatedLogFileName(index + 1)));
      }
    }

    if (await _activeFile.exists()) {
      await _activeFile.rename(p.join(directory.path, rotatedLogFileName(1)));
    }
    await _activeFile.create(recursive: true);
  }

  void _rotateSync() {
    for (var index = maxFiles - 1; index >= 1; index -= 1) {
      final source = File(p.join(directory.path, rotatedLogFileName(index)));
      if (!source.existsSync()) {
        continue;
      }
      if (index == maxFiles - 1) {
        source.deleteSync();
      } else {
        source.renameSync(p.join(directory.path, rotatedLogFileName(index + 1)));
      }
    }

    if (_activeFile.existsSync()) {
      _activeFile.renameSync(p.join(directory.path, rotatedLogFileName(1)));
    }
    _activeFile.createSync(recursive: true);
  }
}

class _AlwaysLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level >= level!;
}

class _PassThroughPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final parts = [
      event.time.toUtc().toIso8601String(),
      levelName(event.level).toUpperCase(),
      _stringify(event.message),
      if (event.error != null) 'error=${event.error}',
    ];
    return [parts.join(' ')];
  }
}

class _StdIoLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final line = event.lines.join('\n');
    if (event.level >= Level.warning) {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }
}

String levelName(Level level) => switch (level) {
  Level.trace => 'trace',
  Level.debug => 'debug',
  Level.info => 'info',
  Level.warning => 'warning',
  Level.error => 'error',
  Level.fatal => 'fatal',
  _ => level.name,
};

String _stringify(Object? message) {
  if (message is Function) {
    return _stringify(message());
  }
  if (message is Map || message is Iterable) {
    return jsonEncode(message);
  }
  return message.toString();
}
