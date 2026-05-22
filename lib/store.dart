import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PromptStore {
  PromptStore({
    required this.prompts,
    required this.folders,
    required this.settings,
  });

  static const _storageKey = 'flow_store_v1';
  static const backupVersion = 1;

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

  String exportToJson() {
    return jsonEncode({
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prompts': prompts.map((item) => item.toJson()).toList(),
      'folders': folders.map((item) => item.toJson()).toList(),
      'settings': settings.toJson(),
    });
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

    prompts = promptsJson
        .map((item) => PromptItem.fromJson(item as Map<String, dynamic>))
        .toList();
    folders = foldersJson
        .map((item) => FolderItem.fromJson(item as Map<String, dynamic>))
        .toList();
    settings = AppSettings.fromJson(
      settingsJson as Map<String, dynamic>? ?? const {},
    );
  }
}
