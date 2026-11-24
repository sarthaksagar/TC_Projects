import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CustomDonutChart extends StatelessWidget {
  final int passed;
  final int failed;
  final int blocked;

  const CustomDonutChart({
    super.key,
    required this.passed,
    required this.failed,
    required this.blocked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final total = passed + failed + blocked;
    final completionRate = total == 0 ? 100.0 : ((passed + failed) / total) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _DonutChartPainter(
                      passed: passed.toDouble(),
                      failed: failed.toDouble(),
                      blocked: blocked.toDouble(),
                      total: max(1.0, total.toDouble()),
                      isDark: isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${completionRate.toInt()}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double passed;
  final double failed;
  final double blocked;
  final double total;
  final bool isDark;

  _DonutChartPainter({
    required this.passed,
    required this.failed,
    required this.blocked,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 14;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    canvas.drawCircle(center, radius, bgPaint);

    final passedSweep = (passed / total) * 2 * pi;
    final failedSweep = (failed / total) * 2 * pi;
    final blockedSweep = (blocked / total) * 2 * pi;

    double startAngle = -pi / 2;

    final passedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF046A38); // Deep Emerald Green

    if (passedSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        passedSweep,
        false,
        passedPaint,
      );
      startAngle += passedSweep;
    }

    if (failedSweep > 0) {
      final failedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.failed;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        failedSweep,
        false,
        failedPaint,
      );
      startAngle += failedSweep;
    }

    if (blockedSweep > 0) {
      final blockedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.secondary;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        blockedSweep,
        false,
        blockedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class CustomChart extends StatelessWidget {
  final String title;

  const CustomChart({
    super.key,
    required this.title,
    dynamic trends,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Last 30 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _WavyBezierChartPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavyBezierChartPainter extends CustomPainter {
  final bool isDark;

  _WavyBezierChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;

    final points = [
      Offset(0, height * 0.70),
      Offset(width * 0.15, height * 0.60),
      Offset(width * 0.30, height * 0.45),
      Offset(width * 0.45, height * 0.75),
      Offset(width * 0.60, height * 0.25),
      Offset(width * 0.75, height * 0.80),
      Offset(width * 0.90, height * 0.15),
      Offset(width, height * 0.40),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.25),
        AppColors.primary.withValues(alpha: 0.02),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _WavyBezierChartPainter oldDelegate) => false;
}

