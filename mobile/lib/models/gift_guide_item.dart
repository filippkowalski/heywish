/// Gift guide item model
/// Represents an individual gift product within a guide
class GiftGuideItem {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final double? price;
  final String? currency;
  final String url;

  GiftGuideItem({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.price,
    this.currency,
    required this.url,
  });

  /// Create from JSON response
  factory GiftGuideItem.fromJson(Map<String, dynamic> json) {
    return GiftGuideItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      url: json['url'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'price': price,
      'currency': currency,
      'url': url,
    };
  }

  /// Check if item has a valid image
  bool get hasImage => image != null && image!.isNotEmpty;

  /// Check if item has a price
  bool get hasPrice => price != null;

  @override
  String toString() {
    return 'GiftGuideItem(id: $id, title: $title, price: ${price ?? 'N/A'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GiftGuideItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
