import 'package:flutter/material.dart';

import '../../../core/services/team_service.dart';

/// 建立或加入隊伍 - TabBar 兩個 tab
/// 成功時 pop(true)，上層需要 invalidate 列表
class CreateJoinTeamScreen extends StatefulWidget {
  const CreateJoinTeamScreen({super.key});

  @override
  State<CreateJoinTeamScreen> createState() => _CreateJoinTeamScreenState();
}

class _CreateJoinTeamScreenState extends State<CreateJoinTeamScreen> {
  final _service = TeamService();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _creating = false;
  bool _joining = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      await _service.createTeam(name);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _joining = true);
    try {
      await _service.joinByInviteCode(code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('隊伍'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '建立隊伍'),
              Tab(text: '加入隊伍'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildCreateTab(), _buildJoinTab()],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '為你的隊伍取個名字',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '建立後系統會自動產生 8 碼邀請碼，最多 10 人',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '隊伍名稱',
              hintText: '例如：英文衝刺組',
              border: OutlineInputBorder(),
            ),
            maxLength: 30,
            enabled: !_creating,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
            ),
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('建立隊伍', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '輸入隊伍邀請碼',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '請隊長把 8 碼邀請碼分享給你',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(
              labelText: '邀請碼',
              hintText: '8 碼英數字',
              border: OutlineInputBorder(),
            ),
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            enabled: !_joining,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
            ),
            onPressed: _joining ? null : _join,
            child: _joining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('加入隊伍', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
