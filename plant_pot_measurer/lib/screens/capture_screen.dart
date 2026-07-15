import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/measurement_session.dart';
import '../models/reference_object.dart';
import 'annotate_flow_screen.dart';

/// Lets the user pick which reference object they'll place next to the pot,
/// then takes (or picks) the photo before moving on to tapping points.
class CaptureScreen extends StatefulWidget {
  final MeasurementSession session;

  const CaptureScreen({super.key, required this.session});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  final _customLengthController = TextEditingController();
  late ReferenceObject _selectedReference;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _selectedReference = widget.session.referenceObject;
  }

  @override
  void dispose() {
    _customLengthController.dispose();
    super.dispose();
  }

  double? get _customLength => double.tryParse(_customLengthController.text);

  bool get _canProceed =>
      !_selectedReference.isCustom || (_customLength ?? 0) > 0;

  Future<void> _takePhoto(ImageSource source) async {
    if (!_canProceed || _isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;

      widget.session.referenceObject = _selectedReference;
      widget.session.customReferenceLengthCm = _customLength;
      widget.session.photo = File(picked.path);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnnotateFlowScreen(session: widget.session),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your reference object')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Choose a reference object',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ll place this next to the pot in the photo so the app '
              'can convert pixels to real-world measurements.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReferenceObject>(
              initialValue: _selectedReference,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ReferenceObject.presets
                  .map(
                    (ref) => DropdownMenuItem(
                      value: ref,
                      child: Text(
                        ref.isCustom
                            ? ref.name
                            : '${ref.name} — ${ref.lengthCm} cm',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedReference = value);
              },
            ),
            if (_selectedReference.isCustom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customLengthController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Known length (cm)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before you take the photo',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Place the reference object flat, touching the pot, '
                      'at the same distance from the camera as the pot\'s '
                      'front edge.\n'
                      '2. Shoot the pot straight-on (not from above or an '
                      'angle) so the top rim, bottom rim, and side are all '
                      'visible.\n'
                      '3. Make sure there\'s good, even light.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Take photo'),
              ),
              onPressed: _canProceed && !_isPicking
                  ? () => _takePhoto(ImageSource.camera)
                  : null,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery instead'),
              onPressed: _canProceed && !_isPicking
                  ? () => _takePhoto(ImageSource.gallery)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
