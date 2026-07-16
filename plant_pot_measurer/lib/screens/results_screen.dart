import 'package:flutter/material.dart';

import '../models/measurement_session.dart';
import '../models/pot_shape.dart';
import '../services/measurement_history_store.dart';
import '../utils/volume_calculator.dart';
import '../widgets/volume_display_widgets.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final MeasurementSession session;

  const ResultsScreen({super.key, required this.session});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    if (!widget.session.isReadyForResults) return;
    try {
      await MeasurementHistoryStore.add(widget.session);
    } catch (_) {
      // History is a convenience feature — a failed save shouldn't block
      // the user from seeing their results.
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
            DimensionRow(label: 'Top diameter', valueCm: topD),
            DimensionRow(label: 'Bottom diameter', valueCm: bottomD),
            DimensionRow(label: 'Height', valueCm: h),
            const SizedBox(height: 8),
            Text(
              'Shape: ${session.shape.label}',
              style: Theme.of(context).textTheme.bodyMedium,
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
            const SizedBox(height: 32),
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
