import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/widgets/base/zeni_primary_button.dart';
import 'package:zeni/core/widgets/base/zeni_secondary_button.dart';

void main() {
  testWidgets(
    'secondary and primary buttons handle long labels in narrow widths and larger text scale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Material(
              child: Center(
                child: SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ZeniSecondaryButton(
                        label: 'Começar uma nova família neste aparelho agora',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      ZeniPrimaryButton(
                        label:
                            'Restaurar toda a família com segurança neste aparelho',
                        icon: Icons.cloud_download_rounded,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ZeniSecondaryButton), findsOneWidget);
      expect(find.byType(ZeniPrimaryButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
