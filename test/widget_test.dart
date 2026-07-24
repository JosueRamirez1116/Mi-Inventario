import 'package:flutter_test/flutter_test.dart';

import 'package:mi_inventario/main.dart';

void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('MiInventario'), findsOneWidget);
  });
}
