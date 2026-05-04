import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/word.dart';
import '../../../core/services/algorithm_service.dart';
import '../../../core/services/sm2_service.dart';
import '../review_session.dart';
import '../widgets/word_card.dart';
import '../widgets/rating_buttons.dart';
import '../../home/widgets/assignments_section.dart' show assignmentsProvider;
import '../../team/screens/team_screen.dart' show myTeamsProvider;
import 'review_complete_screen.dart';
import 'practice_screen.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final List<Word> words;
  const ReviewScreen({super.key, required this.words});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final ReviewSession _session;
  bool _isFlipped = false;
  bool _loading = true;
  bool _isProcessing = false;  // Slice 2 新增

  @override
  void initState() {
    super.initState();
    final algorithm = ref.read(algorithmProvider);
    _session = ReviewSession(words: widget.words, algorithm: algorithm);
    _session.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _onFlipped() => setState(() => _isFlipped = true);

  void _goToPractice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(words: widget.words),
      ),
    );
  }

  Future<void> _onRate(ReviewRating rating) async {
    if (_isProcessing) return;  // Slice 2 新增：防連點
    setState(() => _isProcessing = true);  // Slice 2 新增

    await _session.rate(rating);
    if (!mounted) return;
    if (_session.isComplete) {
      ref.invalidate(assignmentsProvider);
      ref.invalidate(myTeamsProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewCompleteScreen(
            totalReviewed: _session.totalReviewed,
            correctReviewed: _session.correctReviewed,
            onPracticeAgain: _goToPractice,
          ),
        ),
      );
      return;
    }
    setState(() {
      _isFlipped = false;
      _isProcessing = false;  // Slice 2 新增：下一張卡就緒才解鎖
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_session.isComplete) {
      return ReviewCompleteScreen(
        totalReviewed: _session.totalReviewed,
        correctReviewed: _session.correctReviewed,
        onPracticeAgain: _goToPractice,
      );
    }

    final word = _session.currentWord!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Row(
                children: [
                  const Text('複習',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A3358))),
                  const Spacer(),
                  Text('剩 ${_session.remainingCount} 張',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFB0A8CC))),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: WordCard(
                  key: ValueKey(word.id + _session.totalReviewed.toString()),
                  word: word,
                  onFlipped: _onFlipped,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isFlipped
                  ? Padding(
                      key: const ValueKey('buttons'),
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                      child: RatingButtons(
                        intervals: _session.previewIntervals,
                        onRate: _onRate,
                        enabled: !_isProcessing,  // Slice 2 新增
                      ),
                    )
                  : const Padding(
                      key: ValueKey('hint'),
                      padding: EdgeInsets.all(28),
                      child: Text('點擊卡片查看答案',
                          style: TextStyle(
                              color: Color(0xFFB0A8CC), fontSize: 14)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
