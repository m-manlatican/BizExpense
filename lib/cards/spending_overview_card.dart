import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:expense_tracker_3_0/widgets/line_chart_painter.dart';
import 'package:flutter/material.dart';

// 🔥 NEW: Enum for Time Ranges
enum ChartTimeRange { day, week, month }

class SpendingOverviewCard extends StatelessWidget {
  final List<double> spendingPoints;
  final List<String> dateLabels;
  // 🔥 NEW: Control parameters
  final ChartTimeRange selectedRange;
  final ValueChanged<ChartTimeRange> onRangeChanged;

  const SpendingOverviewCard({
    super.key,
    required this.spendingPoints,
    required this.dateLabels,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = spendingPoints.isEmpty ? [0.0, 0.0] : spendingPoints;
    
    // Calculate trend (Last point vs First point)
    final double growth = points.last - points.first;
    final bool isUp = growth >= 0;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              // Trend Indicator
              Row(
                children: [
                  Icon(
                    isUp ? Icons.trending_up : Icons.trending_down, 
                    size: 18, 
                    color: isUp ? Colors.green : Colors.red
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUp ? "Up" : "Down",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  )
                ],
              )
            ],
          ),
          
          const SizedBox(height: 16),

          // 🔥 TIME RANGE SELECTOR
          Container(
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildRangeButton("Day", ChartTimeRange.day),
                _buildRangeButton("Week", ChartTimeRange.week),
                _buildRangeButton("Month", ChartTimeRange.month),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Chart Area
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: LineChartPainter(points),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),

          // Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dateLabels.map((label) => Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Helper for the toggle buttons
  Widget _buildRangeButton(String text, ChartTimeRange range) {
    final bool isSelected = range == selectedRange;
    return Expanded(
      child: GestureDetector(
        onTap: () => onRangeChanged(range),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}