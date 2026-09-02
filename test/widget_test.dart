import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auto_car/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SmartAutoCarApp()),
    );
    await tester.pump();
    expect(find.textContaining('SmartAutoCar'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
