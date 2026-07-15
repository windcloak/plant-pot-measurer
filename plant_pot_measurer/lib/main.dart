import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PlantPotMeasurerApp());
}

class PlantPotMeasurerApp extends StatelessWidget {
  const PlantPotMeasurerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3F7D45); // leafy green
    return MaterialApp(
      title: 'Plant Pot Measurer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
