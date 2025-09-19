// Test básico para la aplicación Te Leo
//
// Verifica que la aplicación se inicie correctamente y muestre la pantalla principal

import 'package:flutter_test/flutter_test.dart';

import 'package:te_leo/main.dart';

void main() {
  testWidgets('Te Leo app smoke test', (WidgetTester tester) async {
    // Construir la aplicación y mostrar un frame
    await tester.pumpWidget(const TeLeoApp());

    // Verificar que el título de la aplicación esté presente
    expect(find.text('Te Leo'), findsOneWidget);

    // Verificar que los botones principales estén presentes
    expect(find.text('Escanear Texto'), findsOneWidget);
    expect(find.text('Mi Biblioteca'), findsOneWidget);

    // Verificar que el texto de bienvenida esté presente
    expect(find.text('Bienvenido a Te Leo'), findsOneWidget);
  });
}
