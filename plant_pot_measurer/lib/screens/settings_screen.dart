import 'package:flutter/material.dart';

import '../models/measurement_unit.dart';
import '../services/unit_preference_store.dart';

/// Lets the user choose whether lengths are shown and entered in
/// centimeters or inches by default, throughout the whole app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  MeasurementUnit? _unit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unit = await UnitPreferenceStore.load();
    if (!mounted) return;
    setState(() => _unit = unit);
  }

  Future<void> _select(MeasurementUnit unit) async {
    setState(() => _unit = unit);
    await UnitPreferenceStore.save(unit);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: unit == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      'Measurement unit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    'Choose how lengths are shown and entered throughout '
                    'the app — reference objects, calibration, and results.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        for (final option in MeasurementUnit.values)
                          RadioListTile<MeasurementUnit>(
                            value: option,
                            groupValue: unit,
                            title: Text(option.label),
                            onChanged: (value) {
                              if (value != null) _select(value);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
