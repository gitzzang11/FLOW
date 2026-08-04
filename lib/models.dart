import 'package:flutter/services.dart';

enum AppPalette {
  ink(0xFF183153),
  coral(0xFFE85D5D),
  sky(0xFF3B82F6),
  amber(0xFFF59E0B),
  mint(0xFF10B981),
  violet(0xFF8B5CF6);

  const AppPalette(this.value);
  final int value;
}

enum AppShortcutAction {
  newPrompt(
    'new_prompt',
    '새 프롬프트',
    '새 프롬프트 편집기를 엽니다',
    LogicalKeyboardKey.keyN,
    control: true,
  ),
  search(
    'search',
    '검색',
    '프롬프트 검색을 시작합니다',
    LogicalKeyboardKey.keyF,
    control: true,
  ),
  settings(
    'settings',
    '설정',
    '설정 메뉴를 엽니다',
    LogicalKeyboardKey.comma,
    control: true,
  ),
  lock(
    'lock',
    '지금 잠금',
    '앱을 즉시 잠급니다',
    LogicalKeyboardKey.keyL,
    control: true,
  ),
  closeSearch(
    'close_search',
    '닫기 / 나가기',
    '검색·편집·작성 화면을 닫습니다. 닫을 화면이 없으면 입력 포커스를 해제합니다',
    LogicalKeyboardKey.escape,
  ),
  editPrompt(
    'edit_prompt',
    '프롬프트 편집',
    '선택한 프롬프트를 편집합니다',
    LogicalKeyboardKey.enter,
  ),
  copyPrompt(
    'copy_prompt',
    '프롬프트 복사',
    '선택한 프롬프트를 클립보드에 복사합니다',
    LogicalKeyboardKey.space,
  ),
  deletePrompt(
    'delete_prompt',
    '프롬프트 삭제',
    '선택한 프롬프트를 삭제합니다',
    LogicalKeyboardKey.delete,
  ),
  duplicatePrompt(
    'duplicate_prompt',
    '프롬프트 복제',
    '선택한 프롬프트를 복제합니다',
    LogicalKeyboardKey.keyD,
    control: true,
  ),
  togglePin(
    'toggle_pin',
    '프롬프트 고정',
    '선택한 프롬프트를 고정하거나 해제합니다',
    LogicalKeyboardKey.keyP,
  ),
  promptActions(
    'prompt_actions',
    '프롬프트 메뉴',
    '선택한 프롬프트의 추가 메뉴를 엽니다',
    LogicalKeyboardKey.keyM,
    shift: true,
  );

  const AppShortcutAction(
    this.id,
    this.title,
    this.description,
    this.defaultKey, {
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final String id;
  final String title;
  final String description;
  final LogicalKeyboardKey defaultKey;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;
}

class AppShortcut {
  const AppShortcut({
    required this.key,
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final LogicalKeyboardKey key;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;

  factory AppShortcut.fromAction(AppShortcutAction action) => AppShortcut(
        key: action.defaultKey,
        control: action.control,
        alt: action.alt,
        shift: action.shift,
        meta: action.meta,
      );

  factory AppShortcut.fromJson(Map<String, dynamic> json) {
    final keyId = (json['keyId'] as num?)?.toInt();
    final key = keyId == null
        ? LogicalKeyboardKey.keyN
        : LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey.keyN;
    return AppShortcut(
      key: key,
      control: json['control'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyId': key.keyId,
        'control': control,
        'alt': alt,
        'shift': shift,
        'meta': meta,
      };

  @override
  bool operator ==(Object other) {
    return other is AppShortcut &&
        other.key.keyId == key.keyId &&
        other.control == control &&
        other.alt == alt &&
        other.shift == shift &&
        other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(key.keyId, control, alt, shift, meta);
}

enum PromptSortMode {
  newest('newest'),
  oldest('oldest'),
  title('title');

  const PromptSortMode(this.storageValue);

  final String storageValue;

  static PromptSortMode fromStorage(String? value) {
    return PromptSortMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => PromptSortMode.newest,
    );
  }
}

enum PromptViewMode {
  list('list'),
  grid('grid');

  const PromptViewMode(this.storageValue);

  final String storageValue;

  static PromptViewMode fromStorage(String? value) {
    return PromptViewMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => PromptViewMode.list,
    );
  }
}

class PromptItem {
  PromptItem({
    required this.id,
    required this.title,
    required this.titleColorValue,
    required this.folderId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.segments,
    this.isPinned = false,
    this.imagePaths = const [],
  });

  final String id;
  final String title;
  final int titleColorValue;
  final String folderId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PromptSegment> segments;
  final bool isPinned;
  final List<String> imagePaths;

  String get plainText => segments.map((segment) => segment.text).join();

  PromptItem copyWith({
    String? id,
    String? title,
    int? titleColorValue,
    String? folderId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PromptSegment>? segments,
    bool? isPinned,
    List<String>? imagePaths,
  }) {
    return PromptItem(
      id: id ?? this.id,
      title: title ?? this.title,
      titleColorValue: titleColorValue ?? this.titleColorValue,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      segments: segments ?? this.segments,
      isPinned: isPinned ?? this.isPinned,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    return PromptItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleColorValue: json['titleColorValue'] as int? ?? AppPalette.ink.value,
      folderId: json['folderId'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      segments: (json['segments'] as List<dynamic>? ?? [])
          .map((item) => PromptSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      isPinned: json['isPinned'] as bool? ?? false,
      imagePaths: (json['imagePaths'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'titleColorValue': titleColorValue,
    'folderId': folderId,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'segments': segments.map((item) => item.toJson()).toList(),
    'isPinned': isPinned,
    'imagePaths': imagePaths,
  };
}

class PromptSegment {
  PromptSegment({required this.text, required this.colorValue});

  final String text;
  final int colorValue;

  PromptSegment copyWith({String? text, int? colorValue}) {
    return PromptSegment(
      text: text ?? this.text,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory PromptSegment.fromJson(Map<String, dynamic> json) {
    return PromptSegment(
      text: json['text'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? AppPalette.ink.value,
    );
  }

  Map<String, dynamic> toJson() => {'text': text, 'colorValue': colorValue};
}

class FolderItem {
  FolderItem({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  FolderItem copyWith({String? id, String? name, DateTime? createdAt}) {
    return FolderItem(
      // Added const for better performance
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.lockEnabled = false,
    this.pinCode = '',
    this.favoriteColors = const [],
    this.promptSortMode = PromptSortMode.newest,
    this.promptViewMode = PromptViewMode.grid,
    this.customPromptOrder = const [],
    this.hapticEnabled = true,
    this.showFolderNavigation = true,
    Map<String, AppShortcut>? shortcuts = const {},
  }) : _shortcutBindings = shortcuts;

  final bool darkMode;
  final bool lockEnabled;
  final String pinCode;
  final List<int> favoriteColors;
  final PromptSortMode promptSortMode;
  final PromptViewMode promptViewMode;
  final List<String> customPromptOrder;
  final bool hapticEnabled;
  final bool showFolderNavigation;
  // Nullable backing storage keeps settings created before this field was
  // introduced (for example during hot reload) compatible with new code.
  final Map<String, AppShortcut>? _shortcutBindings;

  Map<String, AppShortcut> get shortcuts => _shortcutBindings ?? const {};

  AppSettings copyWith({
    bool? darkMode,
    bool? lockEnabled,
    String? pinCode,
    List<int>? favoriteColors,
    PromptSortMode? promptSortMode,
    PromptViewMode? promptViewMode,
    List<String>? customPromptOrder,
    bool? hapticEnabled,
    bool? showFolderNavigation,
    Map<String, AppShortcut>? shortcuts,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      lockEnabled: lockEnabled ?? this.lockEnabled,
      pinCode: pinCode ?? this.pinCode,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      promptSortMode: promptSortMode ?? this.promptSortMode,
      promptViewMode: promptViewMode ?? this.promptViewMode,
      customPromptOrder: customPromptOrder ?? this.customPromptOrder,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      showFolderNavigation: showFolderNavigation ?? this.showFolderNavigation,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    darkMode: json['darkMode'] as bool? ?? false,
    lockEnabled: json['lockEnabled'] as bool? ?? false,
    pinCode: json['pinCode'] as String? ?? '',
    favoriteColors: (json['favoriteColors'] as List<dynamic>? ?? [])
        .cast<int>(),
    promptSortMode: PromptSortMode.fromStorage(
      json['promptSortMode'] as String?,
    ),
    promptViewMode: PromptViewMode.fromStorage(
      json['promptViewMode'] as String?,
    ),
    customPromptOrder: (json['customPromptOrder'] as List<dynamic>? ?? [])
        .cast<String>(),
    hapticEnabled: json['hapticEnabled'] as bool? ?? true,
    showFolderNavigation: json['showFolderNavigation'] as bool? ?? true,
    shortcuts: (json['shortcuts'] as Map<dynamic, dynamic>? ?? {}).map(
      (key, value) => MapEntry(
        key.toString(),
        AppShortcut.fromJson((value as Map<dynamic, dynamic>).cast<String, dynamic>()),
      ),
    ),
  );

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'lockEnabled': lockEnabled,
    'pinCode': pinCode,
    'favoriteColors': favoriteColors,
    'promptSortMode': promptSortMode.storageValue,
    'promptViewMode': promptViewMode.storageValue,
    'customPromptOrder': customPromptOrder,
    'hapticEnabled': hapticEnabled,
    'showFolderNavigation': showFolderNavigation,
    'shortcuts': shortcuts.map((key, value) => MapEntry(key, value.toJson())),
  };
}

void triggerInteractionHaptic(AppSettings settings) {
  if (settings.hapticEnabled) {
    HapticFeedback.lightImpact();
  }
}

