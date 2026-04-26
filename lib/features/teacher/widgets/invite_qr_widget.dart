import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Slice 12 — 邀請碼展示區
///
/// 上半為大型 QR(可切換顯示/隱藏),下半為邀請碼 + 複製 + 重新產生
class InviteQrWidget extends StatefulWidget {
  final String inviteCode;
  final VoidCallback onRegenerate;
  final bool regenerating;

  const InviteQrWidget({
    super.key,
    required this.inviteCode,
    required this.onRegenerate,
    this.regenerating = false,
  });

  @override
  State<InviteQrWidget> createState() => _InviteQrWidgetState();
}

class _InviteQrWidgetState extends State<InviteQrWidget> {
  bool _showQr = true;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邀請碼已複製'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '邀請碼',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showQr = !_showQr),
                  icon: Icon(
                    _showQr ? Icons.visibility_off : Icons.qr_code,
                    size: 18,
                  ),
                  label: Text(_showQr ? '隱藏 QR' : '顯示 QR'),
                ),
              ],
            ),
            if (_showQr) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: QrImageView(
                  data: widget.inviteCode,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: theme.colorScheme.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _copyCode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.inviteCode,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.copy,
                        size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: widget.regenerating ? null : widget.onRegenerate,
              icon: widget.regenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('重新產生邀請碼'),
            ),
          ],
        ),
      ),
    );
  }
}
