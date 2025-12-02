import 'package:flutter/material.dart';

class HeaderTitle extends StatelessWidget {
  // 1. Add the required callback function
  final VoidCallback onSignOut;

  const HeaderTitle({
    super.key,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'November 2025',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // 2. Wrap the icon container in an InkWell and attach the function
        InkWell(
          onTap: onSignOut, // <-- Calls the sign-out function
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
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