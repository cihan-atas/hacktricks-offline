import 'package:flutter_test/flutter_test.dart';
import 'package:hacktricks_vault/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HackTricksVaultApp());
    expect(find.byType(HackTricksVaultApp), findsOneWidget);
  });
}
