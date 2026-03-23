import 'package:coinly/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders firebase setup screen when config is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CoinlyApp());
    await tester.pump();

    expect(find.text('Coinly Setup'), findsOneWidget);
    expect(find.text('Firebase configuration is missing.'), findsOneWidget);
  });
}
