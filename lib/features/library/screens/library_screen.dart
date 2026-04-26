import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/word_list.dart';
import '../../../core/services/word_list_service.dart';
import '../widgets/word_list_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _service = WordListService();
  List<WordList> _lists = [];
  bool _loading = true;
  String? _error;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  Future<void> _load() async {
    if (_userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await _service.fetchAllLists(_userId!);
      if (mounted) setState(() => _lists = lists);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(WordList wl) async {
    if (_userId == null) return;
    setState(() => _processingIds.add(wl.id));
    try {
      await _service.joinList(wl.id, _userId!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(wl.id));
    }
  }

  Future<void> _leave(WordList wl) async {
    if (_userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => AlertDialog(
        title: const Text('移除字庫'),
        content: Text('確定要移除「${wl.name}」？\n已學習的進度不會消失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingIds.add(wl.id));
    try {
      await _service.leaveList(wl.id, _userId!);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(wl.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字庫'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('載入失敗',
                          style:
                              TextStyle(color: Colors.red.shade400)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: _load, child: const Text('重試')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _lists.isEmpty
                      ? LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: SizedBox(height: constraints.maxHeight, child: const Center(child: Text("目前沒有可用字庫")))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lists.length,
                          itemBuilder: (_, i) {
                            final wl = _lists[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: WordListCard(
                                wordList: wl,
                                isLoading: _processingIds
                                    .contains(wl.id),
                                onJoin: () => _join(wl),
                                onLeave: () => _leave(wl),
                                onTap: () =>
                                    context.push('/library/${wl.id}'),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
