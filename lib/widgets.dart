import 'dart:io';
import 'dart:ui' show ImageFilter, lerpDouble;
import 'dart:math' as math;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

class FolderSidebar extends StatelessWidget {
  const FolderSidebar({
    super.key,
    required this.folders,
    required this.prompts,
    required this.selectedFolderId,
    required this.onSelectFolder,
    required this.onCreateFolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
    required this.onReorder,
  });

  final List<FolderItem> folders;
  final List<PromptItem> prompts;
  final String selectedFolderId;
  final ValueChanged<String> onSelectFolder;
  final VoidCallback onCreateFolder;
  final ValueChanged<FolderItem> onEditFolder;
  final ValueChanged<FolderItem> onDeleteFolder;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF161618)
        : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppGradients.accent,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_copy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '폴더',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '폴더 추가',
                    onPressed: onCreateFolder,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FolderTile(
                label: '모든 프롬프트',
                count: prompts.length,
                selected: selectedFolderId.isEmpty,
                onTap: () => onSelectFolder(''),
                settings: const AppSettings(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: folders.length,
                  onReorder: onReorder,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double animValue = Curves.easeInOut.transform(animation.value);
                        final double elevation = lerpDouble(0, 6, animValue)!;
                        return Material(
                          elevation: elevation,
                          color: Colors.transparent,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final count = prompts
                        .where((p) => p.folderId == folder.id)
                        .length;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(folder.id),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _FolderTile(
                          label: folder.name,
                          count: count,
                          selected: selectedFolderId == folder.id,
                          onTap: () => onSelectFolder(folder.id),
                          settings: const AppSettings(),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz_rounded, size: 20),
                            tooltip: '폴더 설정',
                            position: PopupMenuPosition.under,
                            offset: const Offset(-132, 8),
                            elevation: 8,
                            constraints: const BoxConstraints(minWidth: 176),
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.35),
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') onEditFolder(folder);
                              if (value == 'delete') onDeleteFolder(folder);
                            },
                            itemBuilder: (context) {
                              final colorScheme = Theme.of(context).colorScheme;
                              return [
                                PopupMenuItem(
                                  value: 'edit',
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.drive_file_rename_outline_rounded, size: 18),
                                        SizedBox(width: 12),
                                        Text('이름 변경'),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: colorScheme.error,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '삭제',
                                          style: TextStyle(color: colorScheme.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTile extends StatefulWidget {
  const _FolderTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.settings,
    this.trailing,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final AppSettings settings;
  final Widget? trailing;

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final nameColor = widget.selected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7));

    final countColor = widget.selected
        ? (isDark
              ? Colors.white.withOpacity(0.6)
              : Colors.black.withOpacity(0.5))
        : (isDark
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.4));

    final iconColor = widget.selected
        ? scheme.primary
        : (isDark
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.4));

    final tileBg = widget.selected
        ? (isDark
              ? Colors.white.withOpacity(0.08)
              : scheme.primary.withOpacity(0.08))
        : (_isHovered || _isFocused
            ? (isDark
                ? Colors.white.withOpacity(0.04)
                : scheme.primary.withOpacity(0.04))
            : Colors.transparent);

    final border = Border.all(
      color: _isFocused
          ? scheme.primary
          : (widget.selected
              ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : scheme.primary.withOpacity(0.15))
              : (_isHovered
                  ? (isDark
                      ? Colors.white.withOpacity(0.1)
                      : scheme.primary.withOpacity(0.1))
                  : Colors.transparent)),
      width: 1.5,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        onHover: (hovered) => setState(() => _isHovered = hovered),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Row(
            children: [
              Icon(
                widget.selected ? Icons.folder_open_rounded : Icons.folder_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: widget.selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: nameColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '프롬프트 ${widget.count}개',
                      style: TextStyle(color: countColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                Theme(
                  data: Theme.of(context).copyWith(
                    iconButtonTheme: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white54
                            : Colors.black54,
                      ),
                    ),
                  ),
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromptToolbar extends StatelessWidget {
  const PromptToolbar({
    super.key,
    required this.searchQuery,
    required this.allTags,
    required this.selectedTags,
    required this.activeFolderLabel,
    required this.folderPromptCount,
    required this.onSearchChanged,
    required this.onToggleTag,
    this.onOpenDrawer,
  });

  final String searchQuery;
  final List<String> allTags;
  final Set<String> selectedTags;
  final String activeFolderLabel;
  final int folderPromptCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggleTag;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                if (onOpenDrawer != null) ...[
                  IconButton(
                    onPressed: onOpenDrawer,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '제목으로 검색',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  searchQuery.isNotEmpty || selectedTags.isNotEmpty
                      ? '검색 결과: $folderPromptCount개'
                      : '$activeFolderLabel ($folderPromptCount)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (allTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allTags
                      .map(
                        (tag) => FilterChip(
                          label: Text('#$tag'),
                          selected: selectedTags.contains(tag),
                          onSelected: (_) => onToggleTag(tag),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FolderQuickAccessBar extends StatelessWidget {
  const FolderQuickAccessBar({
    super.key,
    required this.folders,
    required this.prompts,
    required this.selectedFolderId,
    required this.onSelectFolder,
    this.onOpenDrawer,
  });

  final List<FolderItem> folders;
  final List<PromptItem> prompts;
  final String selectedFolderId;
  final ValueChanged<String> onSelectFolder;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          if (onOpenDrawer != null) ...[
            IconButton(
              onPressed: onOpenDrawer,
              tooltip: '폴더 열기',
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FolderQuickChip(
                  label: '전체',
                  count: prompts.length,
                  selected: selectedFolderId.isEmpty,
                  onTap: () => onSelectFolder(''),
                ),
                ...folders.map((folder) {
                  final count = prompts
                      .where((p) => p.folderId == folder.id)
                      .length;
                  return _FolderQuickChip(
                    label: folder.name,
                    count: count,
                    selected: selectedFolderId == folder.id,
                    onTap: () => onSelectFolder(folder.id),
                  );
                }),
              ],
            ),
          ),
          Container(
            width: 10,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.surface.withOpacity(0), scheme.surface],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderQuickChip extends StatelessWidget {
  const _FolderQuickChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text('$label · $count'),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primaryContainer,
        side: BorderSide(
          color: selected
              ? scheme.primary.withOpacity(0.25)
              : scheme.outlineVariant.withOpacity(0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class PromptCard extends StatefulWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    required this.settings,
    this.isGrid = false,
    required this.folderName,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onTogglePin,
  });

  final PromptItem prompt;
  final AppSettings settings;
  final String folderName;
  final bool isGrid;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onTogglePin;

  @override
  State<PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<PromptCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOverlayHovered = false;
  bool _isIconHovered = false;

  AppShortcut _shortcutFor(AppShortcutAction action) {
    return widget.settings.shortcuts[action.id] ??
        AppShortcut.fromAction(action);
  }

  bool _matchesShortcut(AppShortcutAction action, KeyEvent event) {
    if (!_isHovered) return false;

    final shortcut = _shortcutFor(action);
    final keyboard = HardwareKeyboard.instance;
    return event.logicalKey == shortcut.key &&
        keyboard.isControlPressed == shortcut.control &&
        keyboard.isAltPressed == shortcut.alt &&
        keyboard.isShiftPressed == shortcut.shift &&
        keyboard.isMetaPressed == shortcut.meta;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Positioned(
          width: math.min(widget.prompt.imagePaths.length * 44.0 + 8.0, 180.0),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-8, 28),
            child: MouseRegion(
              onEnter: (_) {
                _isOverlayHovered = true;
              },
              onExit: (_) {
                _isOverlayHovered = false;
                _hideOverlayWithDelay();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.prompt.imagePaths.map((path) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlayWithDelay() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_isIconHovered && !_isOverlayHovered) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  void _showImageViewerDialog(BuildContext context, List<String> paths) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return _ImageViewerDialog(imagePaths: paths);
      },
    );
  }

  bool _isLocked() {
    final titleLower = widget.prompt.title.toLowerCase();
    if (titleLower.contains('잠금') || titleLower.contains('잠긴')) {
      return true;
    }
    if (widget.prompt.tags.any((tag) {
      final tagLower = tag.toLowerCase();
      return tagLower == '잠금' || tagLower == 'lock';
    })) {
      return true;
    }
    return false;
  }

  String _formatMonthDay(DateTime dt) {
    return '${dt.month}월 ${dt.day}일';
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textStyle = TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.prompt.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.copy_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text('복사', style: textStyle),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onCopy();
                },
              ),
              ListTile(
                leading: Icon(
                  widget.prompt.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  widget.prompt.isPinned ? '고정 해제' : '상단 고정',
                  style: textStyle,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onTogglePin();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text('편집', style: textStyle),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.control_point_duplicate_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text('복제', style: textStyle),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDuplicate();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  '삭제',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = _isLocked();

    final titleColor = isDark ? Colors.white : Colors.black;
    final dateColor = isDark ? Colors.white60 : Colors.black54;

    final titleStyle = TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.bold,
      color: titleColor,
    );

    final dateStyle = TextStyle(fontSize: 12.0, color: dateColor);

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (_matchesShortcut(AppShortcutAction.editPrompt, event)) {
            widget.onEdit();
            return KeyEventResult.handled;
          } else if (_matchesShortcut(AppShortcutAction.copyPrompt, event)) {
            widget.onCopy();
            return KeyEventResult.handled;
          } else if (_matchesShortcut(AppShortcutAction.deletePrompt, event)) {
            widget.onDelete();
            return KeyEventResult.handled;
          } else if (_matchesShortcut(AppShortcutAction.duplicatePrompt, event)) {
            widget.onDuplicate();
            return KeyEventResult.handled;
          } else if (_matchesShortcut(AppShortcutAction.togglePin, event)) {
            widget.onTogglePin();
            return KeyEventResult.handled;
          } else if ((_isHovered &&
                  event.logicalKey == LogicalKeyboardKey.contextMenu) ||
              _matchesShortcut(AppShortcutAction.promptActions, event)) {
            _showActionSheet(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _focusNode.requestFocus();
        },
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onEdit,
          onLongPress: () => _showActionSheet(context),
          onSecondaryTapUp: (_) => _showActionSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..scale((_isHovered || _isFocused) ? 1.03 : 1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: (_isHovered || _isFocused)
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: AspectRatio(
              aspectRatio: 3.0 / 4.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isFocused
                        ? Theme.of(context).colorScheme.primary
                        : (_isHovered
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Colors.transparent),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Background Content
                    if (widget.prompt.imagePaths.isEmpty)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 52),
                          child: isLocked
                              ? Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 40,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black26,
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.topLeft,
                                  child: Text.rich(
                                    TextSpan(
                                      children: widget.prompt.segments
                                          .map(
                                            (segment) => TextSpan(
                                              text: segment.text,
                                              style: TextStyle(
                                                color: Color(segment.colorValue),
                                                height: 1.4,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Image.file(
                          File(widget.prompt.imagePaths.first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark ? Colors.white12 : Colors.black12,
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined, size: 24),
                              ),
                            );
                          },
                        ),
                      ),

                    // Image Viewer Indicator (Left-Top)
                    if (widget.prompt.imagePaths.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: MouseRegion(
                            onEnter: (_) {
                              _isIconHovered = true;
                              _showOverlay();
                            },
                            onExit: (_) {
                              _isIconHovered = false;
                              _hideOverlayWithDelay();
                            },
                            child: GestureDetector(
                              onTap: () => _showImageViewerDialog(context, widget.prompt.imagePaths),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: const Icon(
                                  Icons.collections_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Pin Indicator (Right-Top)
                    if (widget.prompt.isPinned)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                    // Bottom Glassmorphism Title Panel (Floating Oval Capsule)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.45)
                                  : Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.prompt.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: '프롬프트 복사',
                                  child: IconButton(
                                    onPressed: widget.onCopy,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    icon: Icon(
                                      Icons.copy_rounded,
                                      size: 15,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.onCreatePrompt});

  final VoidCallback onCreatePrompt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_clear_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 저장된 프롬프트가 없습니다',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreatePrompt,
            icon: const Icon(Icons.add),
            label: const Text('첫 프롬프트 만들기'),
          ),
        ],
      ),
    );
  }
}

class RightSideEditor extends StatefulWidget {
  const RightSideEditor({
    super.key,
    required this.folders,
    this.prompt,
    this.initialFolderId = '',
    required this.favoriteColors,
    required this.onToggleFavorite,
    required this.settings,
    required this.onSave,
    required this.onClose,
  });

  final List<FolderItem> folders;
  final PromptItem? prompt;
  final String initialFolderId;
  final List<int> favoriteColors;
  final ValueChanged<int> onToggleFavorite;
  final AppSettings settings;
  final ValueChanged<PromptItem> onSave;
  final VoidCallback onClose;

  @override
  State<RightSideEditor> createState() => _RightSideEditorState();
}

class _RightSideEditorState extends State<RightSideEditor> {
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late String _selectedFolderId;
  late int _titleColorValue;
  late int _defaultTextColor;
  late List<PromptSegment> _segments;
  late List<String> _imagePaths;
  bool _isDragOver = false;

  int get _currentDefaultTextColor => widget.settings.darkMode
      ? Colors.white.value
      : Colors.black.value;

  final List<Color> _presetColors = [
    const Color(0xFF111827),
    const Color(0xFF1D4ED8),
    const Color(0xFF7C3AED),
    const Color(0xFFDB2777),
    const Color(0xFFDC2626),
    const Color(0xFFEA580C),
    const Color(0xFFD97706),
    const Color(0xFF65A30D),
    const Color(0xFF059669),
    const Color(0xFF0891B2),
    const Color(0xFF0F766E),
    const Color(0xFF4F46E5),
    const Color(0xFF2563EB),
    const Color(0xFF0EA5E9),
    const Color(0xFF9333EA),
    const Color(0xFFC026D3),
    const Color(0xFFE11D48),
    const Color(0xFFB91C1C),
    const Color(0xFF9A3412),
    const Color(0xFFA16207),
    const Color(0xFF3F6212),
    const Color(0xFF166534),
    const Color(0xFF155E75),
    const Color(0xFF334155),
  ];

  @override
  void initState() {
    super.initState();
    _defaultTextColor = widget.settings.darkMode
        ? Colors.white.value
        : Colors.black.value;
    _titleController = TextEditingController(text: widget.prompt?.title ?? '');
    _tagsController = TextEditingController(
      text: widget.prompt?.tags.join(', ') ?? '',
    );
    _selectedFolderId = widget.prompt?.folderId ?? widget.initialFolderId;
    _titleColorValue = widget.prompt?.titleColorValue ?? _defaultTextColor;
    _segments =
        widget.prompt?.segments.map((s) => s.copyWith()).toList() ??
        [PromptSegment(text: '', colorValue: _defaultTextColor)];
    _imagePaths = List<String>.from(widget.prompt?.imagePaths ?? []);
  }

  Future<void> _pickImages() async {
    triggerInteractionHaptic(widget.settings);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final appDataDir = Platform.environment['APPDATA'];
        final imagesDir = Directory('$appDataDir/Flow/images');
        if (!imagesDir.existsSync()) {
          imagesDir.createSync(recursive: true);
        }

        final List<String> copiedPaths = [];
        for (final file in result.files) {
          if (file.path != null) {
            final originalFile = File(file.path!);
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final targetFile = File('${imagesDir.path}/$fileName');
            await originalFile.copy(targetFile.path);
            copiedPaths.add(targetFile.path);
          }
        }

        setState(() {
          _imagePaths.addAll(copiedPaths);
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    triggerInteractionHaptic(widget.settings);
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _save() {
    triggerInteractionHaptic(widget.settings);
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final now = DateTime.now();

    widget.onSave(
      PromptItem(
        id: widget.prompt?.id ?? PromptStore.newId(),
        title: title,
        titleColorValue: _titleColorValue,
        folderId: _selectedFolderId,
        tags: tags,
        createdAt: widget.prompt?.createdAt ?? now,
        updatedAt: now,
        segments: _segments,
        imagePaths: _imagePaths,
      ),
    );
  }

  Future<void> _pickMoreColors(int segmentIdx) async {
    final seg = _segments[segmentIdx];
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => ColorPickerDialog(
        initialColor: Color(seg.colorValue),
        presets: _presetColors,
        settings: widget.settings,
        favoriteColors: widget.favoriteColors,
        onToggleFavorite: widget.onToggleFavorite,
      ),
    );

    if (color != null) {
      setState(() {
        _segments[segmentIdx] = _segments[segmentIdx].copyWith(
          colorValue: color.value,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragOver = true),
      onDragExited: (details) => setState(() => _isDragOver = false),
      onDragDone: (details) async {
        setState(() => _isDragOver = false);
        final files = details.files;
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff'];
        final appDataDir = Platform.environment['APPDATA'];
        final imagesDir = Directory('$appDataDir/Flow/images');
        if (!imagesDir.existsSync()) {
          imagesDir.createSync(recursive: true);
        }

        final List<String> copiedPaths = [];
        for (final file in files) {
          final ext = file.name.split('.').last.toLowerCase();
          if (allowedExtensions.contains(ext)) {
            final originalFile = File(file.path);
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final targetFile = File('${imagesDir.path}/$fileName');
            await originalFile.copy(targetFile.path);
            copiedPaths.add(targetFile.path);
          }
        }

        if (copiedPaths.isNotEmpty) {
          setState(() {
            _imagePaths.addAll(copiedPaths);
          });
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                widget.prompt == null ? '프롬프트 만들기' : '프롬프트 편집',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  triggerInteractionHaptic(widget.settings);
                  widget.onClose();
                },
                tooltip: '닫기',
              ),
              actions: [
                FilledButton(
                  onPressed: _save,
                  child: const Text('저장'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedFolderId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(
                          '폴더 없음',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...widget.folders.map(
                        (folder) => DropdownMenuItem(
                          value: folder.id,
                          child: Text(
                            folder.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedFolderId = v ?? ''),
                    decoration: const InputDecoration(labelText: '폴더'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: '태그 (쉼표로 구분)'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '이미지 첨부',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        tooltip: '이미지 추가',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, idx) {
                          final path = _imagePaths[idx];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 90,
                            height: 90,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white12
                                            : Colors.black12,
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.file(
                                      File(path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image, size: 30));
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.black12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '첨부된 이미지가 없습니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '프롬프트 내용',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          triggerInteractionHaptic(widget.settings);
                          setState(
                            () => _segments.add(
                              PromptSegment(
                                text: '',
                                      colorValue: _currentDefaultTextColor,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  ..._segments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final seg = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ColorDot(
                                    colorValue: seg.colorValue,
                                    isSelected: true,
                                    onTap: () {
                                      triggerInteractionHaptic(widget.settings);
                                      _pickMoreColors(idx);
                                    },
                                  ),
                                  if (widget.favoriteColors.isNotEmpty) ...[
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey.withOpacity(0.3),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    ...widget.favoriteColors.map(
                                      (colorValue) => _ColorDot(
                                        colorValue: colorValue,
                                        isSelected: seg.colorValue == colorValue,
                                        onTap: () {
                                          triggerInteractionHaptic(widget.settings);
                                          setState(
                                            () => _segments[idx] = seg.copyWith(
                                              colorValue: colorValue,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(
                                      Icons.palette_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      triggerInteractionHaptic(widget.settings);
                                      _pickMoreColors(idx);
                                    },
                                    tooltip: '다른 색상 선택',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      widget.favoriteColors.contains(seg.colorValue)
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 20,
                                      color:
                                          widget.favoriteColors.contains(
                                            seg.colorValue,
                                          )
                                          ? Colors.amber
                                          : null,
                                    ),
                                    onPressed: () {
                                      triggerInteractionHaptic(widget.settings);
                                      widget.onToggleFavorite(seg.colorValue);
                                      setState(() {});
                                    },
                                    tooltip: '즐겨찾기 추가',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      triggerInteractionHaptic(widget.settings);
                                      setState(() {
                                        if (_segments.length > 1) {
                                          _segments.removeAt(idx);
                                        }
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    tooltip: '삭제',
                                  ),
                                ],
                              ),
                            ),
                            TextFormField(
                              initialValue: seg.text,
                              maxLines: null,
                              onChanged: (v) =>
                                  _segments[idx] = _segments[idx].copyWith(text: v),
                              decoration: const InputDecoration(
                                hintText: '여기에 내용을 입력하세요...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (_isDragOver)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black87
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text(
                          '여기에 이미지를 놓아 드롭 첨부',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatefulWidget {
  const _ColorDot({
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ColorDot> createState() => _ColorDotState();
}

class _ColorDotState extends State<_ColorDot> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final dotColor = Color(widget.colorValue);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 10),
            width: 32,
            height: 32,
            transform: Matrix4.identity()..scale((_isHovered || _isFocused) ? 1.15 : 1.0),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (_isFocused || _isHovered
                        ? primaryColor.withOpacity(0.8)
                        : Colors.white.withOpacity(0.2)),
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (isSelected || _isHovered || _isFocused)
                  BoxShadow(
                    color: dotColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1.5,
                  ),
              ],
            ),
            child: isSelected
                ? Center(
                    child: Icon(
                      Icons.check,
                      color: ThemeData.estimateBrightnessForColor(dotColor) == Brightness.light
                          ? Colors.black87
                          : Colors.white,
                      size: 16,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    super.key,
    required this.presets,
    required this.settings,
    this.initialColor,
    required this.favoriteColors,
    required this.onToggleFavorite,
  });

  final List<Color> presets;
  final AppSettings settings;
  final Color? initialColor;
  final List<int> favoriteColors;
  final ValueChanged<int> onToggleFavorite;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();

  final FocusNode _spectrumFocusNode = FocusNode();
  final FocusNode _sliderFocusNode = FocusNode();

  late double _hue; // 0.0 to 360.0
  late double _saturation; // 0.0 to 1.0
  late double _value; // 0.0 to 1.0

  String _colorFormat = 'RGB'; // 'RGB', 'HSV', 'HSL'

  late List<int> _favoriteColors;
  late int _selectedCustomSlotIndex;

  bool _updatingFields = false;

  // Basic colors (48 colors matching the image)
  static const List<Color> _basicColors = [
    // Row 1
    Color(0xFFFF8A8A), Color(0xFFE52E2E), Color(0xFFB33A3A), Color(0xFF8B0000), Color(0xFF5A0000),
    Color(0xFFAEF3F9), Color(0xFF6AE3F0), Color(0xFF3D9CF5), Color(0xFF0F4CFC), Color(0xFF0A2C9E), Color(0xFF1F3D7A), Color(0xFF0A0F5A),
    // Row 2
    Color(0xFFFFFFA6), Color(0xFFECEC13), Color(0xFFFFB366), Color(0xFFE68033), Color(0xFF8B5A2B), Color(0xFF8B8B2F),
    Color(0xFF9999FF), Color(0xFF6B4CFF), Color(0xFF4CA6FF), Color(0xFF0A0F3D), Color(0xFF5A0A5A), Color(0xFF3D0A3D),
    // Row 3
    Color(0xFFB3FFB3), Color(0xFF66FF66), Color(0xFF33CC33), Color(0xFF009933), Color(0xFF006622), Color(0xFF8B8B5F),
    Color(0xFFFFB3D9), Color(0xFFFF80DF), Color(0xFFFF4DFF), Color(0xFFFF007F), Color(0xFF8A8AB3), Color(0xFF8B1A4F),
    // Row 4
    Color(0xFF1E4D1E), Color(0xFF0F3A0F), Color(0xFF1A3F3F), Color(0xFF2E5E5E), Color(0xFF152A2A), Color(0xFF4A707A),
    Color(0xFF5A005A), Color(0xFF3D003D), Color(0xFF000000), Color(0xFF555555), Color(0xFFAAAAAA), Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialColor ?? const Color(0xFF183153);
    final hsv = HSVColor.fromColor(initial);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;

    _favoriteColors = List<int>.from(widget.favoriteColors);
    _selectedCustomSlotIndex = 0;
    // Set initial selected slot to the first empty slot or 0
    for (int i = 0; i < 24; i++) {
      if (i >= _favoriteColors.length) {
        _selectedCustomSlotIndex = i;
        break;
      }
    }

    _hexController.addListener(_onHexChanged);
    _field1Controller.addListener(_onNumericFieldChanged);
    _field2Controller.addListener(_onNumericFieldChanged);
    _field3Controller.addListener(_onNumericFieldChanged);

    _spectrumFocusNode.addListener(() => setState(() {}));
    _sliderFocusNode.addListener(() => setState(() {}));

    _updateTextControllers();
  }

  @override
  void dispose() {
    _hexController.removeListener(_onHexChanged);
    _field1Controller.removeListener(_onNumericFieldChanged);
    _field2Controller.removeListener(_onNumericFieldChanged);
    _field3Controller.removeListener(_onNumericFieldChanged);

    _hexController.dispose();
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();

    _spectrumFocusNode.dispose();
    _sliderFocusNode.dispose();
    super.dispose();
  }

  void _onHexChanged() {
    if (_updatingFields) return;
    final text = _hexController.text.trim().replaceAll('#', '');
    if (text.length == 6) {
      final parsed = int.tryParse(text, radix: 16);
      if (parsed != null) {
        final color = Color(0xFF000000 | parsed);
        final hsv = HSVColor.fromColor(color);
        setState(() {
          _hue = hsv.hue;
          _saturation = hsv.saturation;
          _value = hsv.value;
          _updateTextControllers(excludeHex: true);
        });
      }
    }
  }

  void _onNumericFieldChanged() {
    if (_updatingFields) return;
    final String val1 = _field1Controller.text.trim();
    final String val2 = _field2Controller.text.trim();
    final String val3 = _field3Controller.text.trim();

    final double? num1 = double.tryParse(val1);
    final double? num2 = double.tryParse(val2);
    final double? num3 = double.tryParse(val3);

    if (num1 == null || num2 == null || num3 == null) return;

    if (_colorFormat == 'RGB') {
      final r = num1.clamp(0.0, 255.0).toInt();
      final g = num2.clamp(0.0, 255.0).toInt();
      final b = num3.clamp(0.0, 255.0).toInt();
      final color = Color.fromARGB(255, r, g, b);
      final hsv = HSVColor.fromColor(color);
      setState(() {
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
        _updateTextControllers(excludeNumeric: true);
      });
    } else if (_colorFormat == 'HSV') {
      final h = num1.clamp(0.0, 360.0);
      final s = num2.clamp(0.0, 100.0) / 100.0;
      final v = num3.clamp(0.0, 100.0) / 100.0;
      setState(() {
        _hue = h;
        _saturation = s;
        _value = v;
        _updateTextControllers(excludeNumeric: true);
      });
    } else if (_colorFormat == 'HSL') {
      final h = num1.clamp(0.0, 360.0);
      final s = num2.clamp(0.0, 100.0) / 100.0;
      final l = num3.clamp(0.0, 100.0) / 100.0;
      // Convert HSL to HSV
      final double v = l + s * math.min(l, 1.0 - l);
      final double sv = (v == 0.0) ? 0.0 : 2.0 * (1.0 - l / v);
      setState(() {
        _hue = h;
        _saturation = sv;
        _value = v;
        _updateTextControllers(excludeNumeric: true);
      });
    }
  }

  void _updateTextControllers({
    bool excludeHex = false,
    bool excludeNumeric = false,
  }) {
    if (_updatingFields) return;
    _updatingFields = true;

    final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

    if (!excludeHex) {
      final rStr = activeColor.red.toRadixString(16).padLeft(2, '0');
      final gStr = activeColor.green.toRadixString(16).padLeft(2, '0');
      final bStr = activeColor.blue.toRadixString(16).padLeft(2, '0');
      _hexController.text = '#${rStr}${gStr}${bStr}'.toUpperCase();
    }

    if (!excludeNumeric) {
      if (_colorFormat == 'RGB') {
        _field1Controller.text = activeColor.red.toString();
        _field2Controller.text = activeColor.green.toString();
        _field3Controller.text = activeColor.blue.toString();
      } else if (_colorFormat == 'HSV') {
        _field1Controller.text = _hue.round().toString();
        _field2Controller.text = (_saturation * 100).round().toString();
        _field3Controller.text = (_value * 100).round().toString();
      } else if (_colorFormat == 'HSL') {
        // Convert HSV to HSL
        final double l = _value * (1.0 - _saturation / 2.0);
        final double s = (l == 0.0 || l == 1.0)
            ? 0.0
            : (_value - l) / math.min(l, 1.0 - l);
        _field1Controller.text = _hue.round().toString();
        _field2Controller.text = (s * 100).round().toString();
        _field3Controller.text = (l * 100).round().toString();
      }
    }

    _updatingFields = false;
  }

  void _handleSpectrumDrag(Offset localPosition, Size size) {
    final double dx = localPosition.dx.clamp(0.0, size.width);
    final double dy = localPosition.dy.clamp(0.0, size.height);

    final double hue = (dx / size.width) * 360.0;
    final double saturation = 1.0 - (dy / size.height);

    setState(() {
      _hue = hue;
      _saturation = saturation;
      _updateTextControllers();
    });
  }

  void _handleSliderDrag(Offset localPosition, Size size) {
    final double dy = localPosition.dy.clamp(0.0, size.height);
    final double value = 1.0 - (dy / size.height);

    setState(() {
      _value = value;
      _updateTextControllers();
    });
  }

  KeyEventResult _handleSpectrumKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final double hueStep = isShiftPressed ? 15.0 : 5.0;
    final double satStep = isShiftPressed ? 0.10 : 0.02;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _hue = (_hue - hueStep).clamp(0.0, 360.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _hue = (_hue + hueStep).clamp(0.0, 360.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _saturation = (_saturation + satStep).clamp(0.0, 1.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _saturation = (_saturation - satStep).clamp(0.0, 1.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSliderKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final double valStep = isShiftPressed ? 0.10 : 0.02;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _value = (_value + valStep).clamp(0.0, 1.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _value = (_value - valStep).clamp(0.0, 1.0);
        _updateTextControllers();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _addCurrentColorToCustom() {
    final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    final colorVal = activeColor.value;

    setState(() {
      if (_selectedCustomSlotIndex < _favoriteColors.length) {
        _favoriteColors[_selectedCustomSlotIndex] = colorVal;
      } else {
        while (_favoriteColors.length < _selectedCustomSlotIndex) {
          _favoriteColors.add(0xFF000000);
        }
        _favoriteColors.add(colorVal);
      }

      if (!widget.favoriteColors.contains(colorVal)) {
        widget.onToggleFavorite(colorVal);
      }
    });
  }

  List<String> get _numericLabels {
    if (_colorFormat == 'RGB') {
      return ['빨강', '녹색', '파랑'];
    } else if (_colorFormat == 'HSV') {
      return ['색상', '채도', '명도'];
    } else {
      return ['색상', '채도', '밝기'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final dialogBg = theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;
    final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          triggerInteractionHaptic(widget.settings);
          final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
          Navigator.pop(context, activeColor);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          triggerInteractionHaptic(widget.settings);
          Navigator.pop(context);
        },
      },
      child: FocusScope(
        autofocus: true,
        child: Dialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          child: Container(
            width: 660,
            height: 530,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Close Button
                Row(
                  children: [
                    Text(
                      '색 편집',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: onSurface.withOpacity(0.7)),
                      onPressed: () {
                        triggerInteractionHaptic(widget.settings);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Upper Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spectrum Picker
                    Focus(
                      focusNode: _spectrumFocusNode,
                      onKeyEvent: (node, event) => _handleSpectrumKeyEvent(event),
                      child: Container(
                        width: 240,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _spectrumFocusNode.hasFocus
                                ? theme.colorScheme.primary
                                : borderColor,
                            width: _spectrumFocusNode.hasFocus ? 2.5 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onPanUpdate: (details) => _handleSpectrumDrag(details.localPosition, size),
                              onPanDown: (details) => _handleSpectrumDrag(details.localPosition, size),
                              child: CustomPaint(
                                painter: const HueSaturationPainter(),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: (_hue / 360.0) * size.width - 8,
                                      top: (1.0 - _saturation) * size.height - 8,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Solid Color Preview
                    Container(
                      width: 48,
                      height: 220,
                      decoration: BoxDecoration(
                        color: HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black26,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Brightness Slider
                    Focus(
                      focusNode: _sliderFocusNode,
                      onKeyEvent: (node, event) => _handleSliderKeyEvent(event),
                      child: Container(
                        width: 18,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _sliderFocusNode.hasFocus
                                ? theme.colorScheme.primary
                                : borderColor,
                            width: _sliderFocusNode.hasFocus ? 2.5 : 1.0,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onPanUpdate: (details) => _handleSliderDrag(details.localPosition, size),
                              onPanDown: (details) => _handleSliderDrag(details.localPosition, size),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                                          Colors.black,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: size.width / 2 - 8,
                                    top: (1.0 - _value) * size.height - 8,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black54),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Input Fields Panel
                    Expanded(
                      child: SizedBox(
                        height: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEX Input
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _hexController,
                                      style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        fillColor: fieldBg,
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        prefixIcon: Icon(Icons.tag_rounded, color: onSurface.withOpacity(0.5), size: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Format Dropdown
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: DropdownButtonFormField<String>(
                                      value: _colorFormat,
                                      dropdownColor: dialogBg,
                                      style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        fillColor: fieldBg,
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(value: 'RGB', child: Text('RGB', style: TextStyle(color: onSurface))),
                                        DropdownMenuItem(value: 'HSV', child: Text('HSV', style: TextStyle(color: onSurface))),
                                        DropdownMenuItem(value: 'HSL', child: Text('HSL', style: TextStyle(color: onSurface))),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() {
                                            _colorFormat = v;
                                            _updateTextControllers();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Numeric Inputs
                            ...List.generate(3, (idx) {
                              final label = _numericLabels[idx];
                              final controller = idx == 0
                                  ? _field1Controller
                                  : (idx == 1 ? _field2Controller : _field3Controller);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: TextField(
                                          controller: controller,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                                          decoration: InputDecoration(
                                            fillColor: fieldBg,
                                            filled: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            prefixIcon: Padding(
                                              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                                              child: Center(
                                                widthFactor: 1.0,
                                                child: Text(
                                                  label,
                                                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: borderColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: borderColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lower Section: Grids and Comparison
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Colors Grid
                      Expanded(
                        flex: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '기본 색',
                              style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 12,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                ),
                                itemCount: _basicColors.length,
                                itemBuilder: (context, index) {
                                  final color = _basicColors[index];
                                  final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
                                  final isSelected = activeColor.value == color.value;
                                  return BasicColorCircle(
                                    color: color,
                                    isSelected: isSelected,
                                    onTap: () {
                                      triggerInteractionHaptic(widget.settings);
                                      final hsv = HSVColor.fromColor(color);
                                      setState(() {
                                        _hue = hsv.hue;
                                        _saturation = hsv.saturation;
                                        _value = hsv.value;
                                        _updateTextControllers();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Custom Colors Grid
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '사용자 지정 색',
                                  style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: _addCurrentColorToCustom,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: onSurface,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                ),
                                itemCount: 24,
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedCustomSlotIndex;
                                  final isEmpty = index >= _favoriteColors.length;
                                  final color = isEmpty ? Colors.transparent : Color(_favoriteColors[index]);
                                  return CustomColorCircle(
                                    color: color,
                                    isSelected: isSelected,
                                    isEmpty: isEmpty,
                                    onTap: () {
                                      triggerInteractionHaptic(widget.settings);
                                      setState(() {
                                        _selectedCustomSlotIndex = index;
                                        if (!isEmpty) {
                                          final hsv = HSVColor.fromColor(color);
                                          _hue = hsv.hue;
                                          _saturation = hsv.saturation;
                                          _value = hsv.value;
                                          _updateTextControllers();
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        triggerInteractionHaptic(widget.settings);
                        Navigator.pop(context);
                      },
                      child: Text('취소', style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        triggerInteractionHaptic(widget.settings);
                        final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
                        Navigator.pop(context, activeColor);
                      },
                      child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- Custom Painters and Helper Widgets -----------------

class HueSaturationPainter extends CustomPainter {
  const HueSaturationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Hue gradient
    final huePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, huePaint);

    // Saturation gradient
    final satPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white,
          Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, satPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  const DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double dashLength = 3;
    const double gapLength = 3;
    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashLength + gapLength)) / radius;
      final double sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}

class CustomColorCircle extends StatefulWidget {
  const CustomColorCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.isEmpty,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final bool isEmpty;
  final VoidCallback onTap;

  @override
  State<CustomColorCircle> createState() => _CustomColorCircleState();
}

class _CustomColorCircleState extends State<CustomColorCircle> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child;
    if (widget.isEmpty) {
      child = CustomPaint(
        size: const Size(18, 18),
        painter: DashedCirclePainter(color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3)),
      );
    } else {
      final bool isWhiteOrVeryBright = widget.color.red > 220 && widget.color.green > 220 && widget.color.blue > 220;
      child = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isWhiteOrVeryBright
                ? Colors.black38
                : (isDark ? Colors.white24 : Colors.black26),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
      );
    }

    final display = widget.isSelected
        ? SizedBox(
            width: 26,
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(24, 24),
                  painter: DashedCirclePainter(color: isDark ? Colors.white70 : Colors.black54),
                ),
                child,
              ],
            ),
          )
        : SizedBox(
            width: 26,
            height: 26,
            child: Center(child: child),
          );

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()..scale((_isHovered || _isFocused) ? 1.25 : 1.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isFocused
                    ? theme.colorScheme.primary
                    : ((_isHovered && !widget.isEmpty)
                        ? (isDark ? Colors.white54 : Colors.black54)
                        : Colors.transparent),
                width: 2,
              ),
            ),
            child: display,
          ),
        ),
      ),
    );
  }
}

class BasicColorCircle extends StatefulWidget {
  const BasicColorCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<BasicColorCircle> createState() => _BasicColorCircleState();
}

class _BasicColorCircleState extends State<BasicColorCircle> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isWhiteOrVeryBright = widget.color.red > 220 && widget.color.green > 220 && widget.color.blue > 220;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(2.5),
            transform: Matrix4.identity()..scale((_isHovered || _isFocused) ? 1.25 : 1.0),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (_isFocused || _isHovered
                        ? theme.colorScheme.primary
                        : (isWhiteOrVeryBright ? Colors.black38 : (isDark ? Colors.white24 : Colors.black26))),
                width: widget.isSelected ? 2.5 : (_isFocused || _isHovered ? 2.0 : 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                if (widget.isSelected || _isHovered || _isFocused)
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onToggleTheme,
    required this.onToggleLock,
    required this.onChangePin,
    required this.onLockNow,
    required this.onBackup,
    required this.onRestore,
    required this.onToggleHaptic,
    required this.onToggleFolderNavigation,
    required this.onOpenShortcuts,
  });

  final AppSettings settings;
  final ValueChanged<bool> onToggleTheme;
  final ValueChanged<bool> onToggleLock;
  final VoidCallback onChangePin;
  final VoidCallback onLockNow;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final ValueChanged<bool> onToggleHaptic;
  final ValueChanged<bool> onToggleFolderNavigation;
  final VoidCallback onOpenShortcuts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('다크 모드'),
            value: settings.darkMode,
            onChanged: onToggleTheme,
          ),
          SwitchListTile(
            title: const Text('터치 진동'),
            value: settings.hapticEnabled,
            onChanged: onToggleHaptic,
          ),
          SwitchListTile(
            title: const Text('빠른 폴더 이동 표시'),
            value: settings.showFolderNavigation,
            onChanged: onToggleFolderNavigation,
          ),
          SwitchListTile(
            title: const Text('앱 잠금'),
            value: settings.lockEnabled,
            onChanged: onToggleLock,
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('PIN 변경'),
            onTap: onChangePin,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('지금 잠금'),
            onTap: onLockNow,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('백업 저장'),
            onTap: onBackup,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('백업 불러오기'),
            onTap: onRestore,
          ),
          ListTile(
            leading: const Icon(Icons.keyboard_alt_outlined),
            title: const Text('단축키 설정'),
            subtitle: const Text('앱 기능의 키보드 단축키를 변경합니다'),
            onTap: onOpenShortcuts,
          ),
        ],
      ),
    );
  }
}

class ShortcutSettingsDialog extends StatefulWidget {
  const ShortcutSettingsDialog({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<ShortcutSettingsDialog> createState() => _ShortcutSettingsDialogState();
}

class _ShortcutSettingsDialogState extends State<ShortcutSettingsDialog> {
  late Map<String, AppShortcut> _shortcuts;

  @override
  void initState() {
    super.initState();
    _shortcuts = {
      for (final action in AppShortcutAction.values)
        action.id: widget.settings.shortcuts[action.id] ??
            AppShortcut.fromAction(action),
    };
  }

  AppShortcut _shortcutFor(AppShortcutAction action) {
    return _shortcuts[action.id] ?? AppShortcut.fromAction(action);
  }

  void _updateShortcut(AppShortcutAction action, AppShortcut shortcut) {
    setState(() {
      _shortcuts[action.id] = shortcut;
    });
    widget.onChanged(widget.settings.copyWith(shortcuts: Map.from(_shortcuts)));
  }

  Future<void> _editShortcut(AppShortcutAction action) async {
    final shortcut = await showDialog<AppShortcut>(
      context: context,
      builder: (context) => _ShortcutCaptureDialog(
        action: action,
        current: _shortcutFor(action),
      ),
    );
    if (!mounted || shortcut == null) return;

    final conflict = AppShortcutAction.values.where((other) {
      return other != action && _shortcutFor(other) == shortcut;
    }).firstOrNull;
    if (conflict != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('단축키가 이미 사용 중입니다'),
          content: Text('${conflict.title} 기능이 같은 단축키를 사용하고 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    _updateShortcut(action, shortcut);
  }

  String _shortcutLabel(AppShortcut shortcut) {
    final modifiers = <String>[];
    if (shortcut.control) modifiers.add('Ctrl');
    if (shortcut.meta) modifiers.add('⌘');
    if (shortcut.alt) modifiers.add('Alt');
    if (shortcut.shift) modifiers.add('Shift');
    if (shortcut.key == LogicalKeyboardKey.escape) {
      return [...modifiers, 'Esc'].join(' + ');
    }
    var keyLabel = shortcut.key.keyLabel;
    if (keyLabel.trim().isEmpty) keyLabel = shortcut.key.debugName ?? 'Key';
    return [...modifiers, keyLabel.toUpperCase()].join(' + ');
  }

  IconData _shortcutIcon(AppShortcutAction action) {
    switch (action) {
      case AppShortcutAction.newPrompt:
        return Icons.add_box_outlined;
      case AppShortcutAction.search:
        return Icons.search_rounded;
      case AppShortcutAction.settings:
        return Icons.settings_outlined;
      case AppShortcutAction.lock:
        return Icons.lock_outline_rounded;
      case AppShortcutAction.closeSearch:
        return Icons.keyboard_return_rounded;
      case AppShortcutAction.editPrompt:
        return Icons.edit_outlined;
      case AppShortcutAction.copyPrompt:
        return Icons.copy_outlined;
      case AppShortcutAction.deletePrompt:
        return Icons.delete_outline_rounded;
      case AppShortcutAction.duplicatePrompt:
        return Icons.control_point_duplicate_outlined;
      case AppShortcutAction.togglePin:
        return Icons.push_pin_outlined;
      case AppShortcutAction.promptActions:
        return Icons.more_horiz_rounded;
    }
  }

  void _resetDefaults() {
    setState(() {
      _shortcuts = {
        for (final action in AppShortcutAction.values)
          action.id: AppShortcut.fromAction(action),
      };
    });
    widget.onChanged(widget.settings.copyWith(shortcuts: Map.from(_shortcuts)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('단축키 설정'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '기능을 선택한 뒤 원하는 키 조합을 누르세요.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...AppShortcutAction.values.map((action) {
                final shortcut = _shortcutFor(action);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    leading: Icon(_shortcutIcon(action), color: colorScheme.primary),
                    title: Text(action.title),
                    subtitle: Text(action.description),
                    trailing: OutlinedButton(
                      onPressed: () => _editShortcut(action),
                      child: Text(_shortcutLabel(shortcut)),
                    ),
                    onTap: () => _editShortcut(action),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _resetDefaults,
          icon: const Icon(Icons.restore_rounded),
          label: const Text('기본값 복원'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('완료'),
        ),
      ],
    );
  }
}

class _ShortcutCaptureDialog extends StatefulWidget {
  const _ShortcutCaptureDialog({
    required this.action,
    required this.current,
  });

  final AppShortcutAction action;
  final AppShortcut current;

  @override
  State<_ShortcutCaptureDialog> createState() => _ShortcutCaptureDialogState();
}

class _ShortcutCaptureDialogState extends State<_ShortcutCaptureDialog> {
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final key = event.logicalKey;
    final isModifier = key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
    if (isModifier) return KeyEventResult.handled;

    final keyboard = HardwareKeyboard.instance;
    Navigator.pop(
      context,
      AppShortcut(
        key: key,
        control: keyboard.isControlPressed,
        alt: keyboard.isAltPressed,
        shift: keyboard.isShiftPressed,
        meta: keyboard.isMetaPressed,
      ),
    );
    return KeyEventResult.handled;
  }

  String _currentLabel() {
    final modifiers = <String>[];
    if (widget.current.control) modifiers.add('Ctrl');
    if (widget.current.meta) modifiers.add('⌘');
    if (widget.current.alt) modifiers.add('Alt');
    if (widget.current.shift) modifiers.add('Shift');
    if (widget.current.key == LogicalKeyboardKey.escape) {
      return [...modifiers, 'Esc'].join(' + ');
    }
    var keyLabel = widget.current.key.keyLabel;
    if (keyLabel.trim().isEmpty) {
      keyLabel = widget.current.key.debugName ?? 'Key';
    }
    return [...modifiers, keyLabel.toUpperCase()].join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action.title} 단축키 변경'),
      content: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_rounded, size: 36),
              const SizedBox(height: 12),
              const Text('원하는 키 조합을 누르세요'),
              const SizedBox(height: 8),
              Text(
                '현재: ${_currentLabel()}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class FolderCard extends StatefulWidget {
  const FolderCard({
    super.key,
    required this.name,
    required this.promptCount,
    this.icon = Icons.folder_rounded,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int promptCount;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.isSelected;
    final cardColor = isActive
        ? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.09)
        : (isDark
              ? Colors.white.withValues(alpha: 0.045)
              : Colors.white.withValues(alpha: 0.78));
    final borderColor = isActive
        ? scheme.primary.withValues(alpha: isDark ? 0.8 : 0.62)
        : scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.55);
    final iconBackground = isActive
        ? scheme.primary
        : scheme.primary.withValues(alpha: isDark ? 0.18 : 0.11);
    final iconColor = isActive ? scheme.onPrimary : scheme.primary;
    final labelColor = scheme.onSurface;
    final countColor = scheme.onSurfaceVariant;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Semantics(
            button: true,
            label: '${widget.name}, ${widget.promptCount}개 프롬프트',
            selected: isActive,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 154,
              height: 76,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused ? scheme.primary : borderColor,
                  width: _isFocused ? 2 : (isActive ? 1.5 : 1),
                ),
                boxShadow: (_isHovered || isActive)
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          blurRadius: isActive ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(widget.icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${widget.promptCount}개 프롬프트',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: countColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  void _onKeyPress(String val) {
    if (!enabled) return;
    if (controller.text.length < 4) {
      controller.text += val;
    }
  }

  void _onBackspace() {
    if (!enabled) return;
    if (controller.text.isNotEmpty) {
      controller.text = controller.text.substring(0, controller.text.length - 1);
    }
  }

  void _onClear() {
    if (!enabled) return;
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '1',
                    onTap: () => _onKeyPress('1'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '2',
                    onTap: () => _onKeyPress('2'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '3',
                    onTap: () => _onKeyPress('3'),
                    enabled: enabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '4',
                    onTap: () => _onKeyPress('4'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '5',
                    onTap: () => _onKeyPress('5'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '6',
                    onTap: () => _onKeyPress('6'),
                    enabled: enabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '7',
                    onTap: () => _onKeyPress('7'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '8',
                    onTap: () => _onKeyPress('8'),
                    enabled: enabled,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '9',
                    onTap: () => _onKeyPress('9'),
                    enabled: enabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: 'C',
                    onTap: _onClear,
                    enabled: enabled,
                    isSecondary: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    label: '0',
                    onTap: () => _onKeyPress('0'),
                    enabled: enabled,
                    isSecondary: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _PinButton(
                    icon: Icons.backspace_outlined,
                    onTap: _onBackspace,
                    enabled: enabled,
                    isSecondary: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinButton extends StatefulWidget {
  const _PinButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.enabled,
    this.isSecondary = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isSecondary;

  @override
  State<_PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<_PinButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    if (widget.isSecondary) {
      bgColor = Colors.transparent;
    } else {
      bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    }

    Color fgColor = isDark ? Colors.white : Colors.black;
    if (widget.isSecondary) {
      fgColor = isDark ? Colors.white60 : Colors.black54;
    }

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          if (widget.enabled) widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()..scale((_isHovered || _isFocused) && widget.enabled ? 1.08 : 1.0),
            decoration: BoxDecoration(
              color: (_isHovered || _isFocused) && widget.enabled
                  ? (widget.isSecondary
                      ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
                      : scheme.primary.withOpacity(0.15))
                  : bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: (_isFocused && widget.enabled)
                    ? scheme.primary
                    : ((_isHovered && widget.enabled)
                        ? scheme.primary.withOpacity(0.5)
                        : Colors.transparent),
                width: 2,
              ),
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(widget.icon, color: fgColor, size: 20)
                  : Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({required this.imagePaths});
  final List<String> imagePaths;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Photo viewer
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(
                      File(widget.imagePaths[index]),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48, color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ),

          // Upper Controls (Close & Index)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.imagePaths.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Left Arrow
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          // Right Arrow
          if (_currentIndex < widget.imagePaths.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
