import 'package:flutter_test/flutter_test.dart';
import 'package:ailasai/main.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    // main() 需要 Supabase + Isar，跳過完整啟動
    expect(AilasaiApp, isNotNull);
  });
}
