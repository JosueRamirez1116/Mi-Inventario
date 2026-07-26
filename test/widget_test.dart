import 'package:flutter_test/flutter_test.dart';

import 'package:mi_inventario/main.dart';

void main() {
  testWidgets('shows login screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
  });
}
