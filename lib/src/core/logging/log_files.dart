import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const activeLogFileName = 'marker.log';

Future<Directory> defaultLogDirectory() async {
  final directory = await getApplicationSupportDirectory();
  return Directory(p.join(directory.path, 'logs'));
}

String rotatedLogFileName(int index) => 'marker.$index.log';

int logFileSortIndex(File file) {
  final name = p.basename(file.path);
  if (name == activeLogFileName) {
    return 0;
  }
  final match = RegExp(r'^marker\.(\d+)\.log$').firstMatch(name);
  return int.tryParse(match?.group(1) ?? '') ?? 9999;
}

bool isLogFile(FileSystemEntity entity) {
  if (entity is! File) {
    return false;
  }
  final name = p.basename(entity.path);
  return name == activeLogFileName || RegExp(r'^marker\.\d+\.log$').hasMatch(name);
}
