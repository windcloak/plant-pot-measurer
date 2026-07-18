import 'package:flutter/material.dart';

/// What the user entered on the calibration screen.
class CalibrationInput {
  final double realTop;
  final double realBottom;
  final double realHeight;
  final bool remember;

  const CalibrationInput({
    required this.realTop,
    required this.realBottom,
    required this.realHeight,
    required this.remember,
  });
}

/// Sentinel popped when the user asks to reset calibration to default.
const Object resetCalibrationRequested = Object();

/// A dedicated screen (not a bottom sheet) for entering real-world
/// measurements to calibrate the app's accuracy. Using a normal pushed
/// screen — rather than a modal bottom sheet with several focusable text
/// fields — avoids a Flutter framework crash that can happen when a
/// sheet with focused text fields is popped while its parent rebuilds.
///
/// Pops with a [CalibrationInput], [resetCalibrationRequested], or null
/// (if the user just navigates back without submitting).
class CalibrationScreen extends StatefulWidget {
  final double appTopDiameterCm;
  final double appBottomDiameterCm;
  final double appHeightCm;
  final bool showResetOption;

  const CalibrationScreen({
    super.key,
    required this.appTopDiameterCm,
    required this.appBottomDiameterCm,
    required this.appHeightCm,
    required this.showResetOption,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _topController = TextEditingController();
  final _bottomController = TextEditingController();
  final _heightController = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _submit() {
    final realTop = double.tryParse(_topController.text);
    final realBottom = double.tryParse(_bottomController.text);
    final realHeight = double.tryParse(_heightController.text);
    if (realTop == null ||
        realTop <= 0 ||
        realBottom == null ||
        realBottom <= 0 ||
        realHeight == null ||
        realHeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter all three measurements as positive numbers.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      CalibrationInput(
        realTop: realTop,
        realBottom: realBottom,
        realHeight: realHeight,
        remember: _remember,
      ),
    );
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(resetCalibrationRequested);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrate accuracy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Enter what you measured in real life (e.g. with a ruler or '
              'tape measure) and we\'ll adjust future measurements to '
              'match.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _topController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Actual top diameter (cm)',
                hintText:
                    'App measured ${widget.appTopDiameterCm.toStringAsFixed(1)}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bottomController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Actual bottom diameter (cm)',
                hintText:
                    'App measured ${widget.appBottomDiameterCm.toStringAsFixed(1)}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Actual height (cm)',
                hintText:
                    'App measured ${widget.appHeightCm.toStringAsFixed(1)}',
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _remember,
              title: const Text(
                'Remember this adjustment for future measurements',
              ),
              onChanged: (v) => setState(() => _remember = v ?? true),
            ),
            if (widget.showResetOption)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _reset,
                  child: const Text('Reset calibration to default'),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save calibration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
