import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_pos/main.dart';

void main() {
  testWidgets('BeautyPOS App boot smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BeautyPOSApp());
    expect(find.text('Kasir'), findsWidgets);
  });
}
