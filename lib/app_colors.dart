import 'package:flutter/material.dart';

class AppColors {
  // 🔥 THEME BASE: "Cloud Dancer" (Pantone 11-4201 approx)
  // We use this for the background to give that airy, 2026 feel.
  static const Color background = Color(0xFFF0EEE9); 

  // 🔥 THE PARTNER: "Deep Spruce" 
  // A rich, dark teal that grounds the airy background. 
  // Represents wealth, stability, and modern luxury.
  static const Color primary = Color(0xFF264653); 
  
  // Secondary / Accents
  // A soft sand/gold for subtle highlights
  static const Color secondary = Color(0xFFE9C46A); 
  static const Color accent = Color(0xFF2A9D8F); // Lighter Teal for interactions

  // Surfaces (Cards)
  // Pure white cards pop beautifully against the Cloud Dancer background
  static const Color surface = Colors.white;

  // Semantic Colors (Status)
  static const Color success = Color(0xFF2A9D8F); // Sage/Teal Green (Money in)
  static const Color expense = Color(0xFFE76F51); // Terracotta/Soft Coral (Money out)
  static const Color warning = Color(0xFFF4A261); // Muted Orange

  // Typography
  // Dark Charcoal instead of Black for a softer read
  static const Color textPrimary = Color(0xFF2B2D42); 
  static const Color textSecondary = Color(0xFF8D99AE); 
}