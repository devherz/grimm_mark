import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';

class BudgetDonutChart extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetDonutChart({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAllocated = budgets.fold(0.0, (sum, b) => sum + b.allocatedBudget);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    if (totalAllocated == 0 || budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: CustomPaint(
            painter: _DonutPainter(budgets: budgets, totalAllocated: totalAllocated),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Budget Total',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(totalAllocated),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend List
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: budgets.map((b) {
            final percentage = (b.allocatedBudget / totalAllocated * 100).toStringAsFixed(0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${b.title} ($percentage%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Budget> budgets;
  final double totalAllocated;

  _DonutPainter({required this.budgets, required this.totalAllocated});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (var b in budgets) {
      final sweepAngle = (b.allocatedBudget / totalAllocated) * 2 * math.pi;
      paint.color = b.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.04, // slight spacing between arcs
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class BudgetBarChart extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetBarChart({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    if (budgets.isEmpty) return const SizedBox.shrink();

    double maxVal = 0.0;
    for (var b in budgets) {
      if (b.allocatedBudget > maxVal) maxVal = b.allocatedBudget;
      if (b.totalSpent > maxVal) maxVal = b.totalSpent;
    }
    if (maxVal == 0) maxVal = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('Alloué', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('Dépensé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: budgets.map((b) {
            final allocatedRatio = (b.allocatedBudget / maxVal).clamp(0.05, 1.0);
            final spentRatio = (b.totalSpent / maxVal).clamp(0.05, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(b.icon, color: b.color, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Bar 1: Budget Alloué
                  Row(
                    children: [
                      SizedBox(
                        width: 55,
                        child: Text(
                          'Prévu',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: allocatedRatio,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: b.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          currencyFormat.format(b.allocatedBudget),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: b.color),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Bar 2: Dépense Réelle
                  Row(
                    children: [
                      SizedBox(
                        width: 55,
                        child: Text(
                          'Réel',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: spentRatio,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: b.remainingBudget < 0 ? Colors.red : Colors.orange.shade800,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          currencyFormat.format(b.totalSpent),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: b.remainingBudget < 0 ? Colors.red : Colors.orange.shade800,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
