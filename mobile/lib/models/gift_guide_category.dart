import 'package:flutter/material.dart';

/// Gift guide category model
/// Represents a category for organizing gift guides (e.g., Christmas, For Her, Under $50)
class GiftGuideCategory {
  final String slug;
  final String name;
  final String emoji;
  final Color color;
  final String group; // 'shopping', 'occasion', 'recipient', 'price_style'
  final String? description;

  GiftGuideCategory({
    required this.slug,
    required this.name,
    required this.emoji,
    required this.color,
    required this.group,
    this.description,
  });

  /// Create from JSON response
  factory GiftGuideCategory.fromJson(Map<String, dynamic> json) {
    return GiftGuideCategory(
      slug: json['slug'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      color: _parseColor(json['color'] as String),
      group: json['group'] as String,
      description: json['description'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'emoji': emoji,
      'color': _colorToHex(color),
      'group': group,
      'description': description,
    };
  }

  /// Parse hex color string to Color
  static Color _parseColor(String hexColor) {
    // Remove # if present
    final hex = hexColor.replaceAll('#', '');
    // Parse as ARGB (add FF for full opacity)
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Convert Color to hex string
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  String toString() {
    return 'GiftGuideCategory(slug: $slug, name: $name, group: $group)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GiftGuideCategory && other.slug == slug;
  }

  @override
  int get hashCode => slug.hashCode;
}
