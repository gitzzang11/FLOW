import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  });

  final List<FolderItem> folders;
  final List<PromptItem> prompts;
  final String selectedFolderId;
  final ValueChanged<String> onSelectFolder;
  final VoidCallback onCreateFolder;
  final ValueChanged<FolderItem> onEditFolder;
  final ValueChanged<FolderItem> onDeleteFolder;

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
                settings:
                    const AppSettings(), // Dummy/placeholder or just ignore since we don't trigger haptic here (handled in callbacks)
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: folders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final count = prompts
                        .where((p) => p.folderId == folder.id)
                        .length;
                    return _FolderTile(
                      label: folder.name,
                      count: count,
                      selected: selectedFolderId == folder.id,
                      onTap: () => onSelectFolder(folder.id),
                      settings: const AppSettings(),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        tooltip: '폴더 설정',
                        onSelected: (value) {
                          if (value == 'edit') onEditFolder(folder);
                          if (value == 'delete') onDeleteFolder(folder);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('이름 변경')),
                          PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
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

class _FolderTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final nameColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7));

    final countColor = selected
        ? (isDark
              ? Colors.white.withOpacity(0.6)
              : Colors.black.withOpacity(0.5))
        : (isDark
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.4));

    final iconColor = selected
        ? scheme.primary
        : (isDark
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.4));

    final tileBg = selected
        ? (isDark
              ? Colors.white.withOpacity(0.08)
              : scheme.primary.withOpacity(0.08))
        : Colors.transparent;

    final border = Border.all(
      color: selected
          ? (isDark
                ? Colors.white.withOpacity(0.1)
                : scheme.primary.withOpacity(0.15))
          : Colors.transparent,
      width: 1.5,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
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
                selected ? Icons.folder_open_rounded : Icons.folder_rounded,
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
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: nameColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '프롬프트 $count개',
                      style: TextStyle(color: countColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
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
                  child: trailing!,
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

class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    this.isGrid = false,
    required this.folderName,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onTogglePin,
  });

  final PromptItem prompt;
  final String folderName;
  final bool isGrid;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onTogglePin;

  bool _isLocked() {
    final titleLower = prompt.title.toLowerCase();
    if (titleLower.contains('잠금') || titleLower.contains('잠긴')) {
      return true;
    }
    if (prompt.tags.any((tag) {
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
                  prompt.title,
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
                  onCopy();
                },
              ),
              ListTile(
                leading: Icon(
                  prompt.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  prompt.isPinned ? '고정 해제' : '상단 고정',
                  style: textStyle,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onTogglePin();
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
                  onEdit();
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
                  onDuplicate();
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
                  onDelete();
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCopy,
        onDoubleTap: onEdit,
        onLongPress: () => _showActionSheet(context),
        onSecondaryTapUp: (_) => _showActionSheet(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: prompt.isPinned
                            ? const EdgeInsets.only(right: 20)
                            : EdgeInsets.zero,
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
                                    children: prompt.segments
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
                    ),
                    if (prompt.isPinned)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                prompt.title,
                style: titleStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMonthDay(prompt.updatedAt),
              style: dateStyle,
              textAlign: TextAlign.center,
            ),
          ],
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

class PromptEditorDialog extends StatefulWidget {
  const PromptEditorDialog({
    super.key,
    required this.folders,
    this.prompt,
    this.initialFolderId = '',
    required this.favoriteColors,
    required this.onToggleFavorite,
    required this.settings,
  });

  final List<FolderItem> folders;
  final PromptItem? prompt;
  final String initialFolderId;
  final List<int> favoriteColors;
  final ValueChanged<int> onToggleFavorite;
  final AppSettings settings;

  @override
  State<PromptEditorDialog> createState() => _PromptEditorDialogState();
}

class _PromptEditorDialogState extends State<PromptEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late String _selectedFolderId;
  late int _titleColorValue;
  late List<PromptSegment> _segments;

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
    _titleController = TextEditingController(text: widget.prompt?.title ?? '');
    _tagsController = TextEditingController(
      text: widget.prompt?.tags.join(', ') ?? '',
    );
    _selectedFolderId = widget.prompt?.folderId ?? widget.initialFolderId;
    _titleColorValue = widget.prompt?.titleColorValue ?? AppPalette.ink.value;
    _segments =
        widget.prompt?.segments.map((s) => s.copyWith()).toList() ??
        [PromptSegment(text: '', colorValue: AppPalette.ink.value)];
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

    Navigator.pop(
      context,
      PromptItem(
        id: widget.prompt?.id ?? PromptStore.newId(),
        title: title,
        titleColorValue: _titleColorValue,
        folderId: _selectedFolderId,
        tags: tags,
        createdAt: widget.prompt?.createdAt ?? now,
        updatedAt: now,
        segments: _segments,
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
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.prompt == null ? '프롬프트 만들기' : '프롬프트 편집'),
          actions: [
            TextButton(
              onPressed: () {
                triggerInteractionHaptic(widget.settings);
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            FilledButton(onPressed: _save, child: const Text('저장')),
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
                items: [
                  const DropdownMenuItem(value: '', child: Text('폴더 없음')),
                  ...widget.folders.map(
                    (folder) => DropdownMenuItem(
                      value: folder.id,
                      child: Text(folder.name),
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
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    '프롬프트 내용',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      triggerInteractionHaptic(widget.settings);
                      setState(
                        () => _segments.add(
                          PromptSegment(
                            text: '',
                            colorValue: AppPalette.ink.value,
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
                              ...AppPalette.values.map(
                                (palette) => _ColorDot(
                                  colorValue: palette.value,
                                  isSelected: seg.colorValue == palette.value,
                                  onTap: () {
                                    triggerInteractionHaptic(widget.settings);
                                    setState(
                                      () => _segments[idx] = seg.copyWith(
                                        colorValue: palette.value,
                                      ),
                                    );
                                  },
                                ),
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
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                )
              : Border.all(color: Colors.black12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(colorValue).withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ]
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
    return Dialog(
      backgroundColor: const Color(0xFF202020),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 640,
        height: 520,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Close Button
            Row(
              children: [
                const Text(
                  '색 편집',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
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
                Container(
                  width: 240,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black45),
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
                const SizedBox(width: 16),

                // Solid Color Preview
                Container(
                  width: 40,
                  height: 220,
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black45),
                  ),
                ),
                const SizedBox(width: 16),

                // Brightness Slider
                Container(
                  width: 16,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black45),
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
                                height: 36,
                                child: TextField(
                                  controller: _hexController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF2C2C2E),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Format Dropdown
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: DropdownButtonFormField<String>(
                                  value: _colorFormat,
                                  dropdownColor: const Color(0xFF2C2C2E),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF2C2C2E),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'RGB', child: Text('RGB', style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: 'HSV', child: Text('HSV', style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: 'HSL', child: Text('HSL', style: TextStyle(color: Colors.white))),
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
                            const SizedBox(width: 8),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Numeric Inputs
                        ...List.generate(3, (idx) {
                          final label = _numericLabels[idx];
                          final controller = idx == 0
                              ? _field1Controller
                              : (idx == 1 ? _field2Controller : _field3Controller);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        fillColor: const Color(0xFF2C2C2E),
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Colors.white24),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: Colors.white24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    label,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

            // Lower Section: Grids
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
                        const Text(
                          '기본 색',
                          style: TextStyle(color: Colors.white, fontSize: 14),
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
                            const Text(
                              '사용자 지정 색',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: _addCurrentColorToCustom,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
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
                  child: const Text('취소', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    triggerInteractionHaptic(widget.settings);
                    final activeColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
                    Navigator.pop(context, activeColor);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
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

class CustomColorCircle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget child;
    if (isEmpty) {
      child = CustomPaint(
        size: const Size(16, 16),
        painter: DashedCirclePainter(color: Colors.white30),
      );
    } else {
      child = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: color == Colors.white ? Colors.black38 : Colors.white24,
            width: 1,
          ),
        ),
      );
    }

    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(22, 22),
                painter: const DashedCirclePainter(color: Colors.white70),
              ),
              child,
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(child: child),
      ),
    );
  }
}

class BasicColorCircle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (color == Colors.white ? Colors.black38 : Colors.white12),
            width: isSelected ? 2 : 1,
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
  });

  final AppSettings settings;
  final ValueChanged<bool> onToggleTheme;
  final ValueChanged<bool> onToggleLock;
  final VoidCallback onChangePin;
  final VoidCallback onLockNow;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final ValueChanged<bool> onToggleHaptic;

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
        ],
      ),
    );
  }
}

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.name,
    required this.promptCount,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int promptCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cover color of the folder
    final coverColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
    final borderColor = isSelected
        ? scheme.primary
        : (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1));
    final labelColor = isDark ? Colors.white : Colors.black;
    final countColor = isDark ? Colors.white60 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          children: [
            // Back paper tab sticking out
            Positioned(
              top: 0,
              left: 10,
              right: 10,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
            // Front cover
            Positioned.fill(
              top: 8,
              child: CustomPaint(
                painter: FolderFrontPainter(
                  color: coverColor,
                  borderColor: borderColor,
                  borderWidth: isSelected ? 2.0 : 1.0,
                ),
              ),
            ),
            // Prompt count top-left of front cover
            Positioned(
              top: 30, // folder body starts at top 8 + painter offset 20 = 28
              left: 12,
              child: Text(
                promptCount.toString(),
                style: TextStyle(
                  color: countColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Folder name bottom-left of front cover
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                name,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderFrontPainter extends CustomPainter {
  FolderFrontPainter({
    required this.color,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final Color color;
  final Color? borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    const double r = 8.0;

    // Drawing folder cover with tab on left (y = 10), lower section on right (y = 20)
    path.moveTo(0, 10 + r);
    path.quadraticBezierTo(0, 10, r, 10);
    path.lineTo(w * 0.45 - r, 10);
    path.quadraticBezierTo(w * 0.45, 10, w * 0.48, 10 + r * 0.5);
    path.lineTo(w * 0.52, 20 - r * 0.5);
    path.quadraticBezierTo(w * 0.54, 20, w * 0.54 + r, 20);
    path.lineTo(w - r, 20);
    path.quadraticBezierTo(w, 20, w, 20 + r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FolderFrontPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
