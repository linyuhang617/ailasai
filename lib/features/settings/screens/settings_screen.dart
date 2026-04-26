import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/theme_picker.dart';
import '../../../core/services/algorithm_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _notif = NotificationService.instance;

  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _permissionDenied = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _notif.isEnabled();
    final time = await _notif.getScheduledTime();
    setState(() {
      _enabled = enabled;
      _time = time;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final granted = await _notif.requestPermission();
      if (!granted) {
        setState(() => _permissionDenied = true);
        return;
      }
      setState(() => _permissionDenied = false);
    }
    await _notif.setEnabled(value);
    setState(() => _enabled = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '已開啟每日提醒 🔔' : '已關閉每日提醒'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: '選擇每日提醒時間',
    );
    if (picked == null) return;
    await _notif.setTime(picked);
    setState(() => _time = picked);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '提醒時間已設為 ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── 主題色區塊 ────────────────────────────────────
                const ThemePicker(),

                const SizedBox(height: 16),

                // ── 算法區塊 ──────────────────────────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final algo = ref.watch(algorithmProvider);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              '複習算法',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            title: const Text('FSRS 個人化排程'),
                            subtitle: Text(algo == SrsAlgorithm.fsrs
                                ? '已開啟（FSRS）'
                                : '使用 SM-2'),
                            value: algo == SrsAlgorithm.fsrs,
                            activeThumbColor: const Color(0xFF7C6FE0),
                            onChanged: (value) {
                              ref.read(algorithmProvider.notifier).setAlgorithm(
                                    value ? SrsAlgorithm.fsrs : SrsAlgorithm.sm2,
                                  );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── 通知區塊 ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          '通知',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('每日複習提醒'),
                        subtitle: Text(_enabled ? '已開啟' : '已關閉'),
                        value: _enabled,
                        activeThumbColor: const Color(0xFF7C6FE0),
                        onChanged: _toggleEnabled,
                      ),
                      if (_enabled) ...[
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          title: const Text('提醒時間'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _timeLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7C6FE0),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  color: Colors.black26),
                            ],
                          ),
                          onTap: _pickTime,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── 權限被拒提示 ──────────────────────────────────
                if (_permissionDenied) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5A623)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFF5A623), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '通知權限已被拒絕。\n請前往「設定 → 通知 → 愛喇賽」手動開啟。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A5C00),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── 登出 ──────────────────────────────────────────
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      useRootNavigator: false,
                      builder: (_) => AlertDialog(
                        title: const Text('確認登出'),
                        content: const Text('確定要登出嗎？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              '登出',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await _notif.cancelAll();
                      if (context.mounted) {
                        await AuthService().signOut();
                            // router 會自動跳轉登入頁
                      }
                    }
                  },
                  child: const Text(
                    '登出',
                    style: TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),
              ],
            ),
    );
  }
}
