import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/word.dart';
import 'word_card_front.dart';
import 'word_card_back.dart';

class WordCard extends StatefulWidget {
  final Word word;
  final VoidCallback? onFlipped;

  const WordCard({super.key, required this.word, this.onFlipped});

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isFront = true;
  bool _hasFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_isFront) {
      _controller.forward();
      if (!_hasFlipped) {
        _hasFlipped = true;
        widget.onFlipped?.call();
      }
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = _animation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 268),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C6FE0).withValues(alpha: 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isFrontVisible
                  ? WordCardFront(word: widget.word)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: WordCardBack(word: widget.word),
                    ),
            ),
          );
        },
      ),
    );
  }
}
