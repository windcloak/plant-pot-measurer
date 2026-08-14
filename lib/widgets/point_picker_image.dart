import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Displays a photo and lets the user place two draggable markers on it
/// (e.g. the two edges of a rim, or the two ends of a reference object).
///
/// Point coordinates are reported in *natural image pixel* space (not
/// on-screen pixels), so distances stay consistent no matter how the image
/// happens to be laid out on screen.
///
/// Use a [GlobalKey<PointPickerImageState>] to call [PointPickerImageState.clear]
/// from a parent "Reset" button.
class PointPickerImage extends StatefulWidget {
  final File imageFile;
  final Offset? initialStart;
  final Offset? initialEnd;
  final Color color;
  final String startLabel;
  final String endLabel;
  final ValueChanged<Offset?> onStartChanged;
  final ValueChanged<Offset?> onEndChanged;

  const PointPickerImage({
    super.key,
    required this.imageFile,
    required this.onStartChanged,
    required this.onEndChanged,
    this.initialStart,
    this.initialEnd,
    this.color = Colors.redAccent,
    this.startLabel = 'A',
    this.endLabel = 'B',
  });

  @override
  State<PointPickerImage> createState() => PointPickerImageState();
}

class PointPickerImageState extends State<PointPickerImage> {
  static const double _loupeSize = 120;
  static const double _loupeZoom = 2.5;
  static const double _markerRadius = 14;

  Size? _naturalSize;
  Offset? _start; // natural image pixel coordinates
  Offset? _end;
  Offset? _dragLocalPos; // display-space, drives the magnifier while dragging

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _resolveNaturalSize();
  }

  void _resolveNaturalSize() {
    final provider = FileImage(widget.imageFile);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _naturalSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  /// Clears both points. Callable from a parent widget via a GlobalKey.
  void clear() {
    setState(() {
      _start = null;
      _end = null;
    });
    widget.onStartChanged(null);
    widget.onEndChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final naturalSize = _naturalSize;
    if (naturalSize == null) {
      return const AspectRatio(
        aspectRatio: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displayWidth = constraints.maxWidth;
        final scale = displayWidth / naturalSize.width;
        final displayHeight = naturalSize.height * scale;

        Offset? startDisplay = _start == null ? null : _start! * scale;
        Offset? endDisplay = _end == null ? null : _end! * scale;

        return SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTap(details.localPosition, scale),
                child: Image.file(
                  widget.imageFile,
                  width: displayWidth,
                  height: displayHeight,
                  fit: BoxFit.fill,
                ),
              ),
              if (startDisplay != null && endDisplay != null)
                CustomPaint(
                  size: Size(displayWidth, displayHeight),
                  painter: _LinePainter(startDisplay, endDisplay, widget.color),
                ),
              if (startDisplay != null)
                _buildMarker(
                  startDisplay,
                  widget.startLabel,
                  scale,
                  displayWidth,
                  displayHeight,
                  isStart: true,
                ),
              if (endDisplay != null)
                _buildMarker(
                  endDisplay,
                  widget.endLabel,
                  scale,
                  displayWidth,
                  displayHeight,
                  isStart: false,
                ),
              if (_dragLocalPos != null)
                _buildLoupe(_dragLocalPos!, displayWidth, displayHeight),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPos, double scale) {
    // Placing new points only happens via tap when a point slot is empty.
    // Once both are placed, adjust by dragging the marker handles instead.
    setState(() {
      if (_start == null) {
        _start = localPos / scale;
        widget.onStartChanged(_start);
      } else if (_end == null) {
        _end = localPos / scale;
        widget.onEndChanged(_end);
      }
    });
  }

  Widget _buildMarker(
    Offset displayPos,
    String label,
    double scale,
    double displayWidth,
    double displayHeight, {
    required bool isStart,
  }) {
    return Positioned(
      left: displayPos.dx - _markerRadius,
      top: displayPos.dy - _markerRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            _dragLocalPos = displayPos;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final updated = (displayPos + details.delta);
            final clamped = Offset(
              updated.dx.clamp(0, displayWidth).toDouble(),
              updated.dy.clamp(0, displayHeight).toDouble(),
            );
            if (isStart) {
              _start = clamped / scale;
              widget.onStartChanged(_start);
            } else {
              _end = clamped / scale;
              widget.onEndChanged(_end);
            }
            _dragLocalPos = clamped;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _dragLocalPos = null;
          });
        },
        child: Container(
          width: _markerRadius * 2,
          height: _markerRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.85),
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoupe(
    Offset localPos,
    double displayWidth,
    double displayHeight,
  ) {
    // Position the loupe above the finger so it isn't covered by it; flip
    // below if too close to the top edge.
    const offsetAbove = _loupeSize * 0.9;
    double loupeTop = localPos.dy - offsetAbove - _loupeSize / 2;
    if (loupeTop < 0) {
      loupeTop = localPos.dy + offsetAbove - _loupeSize / 2;
    }
    final maxLoupeLeft = math.max(0.0, displayWidth - _loupeSize);
    double loupeLeft = (localPos.dx - _loupeSize / 2)
        .clamp(0, maxLoupeLeft)
        .toDouble();

    final zoomedWidth = displayWidth * _loupeZoom;
    final zoomedHeight = displayHeight * _loupeZoom;
    final centerX = localPos.dx * _loupeZoom;
    final centerY = localPos.dy * _loupeZoom;

    return Positioned(
      left: loupeLeft,
      top: loupeTop,
      child: ClipOval(
        child: Container(
          width: _loupeSize,
          height: _loupeSize,
          color: Colors.black,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: _loupeSize / 2 - centerX,
                top: _loupeSize / 2 - centerY,
                child: Image.file(
                  widget.imageFile,
                  width: zoomedWidth,
                  height: zoomedHeight,
                  fit: BoxFit.fill,
                ),
              ),
              // Crosshair marking the exact target point.
              Center(
                child: Container(
                  width: 2,
                  height: _loupeSize,
                  color: widget.color.withValues(alpha: 0.9),
                ),
              ),
              Center(
                child: Container(
                  width: _loupeSize,
                  height: 2,
                  color: widget.color.withValues(alpha: 0.9),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _LinePainter(this.start, this.end, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}
