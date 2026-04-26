import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/word_list.dart';
import '../../../core/services/assignment_service.dart';

/// 教師指派作業流程（選字庫 → 設截止日 → 確認送出）
class CreateAssignmentScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final String classroomName;

  const CreateAssignmentScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
  });

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  final _svc = AssignmentService();

  List<WordList> _wordLists = [];
  WordList? _selected;
  DateTime _dueAt = DateTime.now().toUtc().add(const Duration(days: 7));
  bool _loadingLists = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWordLists();
  }

  Future<void> _loadWordLists() async {
    try {
      final lists = await _svc.fetchAvailableWordLists();
      if (!mounted) return;
      setState(() {
        _wordLists = lists;
        _loadingLists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '載入字庫失敗：$e';
        _loadingLists = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt.toLocal(),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      // 設為當天 23:59:59 UTC
      _dueAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      ).toUtc();
    });
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇字庫')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _svc.createAssignment(
        classroomId: widget.classroomId,
        wordListId: _selected!.id,
        dueAt: _dueAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('作業已指派')),
      );
      Navigator.of(context).pop(true); // 回傳 true 通知上層刷新
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('指派失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('指派作業 — ${widget.classroomName}'),
      ),
      body: _loadingLists
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // 截止日
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today_outlined),
                              title: const Text('截止日'),
                              subtitle: Text(_formatDate(_dueAt)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '選擇字庫',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_wordLists.isEmpty)
                            const Center(child: Text('沒有可用的字庫'))
                          else
                            ..._wordLists.map((wl) {
                              final isSelected = _selected?.id == wl.id;
                              return Card(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                                child: ListTile(
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.library_books_outlined,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  title: Text(wl.name),
                                  subtitle: Text(
                                    '${wl.language.toUpperCase()}  ·  ${wl.totalWords} 字',
                                  ),
                                  onTap: () =>
                                      setState(() => _selected = wl),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    // 送出按鈕
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text(
                                  '指派給全班',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
