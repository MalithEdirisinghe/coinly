import 'package:coinly/app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders firebase setup screen when config is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CoinlyApp());
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));

    expect(find.text('Coinly Setup'), findsOneWidget);
    expect(find.text('Firebase configuration is missing.'), findsOneWidget);
  });
}
