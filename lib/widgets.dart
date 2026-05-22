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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppGradients.accent),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '폴더',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '폴더 추가',
                  onPressed: onCreateFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FolderTile(
              label: '모든 프롬프트',
              count: prompts.length,
              selected: selectedFolderId.isEmpty,
              onTap: () => onSelectFolder(''),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: folders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                    trailing: PopupMenuButton<String>(
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
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? scheme.primary.withOpacity(0.25)
                : scheme.outlineVariant.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.folder_open_rounded : Icons.folder_outlined,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '프롬프트 $count개',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
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
    this.headerActions,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  final PromptItem prompt;
  final String folderName;
  final bool isGrid;
  final Widget? headerActions;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = Color(prompt.titleColorValue);
    final plainPreview = prompt.plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final variableCount = RegExp(r'\[[^\]]+\]').allMatches(plainPreview).length;
    final contentLength = plainPreview.length;
    final visibleTagCount = isGrid ? 2 : 4;
    final hiddenTagCount = prompt.tags.length > visibleTagCount
        ? prompt.tags.length - visibleTagCount
        : 0;
    final contentPadding = isGrid
        ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
        : const EdgeInsets.fromLTRB(22, 20, 22, 18);
    final previewPadding = isGrid
        ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
        : const EdgeInsets.fromLTRB(18, 18, 18, 16);
    final titleStyle =
        (isGrid
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w900,
              color: titleColor,
              height: 1.25,
            );
    final preview = Container(
      width: double.infinity,
      padding: previewPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(
          isGrid ? 0.45 : 0.38,
        ),
        borderRadius: BorderRadius.circular(isGrid ? 24 : 26),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(isGrid ? 0.18 : 0.14),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: prompt.segments
              .map(
                (segment) => TextSpan(
                  text: segment.text,
                  style: TextStyle(
                    color: Color(segment.colorValue),
                    height: isGrid ? 1.55 : 1.7,
                    fontSize: isGrid ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              .toList(),
        ),
        maxLines: isGrid ? 8 : 10,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '($folderName) ',
                    style: titleStyle?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    prompt.title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (headerActions != null) ...[
                  const SizedBox(width: 4),
                  headerActions!,
                ],
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'copy') onCopy();
                    if (val == 'edit') onEdit();
                    if (val == 'duplicate') onDuplicate();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'copy', child: Text('복사')),
                    PopupMenuItem(value: 'edit', child: Text('편집')),
                    PopupMenuItem(value: 'duplicate', child: Text('복제')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ],
            ),
            SizedBox(height: isGrid ? 12 : 14),
            if (isGrid) Expanded(child: preview) else preview,
            SizedBox(height: isGrid ? 12 : 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (variableCount > 0)
                  _PromptCapsule(
                    icon: Icons.tune_rounded,
                    label: '변수 $variableCount개',
                    backgroundColor: scheme.tertiaryContainer,
                    foregroundColor: scheme.tertiary,
                  ),
                ...prompt.tags.take(visibleTagCount).map(
                  (tag) => _PromptCapsule(
                    icon: Icons.sell_outlined,
                    label: '#$tag',
                    backgroundColor: scheme.surfaceContainerHighest.withOpacity(
                      0.8,
                    ),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                ),
                if (hiddenTagCount > 0)
                  _PromptCapsule(
                    label: '+$hiddenTagCount',
                    backgroundColor: scheme.surfaceContainerHighest.withOpacity(
                      0.8,
                    ),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                _PromptCapsule(
                  icon: Icons.subject_rounded,
                  label: '${contentLength}자',
                  backgroundColor: scheme.surface,
                  foregroundColor: scheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: isGrid ? 10 : 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '수정 ${formatDate(prompt.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isGrid ? 11 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _PromptActionButton(
                  onPressed: onCopy,
                  tooltip: '복사',
                  icon: Icons.content_copy_rounded,
                  compact: isGrid,
                ),
                const SizedBox(width: 8),
                _PromptActionButton(
                  onPressed: onEdit,
                  tooltip: '편집',
                  icon: Icons.edit_outlined,
                  compact: isGrid,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCapsule extends StatelessWidget {
  const _PromptCapsule({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  final IconData? icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptActionButton extends StatelessWidget {
  const _PromptActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.compact,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
            color: scheme.onSurfaceVariant,
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

class PromptEditorDialog extends StatefulWidget {
  const PromptEditorDialog({
    super.key,
    required this.folders,
    this.prompt,
    this.initialFolderId = '',
    required this.favoriteColors,
    required this.onToggleFavorite,
  });

  final List<FolderItem> folders;
  final PromptItem? prompt;
  final String initialFolderId;
  final List<int> favoriteColors;
  final ValueChanged<int> onToggleFavorite;

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
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => ColorPickerDialog(presets: _presetColors),
    );

    if (color != null) {
      setState(() {
        _segments[segmentIdx] = _segments[segmentIdx].copyWith(
          colorValue: color.value,
        );
      });
    }
  }

  Future<void> _pickTitleColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) => ColorPickerDialog(presets: _presetColors),
    );

    if (color == null) return;
    setState(() => _titleColorValue = color.value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.prompt == null ? '프롬프트 만들기' : '프롬프트 편집'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '제목 색상',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._presetColors.map(
                      (color) => _ColorDot(
                        colorValue: color.value,
                        isSelected: _titleColorValue == color.value,
                        onTap: () =>
                            setState(() => _titleColorValue = color.value),
                      ),
                    ),
                    IconButton(
                      onPressed: _pickTitleColor,
                      tooltip: '색상 선택',
                      icon: const Icon(Icons.palette_outlined),
                    ),
                  ],
                ),
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
                    onPressed: () => setState(
                      () => _segments.add(
                        PromptSegment(
                          text: '',
                          colorValue: AppPalette.ink.value,
                        ),
                      ),
                    ),
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
                                  onTap: () => setState(
                                    () => _segments[idx] = seg.copyWith(
                                      colorValue: palette.value,
                                    ),
                                  ),
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
                                    onTap: () => setState(
                                      () => _segments[idx] = seg.copyWith(
                                        colorValue: colorValue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(
                                  Icons.palette_outlined,
                                  size: 20,
                                ),
                                onPressed: () => _pickMoreColors(idx),
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
                                  widget.onToggleFavorite(seg.colorValue);
                                  setState(() {});
                                },
                                tooltip: '즐겨찾기 추가',
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  if (_segments.length > 1) {
                                    _segments.removeAt(idx);
                                  }
                                }),
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
    return GestureDetector(
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
    );
  }
}

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key, required this.presets});

  final List<Color> presets;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('색상 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: presets.length,
          itemBuilder: (ctx, idx) {
            final color = presets[idx];
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
            );
          },
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
  });

  final AppSettings settings;
  final ValueChanged<bool> onToggleTheme;
  final ValueChanged<bool> onToggleLock;
  final VoidCallback onChangePin;
  final VoidCallback onLockNow;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

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
