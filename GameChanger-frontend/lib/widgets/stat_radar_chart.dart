import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;


class StatRadarChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String title;
  final Color chartColor;
  final List<String> statLabels;
  final List<String> statKeys;
 
  const StatRadarChart({
    Key? key,
    required this.stats,
    required this.title,
    required this.chartColor,
    required this.statLabels,
    required this.statKeys,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 300,
                    child: _buildRadarChart(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildRatingTable(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: List.generate(
                math.min(statLabels.length, statKeys.length),
                (index) => _buildLegendItem(
                  statLabels[index],
                  _getStatValue(statKeys[index]),
                  chartColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRadarChart() {
    return CustomPaint(
      size: const Size(300, 300),
      painter: HexagonChartPainter(
        stats: _getNormalizedValues(),
        labels: statLabels,
        color: chartColor,
      ),
    );
  }
 
  List<double> _getNormalizedValues() {
    final List<double> normalizedValues = [];
    final bool isDefensive = title.toLowerCase().contains('defensive');
   
    for (int i = 0; i < statKeys.length; i++) {
      final key = statKeys[i];
      final value = _getStatValue(key);
      final rating = _getRating(key, value);
     
      // Use rating to determine the normalized value
      double normalizedValue = 0.0;
     
      switch (rating) {
        case 'S': normalizedValue = 0.9; break;
        case 'A': normalizedValue = 0.7; break;
        case 'B': normalizedValue = 0.5; break;
        case 'C': normalizedValue = 0.3; break;
        case 'D': normalizedValue = 0.15; break;
        default: normalizedValue = 0.15;
      }
     
      normalizedValues.add(normalizedValue);
    }
   
    return normalizedValues;
  }
 
  Widget _buildRatingTable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Ratings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: math.min(statLabels.length, statKeys.length),
              itemBuilder: (context, index) {
                final label = statLabels[index];
                final key = statKeys[index];
                final value = _getStatValue(key);
                final rating = _getRating(key, value);
                final ratingColor = _getRatingColor(rating);
               
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: ratingColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildLegendItem(String label, double value, Color color) {
    String displayValue;
   
    // Format the value based on the type of stat
    if (label.contains('%')) {
      displayValue = '${(value * 100).toStringAsFixed(1)}%';
    } else {
      displayValue = value.toStringAsFixed(1);
    }
   
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
       Text(
  '$label: $displayValue',
  style: GoogleFonts.poppins(
    fontSize: 12,
  ),
),
      ],
    );
  }
 
  double _getStatValue(String key) {
    if (stats.containsKey(key)) {
      final value = stats[key];
      if (value is num) {
        return value.toDouble();
      }
    }
    return 0.0;
  }
 
  String _getRating(String key, double value) {
    if (key.contains('pct')) {
      // Percentages
      if (value >= 0.45) return 'S';
      if (value >= 0.40) return 'A';
      if (value >= 0.35) return 'B';
      if (value >= 0.30) return 'C';
      return 'D';
    } else if (key == 'points_per_game') {
      // Points per game
      if (value >= 115) return 'S';
      if (value >= 110) return 'A';
      if (value >= 105) return 'B';
      if (value >= 100) return 'C';
      return 'D';
    } else if (key == 'opponent_points_per_game') {
      // Opponent points (lower is better)
      if (value <= 100) return 'S';
      if (value <= 105) return 'A';
      if (value <= 110) return 'B';
      if (value <= 115) return 'C';
      return 'D';
    } else if (key.contains('assists')) {
      // Assists
      if (value >= 27) return 'S';
      if (value >= 25) return 'A';
      if (value >= 23) return 'B';
      if (value >= 20) return 'C';
      return 'D';
    } else if (key.contains('rebounds')) {
      // Rebounds
      if (value >= 12) return 'S';
      if (value >= 10) return 'A';
      if (value >= 8) return 'B';
      if (value >= 6) return 'C';
      return 'D';
    } else if (key.contains('blocks')) {
      // Blocks
      if (value >= 6) return 'S';
      if (value >= 5) return 'A';
      if (value >= 4) return 'B';
      if (value >= 3) return 'C';
      return 'D';
    } else if (key.contains('steals')) {
      // Steals
      if (value >= 9) return 'S';
      if (value >= 8) return 'A';
      if (value >= 7) return 'B';
      if (value >= 6) return 'C';
      return 'D';
    } else if (key.contains('offensive_rating')) {
      // Offensive rating
      if (value >= 115) return 'S';
      if (value >= 110) return 'A';
      if (value >= 105) return 'B';
      if (value >= 100) return 'C';
      return 'D';
    } else if (key.contains('defensive_rating')) {
      // Defensive rating (lower is better)
      if (value <= 105) return 'S';
      if (value <= 108) return 'A';
      if (value <= 112) return 'B';
      if (value <= 115) return 'C';
      return 'D';
    } else if (key == 'pace') {
      // Pace - more neutral rating
      if (value >= 103) return 'A';
      if (value >= 98) return 'B';
      if (value >= 93) return 'C';
      return 'D';
    } else {
      // Default
      if (value >= 80) return 'S';
      if (value >= 70) return 'A';
      if (value >= 60) return 'B';
      if (value >= 50) return 'C';
      return 'D';
    }
  }
 
  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'S': return Colors.purple.shade700;
      case 'A': return Colors.blue.shade700;
      case 'B': return Colors.green.shade600;
      case 'C': return Colors.orange.shade600;
      case 'D': return Colors.red.shade600;
      default: return Colors.grey.shade600;
    }
  }
}


class HexagonChartPainter extends CustomPainter {
  final List<double> stats;
  final List<String> labels;
  final Color color;
 
  HexagonChartPainter({
    required this.stats,
    required this.labels,
    required this.color,
  });
 
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;
   
    // Draw axes
    _drawAxes(canvas, center, radius);
   
    // Draw labels
    _drawLabels(canvas, center, radius);
   
    // Draw data polygon
    _drawDataPolygon(canvas, center, radius);
  }
 
  void _drawAxes(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
   
    // Draw concentric hexagons for scale
    for (int i = 1; i <= 4; i++) {
      final scaledRadius = radius * i / 4;
      final path = Path();
     
      for (int j = 0; j < math.min(stats.length, 6); j++) {
        final angle = j * 2 * math.pi / math.min(stats.length, 6);
        final x = center.dx + scaledRadius * math.cos(angle - math.pi / 2);
        final y = center.dy + scaledRadius * math.sin(angle - math.pi / 2);
       
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
     
      path.close();
      canvas.drawPath(path, paint);
    }
   
    // Draw axes lines
    for (int i = 0; i < math.min(stats.length, 6); i++) {
      final angle = i * 2 * math.pi / math.min(stats.length, 6);
      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);
     
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }
 
  void _drawLabels(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < math.min(labels.length, 6); i++) {
      final angle = i * 2 * math.pi / math.min(labels.length, 6);
      final labelRadius = radius + 20;
      final x = center.dx + labelRadius * math.cos(angle - math.pi / 2);
      final y = center.dy + labelRadius * math.sin(angle - math.pi / 2);
     
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
     
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }
 
  void _drawDataPolygon(Canvas canvas, Offset center, double radius) {
    if (stats.isEmpty) return;
   
    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
   
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
   
    final path = Path();
   
    for (int i = 0; i < math.min(stats.length, 6); i++) {
      final angle = i * 2 * math.pi / math.min(stats.length, 6);
      final value = stats[i];
      final scaledRadius = radius * value;
      final x = center.dx + scaledRadius * math.cos(angle - math.pi / 2);
      final y = center.dy + scaledRadius * math.sin(angle - math.pi / 2);
     
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
     
      // Draw data points
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
   
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
 
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



