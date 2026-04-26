import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/word_list.dart';
import '../../../core/services/stats_service.dart';
import '../../../core/services/word_list_service.dart';
import '../widgets/memory_stats_section.dart';

class WordListDetailScreen extends StatefulWidget {
  const WordListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  State<WordListDetailScreen> createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  final _listService = WordListService();
  final _statsService = StatsService();

  WordList? _list;
  MemoryStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;





  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _listService.fetchListById(widget.listId, userId),
        _statsService.getMemoryStats(
          userId: userId,
          wordListId: widget.listId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _list = results[0] as WordList?;
        _stats = results[1] as MemoryStats;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_list?.name ?? '字庫詳情'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_list == null) {
      return const _NotFoundView();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ListHeader(wordList: _list!),
          const SizedBox(height: 24),
          if (_stats != null) MemoryStatsSection(stats: _stats!),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.wordList});
  final WordList wordList;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const successGreen = Color(0xFF3DBA6E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Tag(label: wordList.language, color: cs.primary),
            if (wordList.examType != null)
              _Tag(
                label: wordList.examType!,
                color: const Color(0xFFF5A623),
              ),
            if (wordList.isJoined)
              _Tag(label: '已加入', color: successGreen),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${wordList.totalWords} 個單字',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        if (wordList.isJoined && wordList.totalWords > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: wordList.progressPercent,
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(successGreen),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(wordList.progressPercent * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text('載入失敗', style: TextStyle(color: Colors.red.shade400)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('重試')),
        ],
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 40,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          const Text('字庫不存在或已被移除'),
        ],
      ),
    );
  }
}
