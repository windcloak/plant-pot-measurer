import 'package:flutter/material.dart';

import '../models/measurement_session.dart';
import '../models/pot_shape.dart';
import 'results_screen.dart';

class ShapeSelectScreen extends StatefulWidget {
  final MeasurementSession session;

  const ShapeSelectScreen({super.key, required this.session});

  @override
  State<ShapeSelectScreen> createState() => _ShapeSelectScreenState();
}

class _ShapeSelectScreenState extends State<ShapeSelectScreen> {
  late PotShape _shape = widget.session.shape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Which shape is closest?')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: PotShape.values.map((shape) {
                  return Card(
                    child: RadioListTile<PotShape>(
                      value: shape,
                      groupValue: _shape,
                      title: Text(shape.label),
                      subtitle: Text(shape.description),
                      onChanged: (value) {
                        if (value != null) setState(() => _shape = value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  widget.session.shape = _shape;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(session: widget.session),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('See volume'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
