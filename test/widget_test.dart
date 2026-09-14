import 'package:flutter_test/flutter_test.dart';
import 'package:grimm_mark/main.dart';

void main() {
  testWidgets('Rendu de MyApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
