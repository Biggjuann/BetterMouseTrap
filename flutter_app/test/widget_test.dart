import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BetterMousetrapApp());
    expect(find.text('Better Mousetrap'), findsOneWidget);
    expect(find.text('Make it better'), findsOneWidget);
  });
}
