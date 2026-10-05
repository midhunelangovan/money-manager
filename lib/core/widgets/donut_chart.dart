import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DonutSegment {
  final String? categoryId;
  final String label;
  final double value;
  final Color color;
  final double percentage;
  final IconData? iconData;

  const DonutSegment({
    this.categoryId,
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
    this.iconData,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerAmount;
  final String? centerLabel;
  final double size;
  final double strokeWidth;
  final bool isEmpty;
  final String emptyMessage;
  final ValueChanged<DonutSegment>? onSegmentTapped;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerAmount,
    this.centerLabel,
    this.size = 200,
    this.strokeWidth = 22,
    this.isEmpty = false,
    this.emptyMessage = 'There were no transactions in this period',
    this.onSegmentTapped,
  });

  void _handleTap(TapUpDetails details) {
    if (isEmpty || segments.isEmpty || onSegmentTapped == null) return;

    final center = Offset(size / 2, size / 2);
    final localPos = details.localPosition;
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius = size / 2;
    final innerRadius = outerRadius - strokeWidth;

    // Allow tap anywhere in ring or slightly generous touch target
    if (distance < innerRadius - 12 || distance > outerRadius + 12) {
      return;
    }

    // Angle in radians from 12 o'clock (-pi/2) going clockwise [0, 2*pi)
    double angle = math.atan2(dy, dx);
    // Convert to angle starting at -pi/2
    double relAngle = angle - (-math.pi / 2);
    while (relAngle < 0) {
      relAngle += 2 * math.pi;
    }
    while (relAngle >= 2 * math.pi) {
      relAngle -= 2 * math.pi;
    }

    final totalValue = segments.fold<double>(0.0, (sum, s) => sum + s.value);
    if (totalValue <= 0) return;

    double accumulatedAngle = 0.0;
    for (final segment in segments) {
      final sweepAngle = (segment.value / totalValue) * 2 * math.pi;
      if (relAngle >= accumulatedAngle && relAngle < (accumulatedAngle + sweepAngle)) {
        onSegmentTapped!(segment);
        return;
      }
      accumulatedAngle += sweepAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTapUp: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Painted Donut Ring
              CustomPaint(
                size: Size(size, size),
                painter: _DonutChartPainter(
                  segments: segments,
                  strokeWidth: strokeWidth,
                  isDark: isDark,
                  isEmpty: isEmpty,
                ),
              ),

              // Center Content (Total Amount + Label / Empty Text)
              Padding(
                padding: EdgeInsets.all(strokeWidth + 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isEmpty) ...[
                      Icon(
                        Icons.circle_outlined,
                        size: 28,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      if (centerLabel != null) ...[
                        Text(
                          centerLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerAmount,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final bool isDark;
  final bool isEmpty;

  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.isDark,
    required this.isEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2838) : const Color(0xFFE8EEEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (isEmpty || segments.isEmpty) {
      return;
    }

    final totalValue = segments.fold<double>(0.0, (sum, s) => sum + s.value);
    if (totalValue <= 0) return;

    double startAngle = -math.pi / 2; // Start from 12 o'clock
    const double gapAngle = 0.03; // small subtle separation gap between segments

    for (final segment in segments) {
      final sweepAngle = (segment.value / totalValue) * 2 * math.pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = segments.length == 1 ? StrokeCap.round : StrokeCap.butt;

      final actualSweep = segments.length > 1 ? math.max(0.01, sweepAngle - gapAngle) : sweepAngle;
      final actualStart = segments.length > 1 ? startAngle + (gapAngle / 2) : startAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        actualStart,
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isEmpty != isEmpty;
  }
}
