import 'package:expense_tracker_3_0/widgets/branding.dart'; // Import Branding
import 'package:flutter/material.dart';

class HeaderTitle extends StatelessWidget {
  final VoidCallback onSignOut;

  const HeaderTitle({
    super.key,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    // Current date logic
    final now = DateTime.now();
    const List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final String dateDisplay = '${months[now.month - 1]} ${now.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔥 REPLACED DASHBOARD TITLE WITH BRANDING
        // Using `vertical: false` to make it a Row (Icon left, Text right)
        const Branding(
          iconSize: 28,
          fontSize: 22,
          color: Colors.white, // White text/icon for dark header
          vertical: false, 
        ),
        
        const Spacer(),

        // Date Display
        Text(
          dateDisplay, 
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),

        // Sign Out Button
        InkWell(
          onTap: onSignOut,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}