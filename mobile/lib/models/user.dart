class User {
  final String id;
  final String firebaseUid;
  final String? email;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.name,
    this.username,
    this.avatarUrl,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      name: json['full_name'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      isAnonymous: json['is_anonymous'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'full_name': name,
      'username': username,
      'avatar_url': avatarUrl,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}