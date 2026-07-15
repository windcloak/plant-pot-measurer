import 'package:flutter/material.dart';

import '../models/measurement_session.dart';
import '../widgets/point_picker_image.dart';
import 'shape_select_screen.dart';

class _Step {
  final String title;
  final String instructions;
  final Color color;
  final String startLabel;
  final String endLabel;

  const _Step({
    required this.title,
    required this.instructions,
    required this.color,
    this.startLabel = 'A',
    this.endLabel = 'B',
  });
}

/// Walks the user through four tap-two-points measurements on the same
/// photo: calibration reference, top rim diameter, bottom rim diameter,
/// and height.
class AnnotateFlowScreen extends StatefulWidget {
  final MeasurementSession session;

  const AnnotateFlowScreen({super.key, required this.session});

  @override
  State<AnnotateFlowScreen> createState() => _AnnotateFlowScreenState();
}

class _AnnotateFlowScreenState extends State<AnnotateFlowScreen> {
  int _stepIndex = 0;
  final List<GlobalKey<PointPickerImageState>> _pickerKeys = List.generate(
    4,
    (_) => GlobalKey<PointPickerImageState>(),
  );

  late final List<_Step> _steps = [
    _Step(
      title: 'Calibrate: reference object',
      instructions:
          'Tap the two ends of your reference object '
          '(${widget.session.referenceObject.name}) in the photo.',
      color: Colors.amber.shade700,
      startLabel: '1',
      endLabel: '2',
    ),
    const _Step(
      title: 'Top rim diameter',
      instructions:
          'Tap the two outer edges of the pot\'s top opening, straight '
          'across the widest point.',
      color: Colors.lightBlue,
      startLabel: 'L',
      endLabel: 'R',
    ),
    const _Step(
      title: 'Bottom diameter',
      instructions:
          'Tap the two outer edges of the pot\'s base, straight across.',
      color: Colors.teal,
      startLabel: 'L',
      endLabel: 'R',
    ),
    const _Step(
      title: 'Height',
      instructions:
          'Tap the top rim, then the bottom of the pot, to mark its height.',
      color: Colors.deepPurple,
      startLabel: 'Top',
      endLabel: 'Bottom',
    ),
  ];

  PointPair _pairFor(int index) {
    switch (index) {
      case 0:
        return widget.session.calibration;
      case 1:
        return widget.session.topDiameter;
      case 2:
        return widget.session.bottomDiameter;
      default:
        return widget.session.height;
    }
  }

  void _goNext() {
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShapeSelectScreen(session: widget.session),
        ),
      );
    }
  }

  void _goBack() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final pair = _pairFor(_stepIndex);
    final photo = widget.session.photo;

    if (photo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Measure')),
        body: const Center(child: Text('No photo found. Please go back.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(step.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            tooltip: 'Reset points',
            icon: const Icon(Icons.refresh),
            onPressed: () => _pickerKeys[_stepIndex].currentState?.clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_stepIndex + 1) / _steps.length,
              minHeight: 3,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(
                step.instructions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: PointPickerImage(
                    key: _pickerKeys[_stepIndex],
                    imageFile: photo,
                    color: step.color,
                    startLabel: step.startLabel,
                    endLabel: step.endLabel,
                    initialStart: pair.start,
                    initialEnd: pair.end,
                    onStartChanged: (p) => setState(() => pair.start = p),
                    onEndChanged: (p) => setState(() => pair.end = p),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: pair.isComplete ? _goNext : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _stepIndex == _steps.length - 1
                        ? 'Continue to shape & volume'
                        : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
