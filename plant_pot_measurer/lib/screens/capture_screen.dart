import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/measurement_session.dart';
import '../models/measurement_unit.dart';
import '../models/reference_object.dart';
import '../services/calibration_store.dart';
import '../services/custom_reference_store.dart';
import '../services/last_reference_store.dart';
import '../services/unit_preference_store.dart';
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
  final _customNameController = TextEditingController();

  /// Null means "nothing selected yet" — the dropdown shows a
  /// "Select a reference object" hint until the user picks one, or until
  /// a remembered last-used reference finishes loading.
  ReferenceObject? _selectedReference;
  List<ReferenceObject> _savedReferences = [];
  bool _saveCustomForLater = true;
  bool _isPicking = false;
  MeasurementUnit _unit = UnitPreferenceStore.defaultUnit;

  @override
  void initState() {
    super.initState();
    _loadSavedReferences();
    _loadCorrectionFactor();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final unit = await UnitPreferenceStore.load();
    if (!mounted) return;
    setState(() => _unit = unit);
  }

  Future<void> _loadSavedReferences() async {
    final saved = await CustomReferenceStore.load();
    final lastUsed = await LastReferenceStore.load(saved);
    if (!mounted) return;
    setState(() {
      _savedReferences = saved;
      _selectedReference = lastUsed;
    });
  }

  Future<void> _loadCorrectionFactor() async {
    final factor = await CalibrationStore.load();
    widget.session.correctionFactor = factor;
  }

  @override
  void dispose() {
    _customLengthController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  /// Raw value the user typed, in the current display unit (not cm).
  double? get _enteredCustomLength =>
      double.tryParse(_customLengthController.text);

  /// The entered custom length converted to centimeters, ready to store.
  double? get _customLengthCm {
    final entered = _enteredCustomLength;
    return entered == null ? null : _unit.toCm(entered);
  }

  bool get _canProceed {
    final selected = _selectedReference;
    if (selected == null) return false;
    if (!selected.isCustom) return true;
    if ((_customLengthCm ?? 0) <= 0) return false;
    if (_saveCustomForLater) {
      return _customNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _showManageSavedReferences() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Saved reference objects',
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: _savedReferences.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No saved reference objects yet.'),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final ref in _savedReferences)
                                  ListTile(
                                    leading: const Icon(Icons.bookmark_outline),
                                    title: Text(ref.name),
                                    subtitle: Text(
                                      '${_unit.fromCm(ref.lengthCm).toStringAsFixed(2)} '
                                      '${_unit.abbreviation}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        await CustomReferenceStore.remove(
                                          ref.id!,
                                        );
                                        setState(() {
                                          _savedReferences = _savedReferences
                                              .where((r) => r.id != ref.id)
                                              .toList();
                                          if (_selectedReference?.id ==
                                              ref.id) {
                                            _selectedReference = null;
                                          }
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _takePhoto(ImageSource source) async {
    if (!_canProceed || _isPicking) return;
    final selected = _selectedReference;
    if (selected == null) return;

    var referenceToUse = selected;
    if (selected.isCustom) {
      final length = _customLengthCm;
      if (length == null || length <= 0) return;
      final name = _customNameController.text.trim().isEmpty
          ? 'Custom reference'
          : _customNameController.text.trim();

      if (_saveCustomForLater) {
        referenceToUse = await CustomReferenceStore.add(
          name: name,
          lengthCm: length,
        );
        if (!mounted) return;
        setState(() => _savedReferences = [..._savedReferences, referenceToUse]);
      } else {
        referenceToUse = ReferenceObject(name: name, lengthCm: length);
      }
    }

    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;

      widget.session.resetMeasurementPoints();
      widget.session.referenceObject = referenceToUse;
      widget.session.photo = File(picked.path);
      await LastReferenceStore.save(referenceToUse);
      if (!mounted) return;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Choose a reference object',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_savedReferences.isNotEmpty)
                  TextButton.icon(
                    onPressed: _showManageSavedReferences,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Manage'),
                  ),
              ],
            ),
            Text(
              'You\'ll place this next to the pot in the photo so the app '
              'can convert pixels to real-world measurements.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReferenceObject>(
              key: ValueKey(_selectedReference),
              initialValue: _selectedReference,
              isExpanded: true,
              hint: const Text('Select a reference object'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                ...ReferenceObject.presets
                    .where((ref) => !ref.isCustom)
                    .map(
                      (ref) => DropdownMenuItem(
                        value: ref,
                        child: Text(
                          '${ref.name} — '
                          '${_unit.fromCm(ref.lengthCm).toStringAsFixed(2)} '
                          '${_unit.abbreviation}',
                        ),
                      ),
                    ),
                ..._savedReferences.map(
                  (ref) => DropdownMenuItem(
                    value: ref,
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${ref.name} — '
                            '${_unit.fromCm(ref.lengthCm).toStringAsFixed(2)} '
                            '${_unit.abbreviation}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ReferenceObject.custom,
                  child: Text(ReferenceObject.custom.name),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedReference = value);
              },
            ),
            if (_selectedReference?.isCustom ?? false) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. "My hand span")',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customLengthController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Known length (${_unit.abbreviation})',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _saveCustomForLater,
                title: const Text('Save this reference for future pots'),
                subtitle: const Text(
                  'It\'ll show up in this list next time you measure.',
                ),
                onChanged: (v) => setState(() => _saveCustomForLater = v),
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
