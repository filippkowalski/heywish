import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color primaryLight = Color(0xFFE0E7FF); // Indigo-100
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo-600
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  
  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400
  
  // Border and outline colors
  static const Color outline = Color(0xFFE2E8F0); // Slate-200
  static const Color outlineVariant = Color(0xFFF1F5F9); // Slate-100
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF3B82F6); // Blue-500
  
  // Semantic colors
  static const Color divider = Color(0xFFE2E8F0); // Slate-200
  static const Color disabled = Color(0xFFF1F5F9); // Slate-100
  static const Color shadow = Color(0x1A000000); // Black with 10% opacity
  
  // Social colors
  static const Color facebook = Color(0xFF1877F2);
  static const Color google = Color(0xFF4285F4);
  static const Color apple = Color(0xFF000000);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}