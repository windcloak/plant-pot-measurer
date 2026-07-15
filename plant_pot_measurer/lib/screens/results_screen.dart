import 'package:flutter/material.dart';

import '../models/measurement_session.dart';
import '../models/pot_shape.dart';
import '../utils/nursery_gallon_converter.dart';
import '../utils/volume_calculator.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final MeasurementSession session;

  const ResultsScreen({super.key, required this.session});

  static const _cmToInch = 1 / 2.54;

  @override
  Widget build(BuildContext context) {
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
            _DimensionRow(label: 'Top diameter', valueCm: topD),
            _DimensionRow(label: 'Bottom diameter', valueCm: bottomD),
            _DimensionRow(label: 'Height', valueCm: h),
            const SizedBox(height: 8),
            Text('Shape: ${session.shape.label}',
                style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 32),
            Text('Volume', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _TrueVolumeCard(volumeCm3: volumeCm3),
            const SizedBox(height: 12),
            _NurseryVolumeCard(volumeCm3: volumeCm3),
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

class _DimensionRow extends StatelessWidget {
  final String label;
  final double valueCm;

  const _DimensionRow({required this.label, required this.valueCm});

  @override
  Widget build(BuildContext context) {
    final inches = valueCm * ResultsScreen._cmToInch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            '${valueCm.toStringAsFixed(1)} cm  (${inches.toStringAsFixed(1)} in)',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// The pot's actual, physically-measured volume — what it would really
/// hold if you filled it with water. Gallons is the headline unit since
/// that's how gardeners think about pot/soil volume; liters and other
/// units are shown as supporting detail.
class _TrueVolumeCard extends StatelessWidget {
  final double volumeCm3;

  const _TrueVolumeCard({required this.volumeCm3});

  @override
  Widget build(BuildContext context) {
    final gallons = VolumeCalculator.cm3ToUsGallons(volumeCm3);
    final liters = VolumeCalculator.cm3ToLiters(volumeCm3);
    final quarts = VolumeCalculator.cm3ToUsQuarts(volumeCm3);
    final cups = VolumeCalculator.cm3ToUsCups(volumeCm3);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regular volume',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              '${gallons.toStringAsFixed(2)} gal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${liters.toStringAsFixed(2)} L  •  ${volumeCm3.toStringAsFixed(0)} cm³',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('${quarts.toStringAsFixed(1)} qt'),
                Text('${cups.toStringAsFixed(1)} cups'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'True liquid volume — what this pot would hold if filled '
              'with water. Use this for potting soil quantity.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Where this pot lands on the nursery industry's "trade gallon" size
/// scale (the numbers on pots at a garden center), which is a marketing
/// size class rather than a true liquid measurement.
class _NurseryVolumeCard extends StatelessWidget {
  final double volumeCm3;

  const _NurseryVolumeCard({required this.volumeCm3});

  @override
  Widget build(BuildContext context) {
    final trueGallons = VolumeCalculator.cm3ToUsGallons(volumeCm3);
    final tradeGallons = NurseryGallonConverter.tradeGallonsForTrueGallons(
      trueGallons,
    );

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nursery pot size',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              '≈ #${tradeGallons.round()} (${tradeGallons.toStringAsFixed(1)} trade gal)',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Closest nursery/garden-center container size class. Trade '
              '"gallons" are marketing labels, not true liquid gallons — '
              'a nursery #7 pot, for example, holds only about 6.5 true '
              'gallons. This estimate is based on common industry sizing '
              'and can vary by manufacturer.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
