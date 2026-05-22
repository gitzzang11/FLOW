import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class FlowShell extends StatefulWidget {
  const FlowShell({
    super.key,
    required this.store,
    required this.onStoreChanged,
    required this.onRequireRelock,
  });

  final PromptStore store;
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
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
      case PromptSortMode.custom:
        return '직접 정렬';
    }
  }

  List<String> get _normalizedCustomPromptOrder {
    final existingIds = widget.store.prompts.map((prompt) => prompt.id).toSet();
    final seenIds = <String>{};
    final orderedIds = <String>[];

    for (final id in widget.store.settings.customPromptOrder) {
      if (existingIds.contains(id) && seenIds.add(id)) {
        orderedIds.add(id);
      }
    }

    for (final prompt in widget.store.prompts) {
      if (seenIds.add(prompt.id)) {
        orderedIds.add(prompt.id);
      }
    }

    return orderedIds;
  }

  List<PromptItem> _sortPrompts(
    List<PromptItem> prompts, {
    required PromptSortMode mode,
  }) {
    switch (mode) {
      case PromptSortMode.custom:
        final idToPrompt = {for (final p in prompts) p.id: p};
        return _normalizedCustomPromptOrder
            .where(idToPrompt.containsKey)
            .map((id) => idToPrompt[id]!)
            .toList();
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
    var nextSettings = widget.store.settings;
    if (mode == PromptSortMode.custom) {
      nextSettings = nextSettings.copyWith(
        customPromptOrder: _normalizedCustomPromptOrder,
      );
    }
    await _persistSettings(nextSettings.copyWith(promptSortMode: mode));
  }

  Future<void> _movePromptByOffset({
    required String promptId,
    required int offset,
  }) async {
    if (offset == 0) return;

    final currentMode = widget.store.settings.promptSortMode;
    final baseOrderIds = currentMode == PromptSortMode.custom
        ? _normalizedCustomPromptOrder
        : _sortPrompts(
            widget.store.prompts,
            mode: currentMode,
          ).map((p) => p.id).toList();

    final visibleIdsSet = _filteredPrompts.map((p) => p.id).toSet();
    final visibleOrderedIds = baseOrderIds
        .where(visibleIdsSet.contains)
        .toList();

    final currentIndex = visibleOrderedIds.indexOf(promptId);
    if (currentIndex == -1) return;

    final targetIndex = currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= visibleOrderedIds.length) return;

    final movedId = visibleOrderedIds.removeAt(currentIndex);
    visibleOrderedIds.insert(targetIndex, movedId);

    var vIdx = 0;
    final nextOrder = [
      for (final id in baseOrderIds)
        visibleIdsSet.contains(id) ? visibleOrderedIds[vIdx++] : id,
    ];

    await _persistSettings(
      widget.store.settings.copyWith(
        promptSortMode: PromptSortMode.custom,
        customPromptOrder: nextOrder,
      ),
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
      isGrid: isGrid,
      folderName: folderName,
      headerActions:
          widget.store.settings.promptSortMode == PromptSortMode.custom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: index == 0
                      ? null
                      : () => _movePromptByOffset(
                          promptId: prompt.id,
                          offset: -1,
                        ),
                  tooltip: '위로 이동',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  onPressed: index == totalCount - 1
                      ? null
                      : () =>
                            _movePromptByOffset(promptId: prompt.id, offset: 1),
                  tooltip: '아래로 이동',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            )
          : null,
      onCopy: () => _copy(prompt),
      onEdit: () => _openEditor(existing: prompt),
      onDelete: () => _deletePrompt(prompt),
      onDuplicate: () => _duplicatePrompt(prompt),
    );
  }

  Future<void> _openEditor({PromptItem? existing}) async {
    final result = await showDialog<PromptItem>(
      context: context,
      builder: (ctx) => PromptEditorDialog(
        folders: widget.store.folders,
        prompt: existing,
        initialFolderId: existing == null
            ? _selectedFolderId
            : existing.folderId,
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
      ),
    );
    if (result == null) return;

    setState(() {
      final idx = widget.store.prompts.indexWhere((p) => p.id == result.id);
      if (idx >= 0) {
        widget.store.prompts[idx] = result;
      } else {
        widget.store.prompts.add(result);
        widget.store.settings = widget.store.settings.copyWith(
          customPromptOrder: _normalizedCustomPromptOrder,
        );
      }
    });
    await widget.onStoreChanged();
  }

  Future<void> _deletePrompt(PromptItem p) async {
    setState(() {
      widget.store.prompts.removeWhere((item) => item.id == p.id);
      widget.store.settings = widget.store.settings.copyWith(
        customPromptOrder: _normalizedCustomPromptOrder
            .where((id) => id != p.id)
            .toList(),
      );
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
      final nextOrder = _normalizedCustomPromptOrder;
      final insertAt = nextOrder.indexOf(p.id);
      nextOrder.remove(newPrompt.id);
      nextOrder.insert(
        insertAt == -1 ? nextOrder.length : insertAt + 1,
        newPrompt.id,
      );

      widget.store.settings = widget.store.settings.copyWith(
        customPromptOrder: nextOrder,
      );
    });
    await widget.onStoreChanged();
  }

  Future<void> _showFolderDialog({FolderItem? folder}) async {
    final controller = TextEditingController(text: folder?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(folder == null ? '폴더 생성' : '폴더 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '폴더 이름',
            hintText: '내 업무용 프롬프트',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('확인'),
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

  Future<void> _copy(PromptItem p) async {
    await Clipboard.setData(ClipboardData(text: p.plainText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('클립보드에 복사되었습니다.')));
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length == 4) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleBackup() async {
    try {
      final backupBytes = Uint8List.fromList(
        utf8.encode(widget.store.exportToJson()),
      );
      final fileName =
          'flow_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '백업 파일 저장',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: backupBytes,
      );

      if (result == null) return;
      _showMessage('백업 파일이 저장되었습니다.');
    } catch (e) {
      _showMessage('백업 저장 중 오류가 발생했습니다.');
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('데이터 불러오기'),
            content: const Text('현재 데이터는 백업 파일 내용으로 교체됩니다. 계속할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('불러오기'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final backupBytes = result.files.single.bytes;
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SettingsSheet(
        settings: widget.store.settings,
        onToggleTheme: (v) {
          widget.store.settings = widget.store.settings.copyWith(darkMode: v);
          widget.onStoreChanged();
          Navigator.pop(context);
        },
        onToggleLock: (v) async {
          if (v && widget.store.settings.pinCode.isEmpty) {
            Navigator.pop(context);
            final pin = await _showPinDialog(title: 'PIN 설정');
            if (pin != null) {
              widget.store.settings = widget.store.settings.copyWith(
                lockEnabled: true,
                pinCode: pin,
              );
              await widget.onStoreChanged();
            }
          } else {
            widget.store.settings = widget.store.settings.copyWith(
              lockEnabled: v,
            );
            await widget.onStoreChanged();
            if (mounted) Navigator.pop(context);
          }
        },
        onChangePin: () async {
          Navigator.pop(context);
          final pin = await _showPinDialog(title: 'PIN 변경');
          if (pin != null) {
            widget.store.settings = widget.store.settings.copyWith(
              pinCode: pin,
            );
            await widget.onStoreChanged();
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('PIN이 변경되었습니다.')));
            }
          }
        },
        onLockNow: () {
          Navigator.pop(context);
          widget.onRequireRelock();
        },
        onBackup: _handleBackup,
        onRestore: _handleRestore,
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
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return FolderCard(
              name: '전체',
              promptCount: prompts.length,
              isSelected: _selectedFolderId.isEmpty,
              onTap: () {
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

    // Group prompts by month
    final monthGroups = <String, List<PromptItem>>{};
    for (final prompt in prompts) {
      final groupName = _getMonthGroupName(prompt.updatedAt);
      monthGroups.putIfAbsent(groupName, () => []).add(prompt);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 16,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedTags.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: isWide
                    ? null
                    : () => _scaffoldKey.currentState?.openDrawer(),
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
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  icon: const Icon(Icons.search_rounded),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'sort_newest') _changeSortMode(PromptSortMode.newest);
                    if (value == 'sort_oldest') _changeSortMode(PromptSortMode.oldest);
                    if (value == 'sort_title') _changeSortMode(PromptSortMode.title);
                    if (value == 'sort_custom') _changeSortMode(PromptSortMode.custom);
                    if (value == 'toggle_layout') {
                      final currentMode = widget.store.settings.promptViewMode;
                      final nextMode = currentMode == PromptViewMode.list
                          ? PromptViewMode.grid
                          : PromptViewMode.list;
                      _persistSettings(
                        widget.store.settings.copyWith(
                          promptViewMode: nextMode,
                        ),
                      );
                    }
                    if (value == 'add_folder') _showFolderDialog();
                    if (value == 'settings') _openSettings();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'toggle_layout',
                      child: Text('레이아웃 전환'),
                    ),
                    const PopupMenuDivider(),
                    CheckedPopupMenuItem(
                      checked: widget.store.settings.promptSortMode == PromptSortMode.newest,
                      value: 'sort_newest',
                      child: const Text('최신순 정렬'),
                    ),
                    CheckedPopupMenuItem(
                      checked: widget.store.settings.promptSortMode == PromptSortMode.oldest,
                      value: 'sort_oldest',
                      child: const Text('오래된순 정렬'),
                    ),
                    CheckedPopupMenuItem(
                      checked: widget.store.settings.promptSortMode == PromptSortMode.title,
                      value: 'sort_title',
                      child: const Text('이름순 정렬'),
                    ),
                    CheckedPopupMenuItem(
                      checked: widget.store.settings.promptSortMode == PromptSortMode.custom,
                      value: 'sort_custom',
                      child: const Text('직접 정렬'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'add_folder',
                      child: Text('폴더 추가'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('설정'),
                    ),
                  ],
                ),
              ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: FolderSidebar(
                folders: widget.store.folders,
                prompts: widget.store.prompts,
                selectedFolderId: _selectedFolderId,
                onSelectFolder: (id) => setState(() => _selectedFolderId = id),
                onCreateFolder: _showFolderDialog,
                onEditFolder: (f) => _showFolderDialog(folder: f),
                onDeleteFolder: _deleteFolder,
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 300,
              child: FolderSidebar(
                folders: widget.store.folders,
                prompts: widget.store.prompts,
                selectedFolderId: _selectedFolderId,
                onSelectFolder: (id) => setState(() => _selectedFolderId = id),
                onCreateFolder: _showFolderDialog,
                onEditFolder: (f) => _showFolderDialog(folder: f),
                onDeleteFolder: _deleteFolder,
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final is2Column = widget.store.settings.promptViewMode == PromptViewMode.grid;
                final columnCount = is2Column ? 2 : (constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2));
                const crossAxisSpacing = 16.0;
                const mainAxisSpacing = 16.0;
                const padding = 16.0;
                final totalSpacing = (columnCount - 1) * crossAxisSpacing + padding * 2;
                final itemWidth = (constraints.maxWidth - totalSpacing) / columnCount;
                final mainAxisExtent = itemWidth + 60.0;
                final gridExtent = constraints.maxWidth < 640 ? constraints.maxWidth : 380.0;

                return CustomScrollView(
                  slivers: [
                    // Horizontal folders list
                    SliverToBoxAdapter(
                      child: _buildFoldersHorizontalList(),
                    ),

                    // Layout toggle and sorting controls
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final currentMode = widget.store.settings.promptViewMode;
                                  final nextMode = currentMode == PromptViewMode.list
                                      ? PromptViewMode.grid
                                      : PromptViewMode.list;
                                  _persistSettings(
                                    widget.store.settings.copyWith(
                                      promptViewMode: nextMode,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.store.settings.promptViewMode == PromptViewMode.list
                                            ? Icons.grid_view_rounded
                                            : Icons.grid_on_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.store.settings.promptViewMode == PromptViewMode.list
                                            ? '원래 배열'
                                            : '2열 배열',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton<PromptSortMode>(
                                tooltip: '정렬',
                                onSelected: _changeSortMode,
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: PromptSortMode.newest,
                                    child: Text('최신순'),
                                  ),
                                  PopupMenuItem(
                                    value: PromptSortMode.oldest,
                                    child: Text('오래된순'),
                                  ),
                                  PopupMenuItem(
                                    value: PromptSortMode.title,
                                    child: Text('이름순'),
                                  ),
                                  PopupMenuItem(
                                    value: PromptSortMode.custom,
                                    child: Text('직접 정렬'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sort_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(_sortModeLabel),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.expand_more_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                        child: EmptyStateCard(onCreatePrompt: () => _openEditor()),
                      )
                    else
                      for (final entry in monthGroups.entries) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: is2Column
                                ? SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: mainAxisSpacing,
                                    crossAxisSpacing: crossAxisSpacing,
                                    mainAxisExtent: mainAxisExtent,
                                  )
                                : SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: gridExtent,
                                    mainAxisSpacing: mainAxisSpacing,
                                    crossAxisSpacing: crossAxisSpacing,
                                    mainAxisExtent: mainAxisExtent,
                                  ),
                            delegate: SliverChildBuilderDelegate(
                              (context, idx) {
                                final prompt = entry.value[idx];
                                final overallIdx = prompts.indexOf(prompt);
                                return _buildPromptCard(
                                  prompt: prompt,
                                  index: overallIdx,
                                  totalCount: prompts.length,
                                  isGrid: true,
                                );
                              },
                              childCount: entry.value.length,
                            ),
                          ),
                        ),
                      ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        foregroundColor: isDark ? Colors.white : Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.pin, required this.onUnlock});

  final String pin;
  final VoidCallback onUnlock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _isUnlocking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _check() {
    if (_isUnlocking) return;

    FocusScope.of(context).unfocus();
    final input = _pinController.text.trim();

    if (input == widget.pin) {
      setState(() {
        _error = null;
        _isUnlocking = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onUnlock();
      });
      return;
    }

    setState(() => _error = 'PIN이 일치하지 않습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '잠금 해제',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        enabled: !_isUnlocking,
                        decoration: InputDecoration(
                          errorText: _error,
                          counterText: '',
                        ),
                        onSubmitted: (_) => _check(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isUnlocking ? null : _check,
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
          );
        },
      ),
    );
  }
}
