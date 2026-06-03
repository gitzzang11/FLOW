import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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
