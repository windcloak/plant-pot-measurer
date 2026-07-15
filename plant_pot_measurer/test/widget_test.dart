// Basic smoke test: the app launches and shows the home screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_pot_measurer/main.dart';

void main() {
  testWidgets('App launches and shows the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PlantPotMeasurerApp());

    expect(find.text('Measure a pot'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });
}
