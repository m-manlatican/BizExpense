import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';

class Branding extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color? color;
  final bool vertical; 
  final bool? isLightLogo; 

  const Branding({
    super.key,
    this.iconSize = 48,
    this.fontSize = 32,
    this.color,
    this.vertical = true,
    this.isLightLogo, 
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;

    final bool useLight = isLightLogo ?? (themeColor.computeLuminance() > 0.5);
    
    final String assetName = useLight ? 'assets/logo_light.png' : 'assets/logo_dark.png';

    final logo = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        child: Image.asset(
          assetName, 
          width: iconSize * 1.5,
          height: iconSize * 1.5,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.business_center, size: iconSize, color: themeColor);
          },
        ),
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