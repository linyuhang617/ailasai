import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAlgorithmKey = 'algorithm';

enum SrsAlgorithm { sm2, fsrs }

// 全域 boot 值，main() 啟動時讀 SharedPreferences 填入
SrsAlgorithm bootAlgorithm = SrsAlgorithm.sm2;

SrsAlgorithm _parse(String? raw) =>
    raw == 'fsrs' ? SrsAlgorithm.fsrs : SrsAlgorithm.sm2;

Future<void> preloadAlgorithm() async {
  final prefs = await SharedPreferences.getInstance();
  bootAlgorithm = _parse(prefs.getString(_kAlgorithmKey));
}

class AlgorithmNotifier extends Notifier<SrsAlgorithm> {
  @override
  SrsAlgorithm build() => bootAlgorithm;

  Future<void> setAlgorithm(SrsAlgorithm algo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kAlgorithmKey, algo == SrsAlgorithm.fsrs ? 'fsrs' : 'sm2');
    bootAlgorithm = algo;
    state = algo;
  }
}

final algorithmProvider =
    NotifierProvider<AlgorithmNotifier, SrsAlgorithm>(
        AlgorithmNotifier.new);
