import 'gift_guide_item.dart';

/// Gift guide model
/// Represents a curated collection of gift items (e.g., "Christmas Gifts for Her")
class GiftGuide {
  final String slug;
  final String title;
  final String description;
  final String heroImage;
  final String categorySlug;
  final int itemCount;
  final List<String> relatedGuides;
  final List<GiftGuideItem>? items; // null for list view, populated for detail view

  GiftGuide({
    required this.slug,
    required this.title,
    required this.description,
    required this.heroImage,
    required this.categorySlug,
    required this.itemCount,
    required this.relatedGuides,
    this.items,
  });

  /// Create from JSON response
  factory GiftGuide.fromJson(Map<String, dynamic> json) {
    return GiftGuide(
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      heroImage: json['heroImage'] as String,
      categorySlug: json['categorySlug'] as String,
      itemCount: json['itemCount'] as int? ?? 0,
      relatedGuides: (json['relatedGuides'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((item) => GiftGuideItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'title': title,
      'description': description,
      'heroImage': heroImage,
      'categorySlug': categorySlug,
      'itemCount': itemCount,
      'relatedGuides': relatedGuides,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  GiftGuide copyWith({
    String? slug,
    String? title,
    String? description,
    String? heroImage,
    String? categorySlug,
    int? itemCount,
    List<String>? relatedGuides,
    List<GiftGuideItem>? items,
  }) {
    return GiftGuide(
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      heroImage: heroImage ?? this.heroImage,
      categorySlug: categorySlug ?? this.categorySlug,
      itemCount: itemCount ?? this.itemCount,
      relatedGuides: relatedGuides ?? this.relatedGuides,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'GiftGuide(slug: $slug, title: $title, itemCount: $itemCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GiftGuide && other.slug == slug;
  }

  @override
  int get hashCode => slug.hashCode;
}
