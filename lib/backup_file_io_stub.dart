import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> writeBackupFile(String path, Uint8List bytes) async {}

Future<Uint8List?> readPickedFileBytes(PlatformFile file) async {
  return file.bytes;
}
