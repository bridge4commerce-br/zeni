import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/widgets/inputs/counter_stepper.dart';

void main() {
  testWidgets(
    'counter stepper keeps accessibility labels legible in narrow width with dyslexia font',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: ThemeData().textTheme.apply(fontFamily: 'OpenDyslexic'),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            );
          },
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: CounterStepper(
                  label: 'Tamanho da letra',
                  subtitle: 'Ajuste aplicado no app inteiro',
                  value: 115,
                  min: 85,
                  max: 135,
                  step: 5,
                  suffix: '%',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tamanho da letra'), findsOneWidget);
      expect(find.text('Ajuste aplicado no app inteiro'), findsOneWidget);
      expect(find.text('115 %'), findsOneWidget);
      expect(find.byTooltip('Aumentar Tamanho da letra'), findsOneWidget);
      expect(find.byTooltip('Diminuir Tamanho da letra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
