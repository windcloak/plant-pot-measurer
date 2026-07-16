import 'package:flutter/material.dart';

import '../utils/nursery_gallon_converter.dart';
import '../utils/volume_calculator.dart';

const _cmToInch = 1 / 2.54;

/// A single "label: value in cm (value in in)" row, used for top/bottom
/// diameter and height. Shared by the results screen and the history
/// detail screen.
class DimensionRow extends StatelessWidget {
  final String label;
  final double valueCm;

  const DimensionRow({super.key, required this.label, required this.valueCm});

  @override
  Widget build(BuildContext context) {
    final inches = valueCm * _cmToInch;
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
class TrueVolumeCard extends StatelessWidget {
  final double volumeCm3;

  const TrueVolumeCard({super.key, required this.volumeCm3});

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
            Text('Regular volume', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(
              '${gallons.toStringAsFixed(2)} gal',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
class NurseryVolumeCard extends StatelessWidget {
  final double volumeCm3;

  const NurseryVolumeCard({super.key, required this.volumeCm3});

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
            Text('Nursery pot size', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(
              '≈ #${tradeGallons.round()} (${tradeGallons.toStringAsFixed(1)} trade gal)',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
