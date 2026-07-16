import 'dart:io';

import 'package:flutter/material.dart';

import '../models/saved_measurement.dart';
import '../services/measurement_history_store.dart';
import '../utils/volume_calculator.dart';
import 'history_detail_screen.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatTimestamp(DateTime dt) {
  final month = _months[dt.month - 1];
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour < 12 ? 'AM' : 'PM';
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$month ${dt.day}, ${dt.year} · $hour12:$minute $period';
}

/// Lists past measurements, newest first, so the user can look back at
/// pots they've measured before. Swipe an entry to delete it.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SavedMeasurement>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await MeasurementHistoryStore.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _delete(SavedMeasurement item) async {
    setState(() => _items = _items?.where((m) => m.id != item.id).toList());
    await MeasurementHistoryStore.remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      appBar: AppBar(title: const Text('Measurement history')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No measurements yet. Measure a pot and it\'ll show up '
                  'here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final gallons = VolumeCalculator.cm3ToUsGallons(
                  item.volumeCm3,
                );

                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => _delete(item),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: item.photoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(item.photoPath!),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.local_florist, size: 40),
                              ),
                            )
                          : const Icon(Icons.local_florist, size: 40),
                      title: Text(
                        '${item.topDiameterCm.toStringAsFixed(1)} × '
                        '${item.bottomDiameterCm.toStringAsFixed(1)} × '
                        '${item.heightCm.toStringAsFixed(1)} cm',
                      ),
                      subtitle: Text(_formatTimestamp(item.timestamp)),
                      trailing: Text(
                        '${gallons.toStringAsFixed(1)} gal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoryDetailScreen(measurement: item),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
