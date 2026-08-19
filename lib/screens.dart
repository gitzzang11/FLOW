import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_file_io.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class FlowShell extends StatefulWidget {
  const FlowShell({
    super.key,
    required this.store,
    this.initialBackupPath,
    required this.onStoreChanged,
    required this.onRequireRelock,
  });

  final PromptStore store;
  final String? initialBackupPath;
  final Future<void> Function() onStoreChanged;
  final VoidCallback onRequireRelock;

  @override
  State<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends State<FlowShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFolderId = '';
  String _searchQuery = '';
  bool _isSearching = false;
  final _selectedTags = <String>{};
  late final TextEditingController _searchController;

  PromptItem? _activePromptForEdit;
  bool _isEditorOpen = false;
  bool _isCreateMode = false;
  bool _isFolderSidebarOpen = true;

  static const _desktopFolderSidebarWidth = 280.0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    final startupPath = widget.initialBackupPath;
    if (startupPath != null && startupPath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleStartupBackup(startupPath);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PromptItem> get _filteredPrompts {
    final filtered = widget.store.prompts.where((p) {
      final folderMatch =
          _selectedFolderId.isEmpty || p.folderId == _selectedFolderId;
      final query = _searchQuery.toLowerCase();
      final searchMatch =
          p.title.toLowerCase().contains(query) ||
          p.plainText.toLowerCase().contains(query) ||
          p.tags.any((tag) => tag.toLowerCase().contains(query));
      final tagMatch =
          _selectedTags.isEmpty ||
          _selectedTags.every((tag) => p.tags.contains(tag));
      return folderMatch && searchMatch && tagMatch;
    }).toList();

    return _sortPrompts(filtered, mode: widget.store.settings.promptSortMode);
  }

  String get _sortModeLabel {
    switch (widget.store.settings.promptSortMode) {
      case PromptSortMode.newest:
        return '최신순';
      case PromptSortMode.oldest:
        return '오래된순';
      case PromptSortMode.title:
        return '이름순';
    }
  }

  List<PromptItem> _sortPrompts(
    List<PromptItem> prompts, {
    required PromptSortMode mode,
  }) {
    switch (mode) {
      case PromptSortMode.newest:
        return List<PromptItem>.from(prompts)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case PromptSortMode.oldest:
        return List<PromptItem>.from(prompts)
          ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case PromptSortMode.title:
        return List<PromptItem>.from(prompts)..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
  }

  Future<void> _persistSettings(AppSettings nextSettings) async {
    setState(() {
      widget.store.settings = nextSettings;
    });
    await widget.onStoreChanged();
  }

  Future<void> _changeSortMode(PromptSortMode mode) async {
    await _persistSettings(
      widget.store.settings.copyWith(promptSortMode: mode),
    );
  }

  IconData _sortModeIcon(PromptSortMode mode) {
    switch (mode) {
      case PromptSortMode.newest:
        return Icons.arrow_downward_rounded;
      case PromptSortMode.oldest:
        return Icons.arrow_upward_rounded;
      case PromptSortMode.title:
        return Icons.sort_by_alpha_rounded;
    }
  }

  PopupMenuItem<PromptSortMode> _buildSortMenuItem(
    BuildContext context,
    PromptSortMode mode,
    String label,
  ) {
    final isSelected = widget.store.settings.promptSortMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem<PromptSortMode>(
      value: mode,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.10) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _sortModeIcon(mode),
              size: 18,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _startSearch() {
    if (_isSearching) return;
    triggerInteractionHaptic(widget.store.settings);
    setState(() {
      _isSearching = true;
    });
  }

  void _closeSearch() {
    if (!_isSearching && _searchQuery.isEmpty && _selectedTags.isEmpty) return;
    triggerInteractionHaptic(widget.store.settings);
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _selectedTags.clear();
    });
  }

  void _lockNowFromKeyboard() {
    if (!widget.store.settings.lockEnabled) return;
    triggerInteractionHaptic(widget.store.settings);
    widget.onRequireRelock();
  }

  AppShortcut _shortcutFor(AppShortcutAction action) {
    return widget.store.settings.shortcuts[action.id] ??
        AppShortcut.fromAction(action);
  }

  SingleActivator _activatorFor(AppShortcutAction action) {
    final shortcut = _shortcutFor(action);
    return SingleActivator(
      shortcut.key,
      control: shortcut.control,
      alt: shortcut.alt,
      shift: shortcut.shift,
      meta: shortcut.meta,
    );
  }

  Widget _withDesktopShortcuts(Widget child) {
    return CallbackShortcuts(
      bindings: {
        _activatorFor(AppShortcutAction.newPrompt): () {
          triggerInteractionHaptic(widget.store.settings);
          _openEditor();
        },
        _activatorFor(AppShortcutAction.search): _startSearch,
        _activatorFor(AppShortcutAction.settings): _openSettings,
        _activatorFor(AppShortcutAction.lock): _lockNowFromKeyboard,
        _activatorFor(AppShortcutAction.closeSearch): () {
          if (_isEditorOpen) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isEditorOpen) _closeEditor();
            });
          } else if (_isSearching ||
              _searchQuery.isNotEmpty ||
              _selectedTags.isNotEmpty) {
            _closeSearch();
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }

  Widget _buildPromptCard({
    required PromptItem prompt,
    required int index,
    required int totalCount,
    bool isGrid = false,
  }) {
    final folderName = prompt.folderId.isEmpty
        ? '폴더 없음'
        : widget.store.folders
              .firstWhere(
                (f) => f.id == prompt.folderId,
                orElse: () => FolderItem(
                  id: '',
                  name: '폴더 없음',
                  createdAt: DateTime.now(),
                ),
              )
              .name;

    return PromptCard(
      key: ValueKey(prompt.id),
      prompt: prompt,
      settings: widget.store.settings,
      isGrid: isGrid,
      folderName: folderName,
      onCopy: () => _copy(prompt),
      onEdit: () => _openEditor(existing: prompt),
      onDelete: () => _deletePrompt(prompt),
      onDuplicate: () => _duplicatePrompt(prompt),
      onTogglePin: () => _togglePinPrompt(prompt),
    );
  }

  Future<void> _togglePinPrompt(PromptItem p) async {
    setState(() {
      final idx = widget.store.prompts.indexWhere((item) => item.id == p.id);
      if (idx >= 0) {
        widget.store.prompts[idx] = p.copyWith(isPinned: !p.isPinned);
      }
    });
    await widget.onStoreChanged();
  }

  void _openEditor({PromptItem? existing}) {
    setState(() {
      if (existing != null && _isEditorOpen && _activePromptForEdit?.id == existing.id) {
        _closeEditor();
        return;
      }
      _activePromptForEdit = existing;
      _isCreateMode = (existing == null);
      _isEditorOpen = true;
    });
  }

  void _closeEditor() {
    setState(() {
      _activePromptForEdit = null;
      _isCreateMode = false;
      _isEditorOpen = false;
    });
  }

  Widget _buildFolderSidebar() {
    return FolderSidebar(
      folders: widget.store.folders,
      prompts: widget.store.prompts,
      selectedFolderId: _selectedFolderId,
      onSelectFolder: (id) {
        triggerInteractionHaptic(widget.store.settings);
        setState(() => _selectedFolderId = id);
      },
      onCreateFolder: () {
        triggerInteractionHaptic(widget.store.settings);
        _showFolderDialog();
      },
      onEditFolder: (folder) {
        triggerInteractionHaptic(widget.store.settings);
        _showFolderDialog(folder: folder);
      },
      onDeleteFolder: (folder) {
        triggerInteractionHaptic(widget.store.settings);
        _deleteFolder(folder);
      },
      onReorder: _reorderFolder,
    );
  }

  Future<void> _deletePrompt(PromptItem p) async {
    final deletedIndex = widget.store.prompts.indexWhere((item) => item.id == p.id);
    if (deletedIndex < 0) return;

    setState(() {
      if (_activePromptForEdit?.id == p.id) {
        _closeEditor();
      }
      widget.store.prompts.removeAt(deletedIndex);
    });
    await widget.onStoreChanged();

    if (!mounted) return;
    showAppToast(
      context,
      '"${p.title}" 프롬프트를 삭제했습니다.',
      icon: Icons.delete_outline_rounded,
      duration: const Duration(seconds: 5),
      actionLabel: '되돌리기',
      onAction: () => _restoreDeletedPrompt(p, deletedIndex),
    );
  }

  Future<void> _restoreDeletedPrompt(PromptItem prompt, int originalIndex) async {
    if (widget.store.prompts.any((item) => item.id == prompt.id)) return;

    final insertIndex = math.min(originalIndex, widget.store.prompts.length);
    setState(() {
      widget.store.prompts.insert(insertIndex, prompt);
    });
    await widget.onStoreChanged();
  }

  Future<void> _duplicatePrompt(PromptItem p) async {
    final newPrompt = p.copyWith(
      id: PromptStore.newId(),
      title: '${p.title} (복사본)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      widget.store.prompts.add(newPrompt);
    });
    await widget.onStoreChanged();
  }

  Future<void> _showFolderDialog({FolderItem? folder}) async {
    var folderName = folder?.name ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(ctx).colorScheme.outlineVariant.withOpacity(0.35),
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                folder == null
                    ? Icons.create_new_folder_rounded
                    : Icons.drive_file_rename_outline_rounded,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(folder == null ? '새 폴더' : '폴더 이름 변경'),
          ],
        ),
        content: TextFormField(
          initialValue: folderName,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (value) => folderName = value,
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(ctx, value.trim());
          },
          decoration: InputDecoration(
            labelText: '폴더 이름',
            hintText: '예: 업무용 프롬프트',
            prefixIcon: const Icon(Icons.folder_outlined),
            filled: true,
            fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(ctx).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              triggerInteractionHaptic(widget.store.settings);
              Navigator.pop(ctx);
            },
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              triggerInteractionHaptic(widget.store.settings);
              final name = folderName.trim();
              if (name.isNotEmpty) Navigator.pop(ctx, name);
            },
            child: Text(folder == null ? '폴더 만들기' : '저장'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (folder == null) {
          widget.store.folders.add(
            FolderItem(
              id: PromptStore.newId(),
              name: result,
              createdAt: DateTime.now(),
            ),
          );
        } else {
          final idx = widget.store.folders.indexWhere((f) => f.id == folder.id);
          if (idx != -1) {
            widget.store.folders[idx] = folder.copyWith(name: result);
          }
        }
      });
      await widget.onStoreChanged();
    }
  }

  Future<void> _deleteFolder(FolderItem folder) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('폴더 삭제'),
            content: Text(
              '${folder.name} 폴더를 삭제할까요? 폴더 안의 프롬프트는 "폴더 없음"으로 이동됩니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      widget.store.folders.removeWhere((f) => f.id == folder.id);
      for (var i = 0; i < widget.store.prompts.length; i++) {
        if (widget.store.prompts[i].folderId == folder.id) {
          widget.store.prompts[i] = widget.store.prompts[i].copyWith(
            folderId: '',
          );
        }
      }
      if (_selectedFolderId == folder.id) {
        _selectedFolderId = '';
      }
    });
    await widget.onStoreChanged();
  }

  Future<void> _reorderFolder(int oldIdx, int newIdx) async {
    triggerInteractionHaptic(widget.store.settings);
    setState(() {
      if (oldIdx < newIdx) {
        newIdx -= 1;
      }
      final folder = widget.store.folders.removeAt(oldIdx);
      widget.store.folders.insert(newIdx, folder);
    });
    await widget.onStoreChanged();
  }

  Future<void> _copy(PromptItem p) async {
    triggerInteractionHaptic(widget.store.settings);
    await Clipboard.setData(ClipboardData(text: p.plainText));
    if (!mounted) return;
    showAppToast(context, '클립보드에 복사되었습니다.', icon: Icons.copy_rounded);
  }

  Future<String?> _showPinDialog({required String title}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('4자리 PIN을 입력하세요.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '****',
                  counterText: '',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 20),
              PinPad(
                controller: controller,
                enabled: true,
                onSubmitted: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              triggerInteractionHaptic(widget.store.settings);
              Navigator.pop(ctx);
            },
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length == 4) {
                triggerInteractionHaptic(widget.store.settings);
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final isError = message.contains('오류') ||
        message.contains('invalid') ||
        message.contains('Could not');
    showAppToast(
      context,
      message,
      icon: isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
      isError: isError,
    );
  }

  Future<void> _closeSettingsSheet(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _handleToggleLock(
    BuildContext sheetContext,
    bool enabled,
  ) async {
    triggerInteractionHaptic(widget.store.settings);
    await _closeSettingsSheet(sheetContext);
    if (!mounted) return;

    if (enabled && widget.store.settings.pinCode.isEmpty) {
      final pin = await _showPinDialog(title: 'PIN 설정');
      if (!mounted || pin == null) return;

      widget.store.settings = widget.store.settings.copyWith(
        lockEnabled: true,
        pinCode: pin,
      );
      await widget.onStoreChanged();
      return;
    }

    widget.store.settings = widget.store.settings.copyWith(
      lockEnabled: enabled,
    );
    await widget.onStoreChanged();
  }

  Future<void> _handleChangePin(BuildContext sheetContext) async {
    triggerInteractionHaptic(widget.store.settings);
    await _closeSettingsSheet(sheetContext);
    if (!mounted) return;

    final pin = await _showPinDialog(title: 'PIN 변경');
    if (!mounted || pin == null) return;

    widget.store.settings = widget.store.settings.copyWith(pinCode: pin);
    await widget.onStoreChanged();
    if (!mounted) return;

    showAppToast(context, 'PIN이 변경되었습니다.', icon: Icons.lock_reset_rounded);
  }

  Future<void> _handleBackup() async {
    triggerInteractionHaptic(widget.store.settings);
    try {
      final backupBytes = Uint8List.fromList(
        utf8.encode(widget.store.exportToJson(includeImages: true)),
      );
      final initialDirectory = await getDefaultBackupDirectory();
      final fileName =
          'flow_backup_${DateTime.now().millisecondsSinceEpoch}.flow';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '백업 파일 저장',
        initialDirectory: initialDirectory,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['flow'],
        bytes: backupBytes,
        lockParentWindow: true,
      );

      if (result == null) return;
      await writeBackupFile(result, backupBytes);
      _showMessage('백업 파일이 저장되었습니다.');
    } catch (e) {
      _showMessage('백업 저장 중 오류가 발생했습니다.');
    }
  }

  Future<void> _handleRestore() async {
    triggerInteractionHaptic(widget.store.settings);
    final initialDirectory = await getDefaultBackupDirectory();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['flow', 'json'],
      initialDirectory: initialDirectory,
      withData: true,
      lockParentWindow: true,
    );

    if (result == null) return;
    if (!mounted) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('데이터 불러오기'),
            content: const Text('현재 데이터는 백업 파일 내용으로 교체됩니다. 계속할까요?'),
            actions: [
              TextButton(
                onPressed: () {
                  triggerInteractionHaptic(widget.store.settings);
                  Navigator.pop(ctx, false);
                },
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  triggerInteractionHaptic(widget.store.settings);
                  Navigator.pop(ctx, true);
                },
                child: const Text('불러오기'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final backupBytes = await readPickedFileBytes(result.files.single);
      if (backupBytes == null || backupBytes.isEmpty) {
        throw const FormatException('Empty backup file');
      }

      final jsonString = utf8.decode(backupBytes);
      setState(() {
        widget.store.importFromJsonString(jsonString);
      });

      await widget.onStoreChanged();
      _showMessage('백업 파일을 불러왔습니다.');
    } on FormatException {
      _showMessage('백업 파일 형식이 올바르지 않습니다.');
    } catch (e) {
      _showMessage('백업 파일을 불러오는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _handleStartupBackup(String path) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Flow file import'),
            content: Text(
              'Import "$path" into Flow? Current Flow data will be replaced.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  triggerInteractionHaptic(widget.store.settings);
                  Navigator.pop(ctx, false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  triggerInteractionHaptic(widget.store.settings);
                  Navigator.pop(ctx, true);
                },
                child: const Text('Import'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final backupBytes = await readBackupFileAtPath(path);
      if (backupBytes == null || backupBytes.isEmpty) {
        throw const FormatException('Empty backup file');
      }

      final jsonString = utf8.decode(backupBytes);
      setState(() {
        widget.store.importFromJsonString(jsonString);
      });

      await widget.onStoreChanged();
      _showMessage('Flow file imported.');
    } on FormatException {
      _showMessage('The Flow file format is invalid.');
    } catch (e) {
      _showMessage('Could not import the Flow file.');
    }
  }

  void _openSettings() {
    triggerInteractionHaptic(widget.store.settings);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      builder: (ctx) => SettingsSheet(
        settings: widget.store.settings,
        onToggleTheme: (v) {
          triggerInteractionHaptic(widget.store.settings);
          Navigator.pop(ctx);
          widget.store.settings = widget.store.settings.copyWith(darkMode: v);
          widget.onStoreChanged();
        },
        onToggleLock: (v) => _handleToggleLock(ctx, v),
        onChangePin: () => _handleChangePin(ctx),
        onLockNow: () {
          triggerInteractionHaptic(widget.store.settings);
          Navigator.pop(ctx);
          widget.onRequireRelock();
        },
        onBackup: _handleBackup,
        onRestore: _handleRestore,
        onToggleHaptic: (v) {
          if (v) {
            HapticFeedback.lightImpact();
          }
          widget.store.settings = widget.store.settings.copyWith(
            hapticEnabled: v,
          );
          widget.onStoreChanged();
        },
        onToggleFolderNavigation: (v) {
          triggerInteractionHaptic(widget.store.settings);
          widget.store.settings = widget.store.settings.copyWith(
            showFolderNavigation: v,
          );
          widget.onStoreChanged();
          setState(() {});
        },
        onOpenShortcuts: () => _openShortcutSettings(ctx),
      ),
    );
  }

  void _openShortcutSettings(BuildContext settingsContext) {
    Navigator.pop(settingsContext);
    showDialog<void>(
      context: context,
      builder: (_) => ShortcutSettingsDialog(
        settings: widget.store.settings,
        onChanged: (nextSettings) {
          setState(() {
            widget.store.settings = nextSettings;
          });
          widget.onStoreChanged();
        },
      ),
    );
  }

  String _getMonthGroupName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      return '이번 달';
    } else if (date.year == now.year) {
      return '${date.month}월';
    } else {
      return '${date.year}년 ${date.month}월';
    }
  }

  Widget _buildFoldersHorizontalList() {
    final folders = widget.store.folders;
    final prompts = widget.store.prompts;

    return SizedBox(
      height: 94,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return FolderCard(
              name: '전체',
              promptCount: prompts.length,
              icon: Icons.all_inbox_rounded,
              isSelected: _selectedFolderId.isEmpty,
              onTap: () {
                triggerInteractionHaptic(widget.store.settings);
                setState(() {
                  _selectedFolderId = '';
                });
              },
            );
          }

          final folder = folders[index - 1];
          final count = prompts.where((p) => p.folderId == folder.id).length;

          return FolderCard(
            name: folder.name,
            promptCount: count,
            isSelected: _selectedFolderId == folder.id,
            onTap: () {
              triggerInteractionHaptic(widget.store.settings);
              setState(() {
                if (_selectedFolderId == folder.id) {
                  _selectedFolderId = '';
                } else {
                  _selectedFolderId = folder.id;
                }
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 900;
    final prompts = _filteredPrompts;
    final visibleTags = _searchQuery.isEmpty
        ? const <String>[]
        : (widget.store.prompts
              .expand((p) => p.tags)
              .where(
                (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toSet()
              .toList()
            ..sort());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pinnedPrompts = prompts.where((p) => p.isPinned).toList();
    final regularPrompts = prompts.where((p) => !p.isPinned).toList();

    // Group prompts by month
    final monthGroups = <String, List<PromptItem>>{};
    for (final prompt in regularPrompts) {
      final groupName = _getMonthGroupName(prompt.updatedAt);
      monthGroups.putIfAbsent(groupName, () => []).add(prompt);
    }

    return _withDesktopShortcuts(
      Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          titleSpacing: 16,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    triggerInteractionHaptic(widget.store.settings);
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                      _selectedTags.clear();
                    });
                  },
                )
              : IconButton(
                  tooltip: isWide
                      ? (_isFolderSidebarOpen ? '폴더바 닫기' : '폴더바 열기')
                      : '폴더 메뉴',
                  icon: Icon(
                    isWide && _isFolderSidebarOpen
                        ? Icons.menu_open_rounded
                        : Icons.menu_rounded,
                  ),
                  onPressed: () {
                    triggerInteractionHaptic(widget.store.settings);
                    if (isWide) {
                      setState(
                        () => _isFolderSidebarOpen = !_isFolderSidebarOpen,
                      );
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    if (_searchQuery.isEmpty) {
                      _selectedTags.clear();
                    }
                  }),
                  decoration: InputDecoration(
                    hintText: '제목, 태그, 내용 검색',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedTags.clear();
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : const Text(
                  '폴더',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
          actions: _isSearching
              ? []
              : [
                  IconButton(
                    onPressed: _startSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: '설정',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
        ),
        drawer: isWide
            ? null
            : Drawer(
                width: 280,
                child: _buildFolderSidebar(),
              ),
        body: Row(
          children: [
            if (isWide)
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: _isFolderSidebarOpen
                    ? _desktopFolderSidebarWidth
                    : 0.0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: _desktopFolderSidebarWidth,
                    maxWidth: _desktopFolderSidebarWidth,
                    child: _buildFolderSidebar(),
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cardWidth = 184.0;
                  const cardHeight = 246.0;
                  const crossAxisSpacing = 16.0;
                  const mainAxisSpacing = 16.0;
                  const padding = 16.0;
                  final contentWidth = math.max(
                    0.0,
                    constraints.maxWidth - padding * 2,
                  );
                  final columnCount = math.max(
                    1,
                    ((contentWidth + crossAxisSpacing) /
                            (cardWidth + crossAxisSpacing))
                        .floor(),
                  );
                  final gridWidth =
                      columnCount * cardWidth +
                      (columnCount - 1) * crossAxisSpacing;
                  final gridHorizontalPadding = math.max(
                    padding,
                    (constraints.maxWidth - gridWidth) / 2,
                  );
                  final gridDelegate =
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        mainAxisSpacing: mainAxisSpacing,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisExtent: cardHeight,
                      );

                  return CustomScrollView(
                    slivers: [
                      // Horizontal folders list
                      if (widget.store.settings.showFolderNavigation)
                        SliverToBoxAdapter(child: _buildFoldersHorizontalList()),

                      // Sorting controls (layout toggle removed)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: PopupMenuButton<PromptSortMode>(
                              tooltip: '정렬 방식',
                              position: PopupMenuPosition.under,
                              offset: const Offset(0, 8),
                              elevation: 8,
                              color: Theme.of(context).colorScheme.surface,
                              constraints: const BoxConstraints(minWidth: 210),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withOpacity(0.35),
                                ),
                              ),
                              onSelected: (mode) {
                                triggerInteractionHaptic(widget.store.settings);
                                _changeSortMode(mode);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<PromptSortMode>(
                                  enabled: false,
                                  height: 36,
                                  child: Text(
                                    '정렬 기준',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const PopupMenuDivider(height: 1),
                                _buildSortMenuItem(
                                  context,
                                  PromptSortMode.newest,
                                  '최신순',
                                ),
                                _buildSortMenuItem(
                                  context,
                                  PromptSortMode.oldest,
                                  '오래된순',
                                ),
                                _buildSortMenuItem(
                                  context,
                                  PromptSortMode.title,
                                  '이름순',
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _sortModeIcon(
                                        widget.store.settings.promptSortMode,
                                      ),
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _sortModeLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.expand_more_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_searchQuery.isNotEmpty && visibleTags.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: visibleTags
                                    .map(
                                      (tag) => FilterChip(
                                        label: Text('#$tag'),
                                        selected: _selectedTags.contains(tag),
                                        onSelected: (_) => setState(
                                          () => _selectedTags.contains(tag)
                                              ? _selectedTags.remove(tag)
                                              : _selectedTags.add(tag),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),

                      if (prompts.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateCard(
                            onCreatePrompt: () => _openEditor(),
                          ),
                        )
                      else ...[
                        if (pinnedPrompts.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.push_pin_rounded,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '고정된 프롬프트',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: gridHorizontalPadding,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: gridDelegate,
                              delegate: SliverChildBuilderDelegate((
                                context,
                                idx,
                              ) {
                                final prompt = pinnedPrompts[idx];
                                final overallIdx = prompts.indexOf(prompt);
                                return _buildPromptCard(
                                  prompt: prompt,
                                  index: overallIdx,
                                  totalCount: prompts.length,
                                  isGrid: true,
                                );
                              }, childCount: pinnedPrompts.length),
                            ),
                          ),
                        ],
                        for (final entry in monthGroups.entries) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                12,
                              ),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: gridHorizontalPadding,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: gridDelegate,
                              delegate: SliverChildBuilderDelegate((
                                context,
                                idx,
                              ) {
                                final prompt = entry.value[idx];
                                final overallIdx = prompts.indexOf(prompt);
                                return _buildPromptCard(
                                  prompt: prompt,
                                  index: overallIdx,
                                  totalCount: prompts.length,
                                  isGrid: true,
                                );
                              }, childCount: entry.value.length),
                            ),
                          ),
                        ],
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  );
                },
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: _isEditorOpen ? 420.0 : 0.0,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                // Keep the editor laid out at its final width while the
                // container animates, then reveal it through the clip.
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: _isEditorOpen ? 420.0 : 0.0,
                  maxWidth: _isEditorOpen ? 420.0 : 0.0,
                  child: _isEditorOpen
                      ? RightSideEditor(
                          key: ValueKey(_activePromptForEdit?.id ?? 'create'),
                          folders: widget.store.folders,
                          prompt: _activePromptForEdit,
                          initialFolderId: _activePromptForEdit == null
                              ? _selectedFolderId
                              : _activePromptForEdit!.folderId,
                          favoriteColors: widget.store.settings.favoriteColors,
                          onToggleFavorite: (color) {
                            final favorites = List<int>.from(
                              widget.store.settings.favoriteColors,
                            );
                            if (favorites.contains(color)) {
                              favorites.remove(color);
                            } else {
                              favorites.add(color);
                            }
                            widget.store.settings = widget.store.settings.copyWith(
                              favoriteColors: favorites,
                            );
                            widget.onStoreChanged();
                          },
                          settings: widget.store.settings,
                          onSave: (result) async {
                            setState(() {
                              final idx = widget.store.prompts.indexWhere((p) => p.id == result.id);
                              if (idx >= 0) {
                                widget.store.prompts[idx] = result;
                              } else {
                                widget.store.prompts.add(result);
                              }
                              _activePromptForEdit = null;
                              _isEditorOpen = false;
                            });
                            await widget.onStoreChanged();
                          },
                          onClose: _closeEditor,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _isEditorOpen
            ? null
            : FloatingActionButton(
                onPressed: () {
                  triggerInteractionHaptic(widget.store.settings);
                  _openEditor();
                },
          backgroundColor: isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA),
          foregroundColor: isDark ? Colors.white : Colors.black,
          shape: const CircleBorder(),
          child: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class ShakeCurve extends Curve {
  const ShakeCurve({this.count = 3.0});
  final double count;

  @override
  double transformInternal(double t) {
    return math.sin(t * count * 2 * math.pi);
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.pin,
    required this.onUnlock,
    required this.settings,
  });

  final String pin;
  final VoidCallback onUnlock;
  final AppSettings settings;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isUnlocking = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  Timer? _countdownTimer;
  bool _loadingState = true;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: const ShakeCurve(count: 3.0),
      ),
    );
    _loadLockoutState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLockoutState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutMillis = prefs.getInt('lockscreen_lockout_until') ?? 0;
      final failed = prefs.getInt('lockscreen_failed_attempts') ?? 0;

      final lockoutTime = DateTime.fromMillisecondsSinceEpoch(lockoutMillis);
      final now = DateTime.now();

      if (mounted) {
        setState(() {
          _failedAttempts = failed;
          _loadingState = false;
          if (lockoutTime.isAfter(now)) {
            final diffSeconds = lockoutTime.difference(now).inSeconds;
            if (diffSeconds > 0) {
              _startLockoutCountdown(diffSeconds);
            } else {
              _clearFailedAttempts();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = false;
        });
      }
    }
  }

  void _startLockoutCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutSecondsRemaining = seconds;
      _error = '10회 실패로 잠금해제가 제한됩니다. ($_lockoutSecondsRemaining초 후 재시도)';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_lockoutSecondsRemaining > 1) {
          _lockoutSecondsRemaining--;
          _error = '10회 실패로 잠금해제가 제한됩니다. ($_lockoutSecondsRemaining초 후 재시도)';
        } else {
          _lockoutSecondsRemaining = 0;
          _countdownTimer?.cancel();
          _clearFailedAttempts();
          _error = null;
          _pinController.clear();
        }
      });
    });
  }

  Future<void> _incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts++;
    await prefs.setInt('lockscreen_failed_attempts', _failedAttempts);

    if (_failedAttempts >= 10) {
      final now = DateTime.now();
      final lockoutTime = now.add(const Duration(minutes: 1));
      await prefs.setInt(
        'lockscreen_lockout_until',
        lockoutTime.millisecondsSinceEpoch,
      );
      _startLockoutCountdown(60);
    }
  }

  Future<void> _clearFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = 0;
    _lockoutSecondsRemaining = 0;
    await prefs.remove('lockscreen_failed_attempts');
    await prefs.remove('lockscreen_lockout_until');
  }

  Future<void> _check() async {
    triggerInteractionHaptic(widget.settings);
    if (_isUnlocking || _lockoutSecondsRemaining > 0 || _loadingState) return;

    FocusScope.of(context).unfocus();
    final input = _pinController.text.trim();

    if (input == widget.pin) {
      setState(() {
        _error = null;
        _isUnlocking = true;
      });
      await _clearFailedAttempts();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onUnlock();
      });
      return;
    }

    // Wrong PIN
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0.0);

    await _incrementFailedAttempts();

    if (mounted) {
      setState(() {
        if (_failedAttempts >= 10) {
          // Lockout is active, countdown handles error text update.
        } else {
          _error = 'PIN이 일치하지 않습니다. (시도 횟수: $_failedAttempts/10)';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockedOut = _lockoutSecondsRemaining > 0;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLockedOut
                              ? Icons.lock_clock_outlined
                              : Icons.lock_person_outlined,
                          size: 80,
                          color: isLockedOut
                              ? Colors.redAccent
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isLockedOut ? '잠금 해제 제한됨' : '잠금 해제',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isLockedOut ? Colors.redAccent : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          enabled:
                              !_isUnlocking && !isLockedOut && !_loadingState,
                          decoration: InputDecoration(
                            errorText: _error,
                            counterText: '',
                            prefixIcon: isLockedOut
                                ? const Icon(
                                    Icons.timer,
                                    color: Colors.redAccent,
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _check(),
                        ),
                        const SizedBox(height: 24),
                        if (!isLockedOut && !_loadingState) ...[
                          PinPad(
                            controller: _pinController,
                            enabled: !_isUnlocking,
                            onSubmitted: _check,
                          ),
                          const SizedBox(height: 24),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                (_isUnlocking || isLockedOut || _loadingState)
                                ? null
                                : _check,
                            child: _isUnlocking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('확인'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
