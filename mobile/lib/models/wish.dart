class Wish {
  final String id;
  final String wishlistId;
  final String title;
  final String? description;
  final double? price;
  final String? currency;
  final String? url;
  final List<String> images;
  final String? brand;
  final String? category;
  final int priority;
  final int quantity;
  final String status;
  final String? reservedBy;
  final DateTime? reservedAt;
  final String? reserverName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wish({
    required this.id,
    required this.wishlistId,
    required this.title,
    this.description,
    this.price,
    this.currency = 'USD',
    this.url,
    this.images = const [],
    this.brand,
    this.category,
    this.priority = 1,
    this.quantity = 1,
    this.status = 'available',
    this.reservedBy,
    this.reservedAt,
    this.reserverName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReserved => status == 'reserved';
  String? get imageUrl => images.isNotEmpty ? images.first : null;

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'].toString(),
      wishlistId: json['wishlist_id'].toString(),
      title: json['title'],
      description: json['description'],
      price: json['price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      url: json['url'],
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : [],
      brand: json['brand'],
      category: json['category'],
      priority: json['priority'] ?? 1,
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'available',
      reservedBy: json['reserved_by'],
      reservedAt: json['reserved_at'] != null 
          ? DateTime.parse(json['reserved_at']) 
          : null,
      reserverName: json['reserver_name'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wishlist_id': wishlistId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'url': url,
      'images': images,
      'brand': brand,
      'category': category,
      'priority': priority,
      'quantity': quantity,
      'status': status,
      'reserved_by': reservedBy,
      'reserved_at': reservedAt?.toIso8601String(),
      'reserver_name': reserverName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}