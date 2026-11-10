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
  final bool isLoading;
  final String emptyMessage;
  final ValueChanged<DonutSegment>? onSegmentTapped;
  final VoidCallback? onCenterTapped;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerAmount,
    this.centerLabel,
    this.size = 230,
    this.strokeWidth = 24,
    this.isEmpty = false,
    this.isLoading = false,
    this.emptyMessage = 'There were no expenses in this week',
    this.onSegmentTapped,
    this.onCenterTapped,
  });

  void _handleTap(TapUpDetails details) {
    if (isLoading) return;

    final center = Offset(size / 2, size / 2);
    final localPos = details.localPosition;
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius = size / 2;
    final innerRadius = outerRadius - strokeWidth;

    // Center tapped (inner area)
    if (distance < innerRadius - 8) {
      if (onCenterTapped != null) {
        onCenterTapped!();
      }
      return;
    }

    if (isEmpty || segments.isEmpty || onSegmentTapped == null) return;

    // Allow tap anywhere in ring or slightly generous touch target
    if (distance > outerRadius + 14) {
      return;
    }

    // Angle in radians from 12 o'clock (-pi/2) going clockwise [0, 2*pi)
    double angle = math.atan2(dy, dx);
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
                  isEmpty: isEmpty || isLoading,
                ),
              ),

              // Center Content (Loading / Total Amount + Label / Empty Text)
              Padding(
                padding: EdgeInsets.all(strokeWidth + 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ] else if (isEmpty) ...[
                      Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      if (centerLabel != null) ...[
                        Text(
                          centerLabel!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E95A2),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerAmount,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1B1E24),
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

    // Background track ring in clean subtle border neutral
    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (isEmpty || segments.isEmpty) {
      // Subtle dashed inner circle treatment
      final innerRadius = radius - strokeWidth / 2 - 8;
      if (innerRadius > 0) {
        final dashedPaint = Paint()
          ..color = isDark ? Colors.white12 : AppColors.lightBorderSubtle
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        const double dashAngle = 0.08;
        const double gapAngle = 0.06;
        double curAngle = 0.0;
        final rect = Rect.fromCircle(center: center, radius: innerRadius);
        while (curAngle < 2 * math.pi) {
          canvas.drawArc(rect, curAngle, dashAngle, false, dashedPaint);
          curAngle += dashAngle + gapAngle;
        }
      }
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