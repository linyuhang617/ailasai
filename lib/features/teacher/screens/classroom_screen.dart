import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/classroom.dart';
import '../../../core/services/classroom_service.dart';
import '../widgets/invite_qr_widget.dart';
import '../../teacher/screens/create_assignment_screen.dart';
import '../../../core/models/assignment.dart';
import '../../../core/services/assignment_service.dart';

/// 單一班級詳情:邀請碼 + 成員列表 + 管理操作
class ClassroomScreen extends ConsumerStatefulWidget {
  final String classroomId;
  const ClassroomScreen({super.key, required this.classroomId});

  @override
  ConsumerState<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends ConsumerState<ClassroomScreen> {
  final _svc = ClassroomService();
  Classroom? _classroom;
  List<ClassroomMember> _members = [];
  final _assignSvc = AssignmentService();
  List<ClassroomAssignment> _assignments = [];
  bool _loading = true;
  bool _regenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _svc.fetchMyClassrooms();
      final target = all.where((c) => c.id == widget.classroomId).firstOrNull;
      if (target == null) {
        if (mounted) setState(() => _error = '找不到此班級');
        return;
      }
      final members = await _svc.fetchMembers(widget.classroomId);
      final assignments =
          await _assignSvc.fetchClassroomAssignments(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _classroom = target;
        _members = members;
        _assignments = assignments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '載入失敗:$e';
        _loading = false;
      });
    }
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final updated = await _svc.regenerateInviteCode(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _classroom = _classroom?.copyWith(inviteCode: updated.inviteCode);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邀請碼已更新,舊碼失效')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失敗:$e')),
      );
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _removeMember(ClassroomMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('移除學生?'),
        content: Text('將 ${m.studentEmail ?? "此學生"} 從班級移除?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _svc.removeMember(m.id);
      if (!mounted) return;
      setState(() => _members.removeWhere((x) => x.id == m.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已移除')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('移除失敗:$e')),
      );
    }
  }

  Future<void> _deleteClassroom() async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除班級?'),
        content: const Text('此操作無法復原,所有學生將被移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _svc.deleteClassroom(widget.classroomId);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除失敗:$e')),
      );
    }
  }

  Future<void> _goToAssign() async {
    if (_classroom == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateAssignmentScreen(
          classroomId: widget.classroomId,
          classroomName: _classroom!.name,
        ),
      ),
    );
    if (result == true) _load(); // 指派完刷新
  }

  Future<void> _deleteAssignment(ClassroomAssignment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除作業?'),
        content: Text('刪除「${a.wordListName}」的指派作業？學生進度也會一併刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _assignSvc.deleteAssignment(a.id);
      if (!mounted) return;
      setState(() => _assignments.removeWhere((x) => x.id == a.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('作業已刪除')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('刪除失敗：$e')));
    }
  }

  void _goToStudentProgress(ClassroomMember m) {
    final email = m.studentEmail;
    final q = email != null ? '?email=${Uri.encodeComponent(email)}' : '';
    context.push('/classrooms/${widget.classroomId}/student/${m.studentId}$q');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_classroom?.name ?? '班級'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_add),
            tooltip: '指派作業',
            onPressed: _classroom == null ? null : _goToAssign,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      InviteQrWidget(
                        inviteCode: _classroom!.inviteCode,
                        onRegenerate: _regenerate,
                        regenerating: _regenerating,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          '成員(${_members.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              '尚無學生加入\n請分享邀請碼或 QR',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        ..._members.map(
                          (m) => ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(m.studentEmail ?? m.studentId),
                            subtitle: Text('加入於 ${_formatDate(m.joinedAt)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red.shade400,
                              onPressed: () => _removeMember(m),
                            ),
                            onTap: () => _goToStudentProgress(m),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                          '指派作業（${_assignments.length}）',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_assignments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Text(
                            '尚未指派任何作業',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      else
                        ..._assignments.map(
                          (a) => ListTile(
                            leading: const Icon(Icons.assignment_outlined),
                            title: Text(a.wordListName),
                            subtitle: Text(
                              '截止：${_formatDate(a.dueAt)}  ·  ${a.totalWords} 字${a.isOverdue ? '  已截止' : ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red.shade400,
                              onPressed: () => _deleteAssignment(a),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton.icon(
                          onPressed: _deleteClassroom,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('刪除班級'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}
