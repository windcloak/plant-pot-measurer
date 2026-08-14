import 'package:flutter/material.dart';

import '../models/measurement_session.dart';
import '../models/measurement_unit.dart';
import '../models/pot_shape.dart';
import '../services/calibration_store.dart';
import '../services/measurement_history_store.dart';
import '../services/unit_preference_store.dart';
import '../utils/volume_calculator.dart';
import '../widgets/volume_display_widgets.dart';
import 'calibration_screen.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final MeasurementSession session;

  const ResultsScreen({super.key, required this.session});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? _historyEntryId;
  MeasurementUnit _unit = UnitPreferenceStore.defaultUnit;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final unit = await UnitPreferenceStore.load();
    if (!mounted) return;
    setState(() => _unit = unit);
  }

  Future<void> _saveToHistory() async {
    if (!widget.session.isReadyForResults) return;
    try {
      final saved = await MeasurementHistoryStore.add(widget.session);
      _historyEntryId = saved.id;
    } catch (_) {
      // History is a convenience feature — a failed save shouldn't block
      // the user from seeing their results.
    }
  }

  /// Pushes the calibration screen and returns only after it has fully
  /// closed (popped back to this screen). All side effects (setState,
  /// persistence, snackbars) happen below, strictly after that pop, so
  /// this screen is never mutated while another route is still tearing
  /// down.
  Future<void> _openCalibrationScreen() async {
    final session = widget.session;
    final appTopD = session.topDiameterCm;
    final appBottomD = session.bottomDiameterCm;
    final appHeight = session.heightCm;
    if (appTopD == null || appBottomD == null || appHeight == null) return;

    final showResetOption = (session.correctionFactor - 1.0).abs() > 0.001;

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CalibrationScreen(
          appTopDiameterCm: appTopD,
          appBottomDiameterCm: appBottomD,
          appHeightCm: appHeight,
          showResetOption: showResetOption,
          unit: _unit,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (identical(result, resetCalibrationRequested)) {
      await CalibrationStore.reset();
      if (!mounted) return;
      setState(() => session.correctionFactor = CalibrationStore.defaultFactor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration reset to default.')),
      );
      return;
    }

    if (result is CalibrationInput) {
      final ratios = [
        result.realTopCm / appTopD,
        result.realBottomCm / appBottomD,
        result.realHeightCm / appHeight,
      ];
      final avgRatio = ratios.reduce((a, b) => a + b) / ratios.length;
      final newFactor = session.correctionFactor * avgRatio;

      if (result.remember) {
        await CalibrationStore.save(newFactor);
      }
      if (!mounted) return;
      setState(() => session.correctionFactor = newFactor);

      final entryId = _historyEntryId;
      if (entryId != null) {
        final newTop = session.topDiameterCm;
        final newBottom = session.bottomDiameterCm;
        final newHeight = session.heightCm;
        if (newTop != null && newBottom != null && newHeight != null) {
          await MeasurementHistoryStore.updateDimensions(
            id: entryId,
            topDiameterCm: newTop,
            bottomDiameterCm: newBottom,
            heightCm: newHeight,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.remember
                ? 'Calibration saved — future measurements will be adjusted.'
                : 'Applied to this result only.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final topD = session.topDiameterCm;
    final bottomD = session.bottomDiameterCm;
    final h = session.heightCm;

    if (topD == null || bottomD == null || h == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child: Text('Missing measurements — please go back and retake.'),
        ),
      );
    }

    final volumeCm3 = VolumeCalculator.volumeCm3(
      shape: session.shape,
      topDiameterCm: topD,
      bottomDiameterCm: bottomD,
      heightCm: h,
    );

    final hasCorrection = (session.correctionFactor - 1.0).abs() > 0.001;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (session.photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  session.photo!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            DimensionRow(label: 'Top diameter', valueCm: topD, unit: _unit),
            DimensionRow(
              label: 'Bottom diameter',
              valueCm: bottomD,
              unit: _unit,
            ),
            DimensionRow(label: 'Height', valueCm: h, unit: _unit),
            const SizedBox(height: 8),
            Text(
              'Shape: ${session.shape.label}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (hasCorrection)
              Text(
                'Includes your accuracy calibration '
                '(×${session.correctionFactor.toStringAsFixed(3)}).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const Divider(height: 32),
            Text('Volume', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TrueVolumeCard(volumeCm3: volumeCm3),
            const SizedBox(height: 12),
            NurseryVolumeCard(volumeCm3: volumeCm3),
            if (session.shape == PotShape.taperedRoundedBottom) ...[
              const SizedBox(height: 12),
              Text(
                'Note: rounded-bottom volume includes an estimated ~5% '
                'reduction for the curved base — treat it as an approximation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Saved to your measurement history.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Did you measure this pot yourself?',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your measurements so we can be more accurate '
                      'next time!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.tune),
                      label: const Text('Calibrate accuracy'),
                      onPressed: _openCalibrationScreen,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Measure another pot'),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
