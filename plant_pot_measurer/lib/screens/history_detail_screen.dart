import 'dart:io';

import 'package:flutter/material.dart';

import '../models/measurement_unit.dart';
import '../models/pot_shape.dart';
import '../models/saved_measurement.dart';
import '../widgets/volume_display_widgets.dart';

/// Full detail view for one past measurement, reusing the same volume
/// cards shown right after measuring a pot.
class HistoryDetailScreen extends StatelessWidget {
  final SavedMeasurement measurement;
  final MeasurementUnit unit;

  const HistoryDetailScreen({
    super.key,
    required this.measurement,
    this.unit = MeasurementUnit.centimeters,
  });

  @override
  Widget build(BuildContext context) {
    final volumeCm3 = measurement.volumeCm3;

    return Scaffold(
      appBar: AppBar(title: const Text('Past measurement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (measurement.photoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(measurement.photoPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            DimensionRow(
              label: 'Top diameter',
              valueCm: measurement.topDiameterCm,
              unit: unit,
            ),
            DimensionRow(
              label: 'Bottom diameter',
              valueCm: measurement.bottomDiameterCm,
              unit: unit,
            ),
            DimensionRow(
              label: 'Height',
              valueCm: measurement.heightCm,
              unit: unit,
            ),
            const SizedBox(height: 8),
            Text(
              'Shape: ${measurement.shape.label}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Reference used: ${measurement.referenceObjectName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Text('Volume', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TrueVolumeCard(volumeCm3: volumeCm3),
            const SizedBox(height: 12),
            NurseryVolumeCard(volumeCm3: volumeCm3),
            if (measurement.shape == PotShape.taperedRoundedBottom) ...[
              const SizedBox(height: 12),
              Text(
                'Note: rounded-bottom volume includes an estimated ~5% '
                'reduction for the curved base — treat it as an approximation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
