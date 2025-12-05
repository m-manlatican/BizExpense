import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';

class Branding extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color? color;
  final bool vertical; // Layout mode (Column vs Row)

  const Branding({
    super.key,
    this.iconSize = 48,
    this.fontSize = 32,
    this.color,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;

    // Logo Icon: Heart in Hand (closest to your reference image)
    final logo = Container(
      padding: EdgeInsets.all(iconSize * 0.25),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.volunteer_activism_rounded, 
        size: iconSize, 
        color: themeColor,
      ),
    );

    final title = Text(
      "BizExpense",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: themeColor,
        letterSpacing: -0.5,
        fontFamily: 'Roboto', 
      ),
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          const SizedBox(height: 16),
          title,
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          const SizedBox(width: 12),
          title,
        ],
      );
    }
  }
}