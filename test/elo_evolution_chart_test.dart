import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matharena/features/game/presentation/widgets/elo_evolution_chart.dart';

void main() {
  testWidgets('EloEvolutionChart does not crash with flat history',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EloEvolutionChart(
            eloHistory: {1700000000000: 865},
            currentElo: 865,
          ),
        ),
      ),
    );

    // If fl_chart asserts (interval == 0), the test will fail before here.
    expect(find.text('Évolution ELO'), findsOneWidget);
  });
}
