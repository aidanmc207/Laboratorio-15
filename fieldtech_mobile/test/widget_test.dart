import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldtech_mobile/screens/nueva_incidencia_modal.dart';

void main() {
  testWidgets('El formulario muestra los campos de la incidencia', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NuevaIncidenciaModal(onGuardado: () {})),
      ),
    );

    expect(find.text('Registrar Incidencia en Campo'), findsOneWidget);
    expect(find.text('Obtener GPS'), findsOneWidget);
    expect(find.text('Guardar Localmente (Offline)'), findsOneWidget);
  });

  testWidgets('No guarda sin titulo ni coordenadas GPS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NuevaIncidenciaModal(onGuardado: () {})),
      ),
    );

    await tester.tap(find.text('Guardar Localmente (Offline)'));
    await tester.pump();

    expect(find.text('Debe ingresar un título y capturar las coordenadas GPS.'), findsOneWidget);
  });
}
