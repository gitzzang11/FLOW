import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String?> getDefaultBackupDirectory() async {
  if (!Platform.isWindows) return null;

  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile == null || userProfile.isEmpty) return null;

  final directory = Directory('$userProfile\\Documents\\Flow');
  await directory.create(recursive: true);
  return directory.path;
}

Future<void> writeBackupFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> readPickedFileBytes(PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes != null) return bytes;

  final path = file.path;
  if (path == null || path.isEmpty) return null;

  return File(path).readAsBytes();
}

Future<Uint8List?> readBackupFileAtPath(String path) async {
  if (path.isEmpty) return null;

  final file = File(path);
  if (!await file.exists()) return null;

  return file.readAsBytes();
}
