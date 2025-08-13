import 'wish.dart';

class Wishlist {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? occasionType;
  final DateTime? eventDate;
  final String visibility;
  final String? shareToken;
  final String? coverImageUrl;
  final int wishCount;
  final int reservedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Wish>? wishes;

  Wishlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.occasionType,
    this.eventDate,
    this.visibility = 'private',
    this.shareToken,
    this.coverImageUrl,
    this.wishCount = 0,
    this.reservedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.wishes,
  });

  bool get isPublic => visibility == 'public';

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'],
      description: json['description'],
      occasionType: json['occasion_type'],
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date']) 
          : null,
      visibility: json['visibility'] ?? 'private',
      shareToken: json['share_token'],
      coverImageUrl: json['cover_image_url'],
      wishCount: json['item_count'] ?? 0,
      reservedCount: json['reserved_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      wishes: json['items'] != null
          ? (json['items'] as List).map((w) => Wish.fromJson(w)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'occasion_type': occasionType,
      'event_date': eventDate?.toIso8601String(),
      'visibility': visibility,
      'share_token': shareToken,
      'cover_image_url': coverImageUrl,
      'item_count': wishCount,
      'reserved_count': reservedCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (wishes != null) 'items': wishes!.map((w) => w.toJson()).toList(),
    };
  }
}