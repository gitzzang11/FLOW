import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PromptStore {
  PromptStore({
    required this.prompts,
    required this.folders,
    required this.settings,
  });

  static const _storageKey = 'flow_store_v1';
  static const backupVersion = 2;

  List<PromptItem> prompts;
  List<FolderItem> folders;
  AppSettings settings;

  static Future<PromptStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return PromptStore(
        prompts: [],
        folders: [],
        settings: const AppSettings(),
      );
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PromptStore(
      prompts: (json['prompts'] as List<dynamic>? ?? [])
          .map((item) => PromptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      folders: (json['folders'] as List<dynamic>? ?? [])
          .map((item) => FolderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      settings: AppSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, exportToJson());
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  String exportToJson({bool includeImages = false}) {
    final payload = <String, dynamic>{
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prompts': prompts.map((item) => item.toJson()).toList(),
      'folders': folders.map((item) => item.toJson()).toList(),
      'settings': settings.toJson(),
    };

    if (includeImages) {
      payload['images'] = _collectEmbeddedImages();
    }
    return jsonEncode(payload);
  }

  Map<String, String> _collectEmbeddedImages() {
    final embedded = <String, String>{};
    for (final prompt in prompts) {
      for (final path in prompt.imagePaths) {
        if (embedded.containsKey(path)) continue;
        final file = File(path);
        if (!file.existsSync()) continue;
        try {
          embedded[path] = base64Encode(file.readAsBytesSync());
        } on FileSystemException {
          // Keep the backup usable even when one attachment cannot be read.
        }
      }
    }
    return embedded;
  }

  void importFromJsonString(String rawJson) {
    final json = jsonDecode(rawJson);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object.');
    }

    final promptsJson = json['prompts'];
    final foldersJson = json['folders'];
    final settingsJson = json['settings'];

    if (promptsJson is! List || foldersJson is! List) {
      throw const FormatException('Backup is missing prompt or folder lists.');
    }
    if (settingsJson != null && settingsJson is! Map<String, dynamic>) {
      throw const FormatException('Backup settings format is invalid.');
    }

    final embeddedImages = _restoreEmbeddedImages(json['images']);
    prompts = promptsJson.map((item) {
      final prompt = PromptItem.fromJson(item as Map<String, dynamic>);
      final restoredPaths = prompt.imagePaths
          .map((path) => embeddedImages[path] ?? path)
          .toList();
      return prompt.copyWith(imagePaths: restoredPaths);
    }).toList();
    folders = foldersJson
        .map((item) => FolderItem.fromJson(item as Map<String, dynamic>))
        .toList();
    settings = AppSettings.fromJson(
      settingsJson as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, String> _restoreEmbeddedImages(dynamic rawImages) {
    if (rawImages is! Map) return const {};

    final appDataDir = Platform.environment['APPDATA'] ??
        Directory.systemTemp.path;
    final imagesDir = Directory('$appDataDir/Flow/images');
    try {
      imagesDir.createSync(recursive: true);
    } on FileSystemException {
      return const {};
    }

    final restored = <String, String>{};
    for (final entry in rawImages.entries) {
      final sourcePath = entry.key.toString();
      final encoded = entry.value;
      if (encoded is! String || encoded.isEmpty) continue;

      final originalName = sourcePath.split(RegExp(r'[\\/]')).last;
      final safeName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final targetPath = '${imagesDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      try {
        File(targetPath).writeAsBytesSync(base64Decode(encoded));
        restored[sourcePath] = targetPath;
      } on FormatException {
        // Ignore malformed attachment data and keep the prompt itself.
      } on FileSystemException {
        // Ignore attachments that cannot be written on this machine.
      }
    }
    return restored;
  }
}
