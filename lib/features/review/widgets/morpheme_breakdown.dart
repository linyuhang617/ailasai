import 'package:flutter/material.dart';
import '../../../core/models/morpheme.dart';
import '../../../core/services/morpheme_service.dart';

class MorphemeBreakdown extends StatefulWidget {
  final String wordId;
  final String wordTerm;

  const MorphemeBreakdown({
    super.key,
    required this.wordId,
    required this.wordTerm,
  });

  @override
  State<MorphemeBreakdown> createState() => _MorphemeBreakdownState();
}

class _MorphemeBreakdownState extends State<MorphemeBreakdown> {
  final _service = MorphemeService();
  late final Future<List<WordMorpheme>> _morphemesFuture;

  static const Color _prefixColor = Color(0xFFE07C5A);
  static const Color _suffixColor = Color(0xFF3DBA6E);

  Color _typeColor(BuildContext context, String type) {
    switch (type) {
      case 'prefix': return _prefixColor;
      case 'suffix': return _suffixColor;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'prefix': return 'prefix';
      case 'suffix': return 'suffix';
      default: return 'root';
    }
  }

  @override
  void initState() {
    super.initState();
    _morphemesFuture = _service.fetchMorphemes(widget.wordId);
  }


  void _showSheet(BuildContext context, WordMorpheme wm) {
    final color = _typeColor(context, wm.morpheme.type);
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _MorphemeSheet(
        wm: wm,
        color: color,
        typeLabel: _typeLabel(wm.morpheme.type),
        service: _service,
        excludeWordId: widget.wordId,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WordMorpheme>>(
      future: _morphemesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final morphemes = snapshot.data!;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: morphemes.map((wm) {
                final color = _typeColor(context, wm.morpheme.type);
                return GestureDetector(
                  onTap: () => _showSheet(context, wm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          wm.morpheme.form,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(height: 3, color: color),
                        const SizedBox(height: 5),
                        Text(
                          _typeLabel(wm.morpheme.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          wm.morpheme.meaningZh,
                          style: TextStyle(
                            fontSize: 9,
                            color: color.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              '點擊字根查看同族單字',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────
class _MorphemeSheet extends StatefulWidget {
  final WordMorpheme wm;
  final Color color;
  final String typeLabel;
  final MorphemeService service;
  final String excludeWordId;

  const _MorphemeSheet({
    required this.wm,
    required this.color,
    required this.typeLabel,
    required this.service,
    required this.excludeWordId,
  });

  @override
  State<_MorphemeSheet> createState() => _MorphemeSheetState();
}

class _MorphemeSheetState extends State<_MorphemeSheet> {
  late final Future<List<WordFamilyMember>> _familyFuture;

  @override
  void initState() {
    super.initState();
    _familyFuture = widget.service.fetchWordFamily(
      widget.wm.morpheme.id,
      excludeWordId: widget.excludeWordId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DCF0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.wm.morpheme.form,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.wm.morpheme.meaningZh,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF3A3358),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<WordFamilyMember>>(
            future: _familyFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final members = snapshot.data!;
              if (members.isEmpty) {
                return Text(
                  '暫無同字根單字',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF3A3358).withValues(alpha: 0.35),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '同字根單字',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.color.withValues(alpha: 0.55),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...members.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            m.term,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3358),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.definitionZh,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB0A8CC),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
