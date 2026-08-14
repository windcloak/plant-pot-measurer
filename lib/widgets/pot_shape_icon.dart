import 'package:flutter/material.dart';

import '../models/pot_shape.dart';

/// A tiny line-art side-view diagram of a pot shape (open rim ellipse at
/// top, tapered or straight sides, flat or rounded base), used to help
/// the user pick the closest match on the shape-selection screen.
class PotShapeIcon extends StatelessWidget {
  final PotShape shape;
  final double size;
  final Color? color;

  const PotShapeIcon({super.key, required this.shape, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    return CustomPaint(
      size: Size(size, size),
      painter: _PotShapePainter(shape: shape, color: resolvedColor),
    );
  }
}

class _PotShapePainter extends CustomPainter {
  final PotShape shape;
  final Color color;

  _PotShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final topY = h * 0.26;
    final bottomY = h * 0.82;

    final rimHalfWidth = w * 0.36;
    final baseHalfWidth = shape == PotShape.cylinder ? rimHalfWidth : w * 0.20;

    // Open rim, drawn as an ellipse viewed slightly from above.
    final rimRect = Rect.fromCenter(
      center: Offset(centerX, topY),
      width: rimHalfWidth * 2,
      height: h * 0.14,
    );
    canvas.drawOval(rimRect, strokePaint);

    final topLeft = Offset(centerX - rimHalfWidth, topY);
    final topRight = Offset(centerX + rimHalfWidth, topY);
    final bottomLeft = Offset(centerX - baseHalfWidth, bottomY);
    final bottomRight = Offset(centerX + baseHalfWidth, bottomY);

    final sidesPath = Path()..moveTo(topLeft.dx, topLeft.dy);
    sidesPath.lineTo(bottomLeft.dx, bottomLeft.dy);

    if (shape == PotShape.taperedRoundedBottom) {
      // A gentle curve between the base corners instead of a flat base,
      // to suggest a rounded bottom edge.
      sidesPath.quadraticBezierTo(
        centerX,
        bottomY + h * 0.10,
        bottomRight.dx,
        bottomRight.dy,
      );
    } else {
      sidesPath.lineTo(bottomRight.dx, bottomRight.dy);
    }
    sidesPath.lineTo(topRight.dx, topRight.dy);

    canvas.drawPath(sidesPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PotShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
