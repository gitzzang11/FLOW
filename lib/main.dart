import 'package:flutter/material.dart';

import 'models.dart';
import 'screens.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FlowApp(initialBackupPath: _firstStartupBackupPath(args)));
}

String? _firstStartupBackupPath(List<String> args) {
  for (final arg in args) {
    final path = arg.trim();
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.flow') || lowerPath.endsWith('.json')) {
      return path;
    }
  }
  return null;
}

class FlowApp extends StatefulWidget {
  const FlowApp({super.key, this.initialBackupPath});

  final String? initialBackupPath;

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> {
  bool _loading = true;
  bool _unlocked = false;
  late PromptStore _store;

  void _handleUnlock() {
    if (_unlocked || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _unlocked = true);
    });
  }

  void _handleRelock() {
    if (!_unlocked || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _unlocked = false);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _store = await PromptStore.load();

    if (_store.folders.isEmpty) {
      _store.folders.add(
        FolderItem(
          id: PromptStore.newId(),
          name: '빠른 시작',
          createdAt: DateTime.now(),
        ),
      );
    }

    if (_store.prompts.isEmpty) {
      final folderId = _store.folders.first.id;
      final now = DateTime.now();
      _store.prompts.addAll([
        PromptItem(
          id: PromptStore.newId(),
          title: '랜딩 페이지 카피라이팅',
          titleColorValue: AppPalette.ink.value,
          folderId: folderId,
          tags: ['마케팅', '카피'],
          createdAt: now,
          updatedAt: now,
          segments: [
            PromptSegment(
              text: '다음 제품의 전환율이 높은 랜딩 페이지 카피를 작성해줘. ',
              colorValue: AppPalette.ink.value,
            ),
            PromptSegment(text: '[제품 이름]', colorValue: AppPalette.coral.value),
            PromptSegment(text: ' 대상 ', colorValue: AppPalette.ink.value),
            PromptSegment(text: '[타깃 고객]', colorValue: AppPalette.sky.value),
            PromptSegment(
              text: ' 을 위한 핵심 문구를 만들어줘.',
              colorValue: AppPalette.ink.value,
            ),
          ],
        ),
        PromptItem(
          id: PromptStore.newId(),
          title: '회의록 요약 프롬프트',
          titleColorValue: AppPalette.ink.value,
          folderId: '',
          tags: ['업무', '요약'],
          createdAt: now,
          updatedAt: now,
          segments: [
            PromptSegment(
              text: '다음 회의록을 액션 아이템, 담당자, 마감 일정 중심으로 요약해줘. ',
              colorValue: AppPalette.ink.value,
            ),
            PromptSegment(text: '[회의 내용]', colorValue: AppPalette.amber.value),
            PromptSegment(
              text: ' 을 바탕으로 고객 공유용 문장도 함께 정리해줘.',
              colorValue: AppPalette.ink.value,
            ),
          ],
        ),
      ]);
      await _store.persist();
    }

    setState(() {
      _loading = false;
      _unlocked = !_store.settings.lockEnabled;
    });
  }

  Future<void> _saveStore() async {
    await _store.persist();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _loading ? const AppSettings() : _store.settings;
    const themeSeed = Color(0xFF0F766E);

    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: buildTheme(Brightness.light, themeSeed),
      darkTheme: buildTheme(Brightness.dark, themeSeed),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (settings.lockEnabled && !_unlocked)
          ? LockScreen(
              key: const ValueKey('lock-screen'),
              pin: settings.pinCode,
              onUnlock: _handleUnlock,
              settings: settings,
            )
          : FlowShell(
              key: const ValueKey('flow-shell'),
              store: _store,
              initialBackupPath: widget.initialBackupPath,
              onStoreChanged: _saveStore,
              onRequireRelock: _handleRelock,
            ),
    );
  }
}
