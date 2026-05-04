import 'package:flutter/material.dart';
import '../../../core/models/word.dart';
import '../../../core/services/sm2_service.dart';
import '../practice_session.dart';
import '../widgets/word_card.dart';
import '../widgets/rating_buttons.dart';
import 'review_complete_screen.dart';

class PracticeScreen extends StatefulWidget {
  final List<Word> words;
  const PracticeScreen({super.key, required this.words});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeSession _session;
  bool _isFlipped = false;
  bool _isProcessing = false;  // Slice 2 新增

  @override
  void initState() {
    super.initState();
    _session = PracticeSession(words: widget.words);
    _session.init();
  }

  void _onFlipped() => setState(() => _isFlipped = true);

  void _onRate(ReviewRating rating) {
    if (_isProcessing) return;  // Slice 2 新增：防連點
    setState(() => _isProcessing = true);  // Slice 2 新增

    _session.rate(rating);
    if (!mounted) return;
    if (_session.isComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewCompleteScreen(
            totalReviewed: _session.totalReviewed,
            correctReviewed: _session.correctReviewed,
            isPractice: true,
            onPracticeAgain: null,
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
    if (_session.isComplete) {
      return ReviewCompleteScreen(
        totalReviewed: _session.totalReviewed,
        correctReviewed: _session.correctReviewed,
        isPractice: true,
        onPracticeAgain: null,
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
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('加練',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
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
