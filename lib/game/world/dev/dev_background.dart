import 'dart:ui';

import 'package:flame/components.dart';

/// [DevBackground] renders a tiled grid on the game world so that
/// character movement is clearly visible during development.
///
/// Draws a dark background with lighter grid lines spanning the
/// entire [gridSize] area, centred on the origin.
class DevBackground extends Component {
  /// Creates a [DevBackground].
  ///
  /// [gridSize] is the total width/height of the background area.
  /// [tileSize] is the spacing between grid lines.
  DevBackground({this.gridSize = 2000, this.tileSize = 64});

  /// Total width and height of the background area in pixels.
  final double gridSize;

  /// Spacing between grid lines in pixels.
  final double tileSize;

  //#region Rendering

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final half = gridSize / 2;
    final rect = Rect.fromLTWH(-half, -half, gridSize, gridSize);

    // Dark background fill.
    canvas.drawRect(rect, _backgroundPaint);

    // Grid lines.
    final start = -half;
    final end = half;

    for (var x = start; x <= end; x += tileSize) {
      canvas.drawLine(Offset(x, start), Offset(x, end), _gridPaint);
    }
    for (var y = start; y <= end; y += tileSize) {
      canvas.drawLine(Offset(start, y), Offset(end, y), _gridPaint);
    }

    // Axis cross at origin for reference.
    canvas.drawLine(Offset(-half, 0), Offset(half, 0), _axisPaint);
    canvas.drawLine(Offset(0, -half), Offset(0, half), _axisPaint);
  }

  //#endregion

  //#region Paint objects

  static final Paint _backgroundPaint = Paint()
    ..color = const Color(0xFF1A1A2E);

  static final Paint _gridPaint = Paint()
    ..color = const Color(0xFF2A2A4A)
    ..strokeWidth = 1;

  static final Paint _axisPaint = Paint()
    ..color = const Color(0xFF4A4A6A)
    ..strokeWidth = 2;

  //#endregion
}
