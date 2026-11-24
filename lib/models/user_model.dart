class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // e.g. QA Lead, Automation Architect, Senior Test Engineer, SDET Specialist, QA Analyst, Admin
  final String avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] ?? json['full_name'] ?? 'Team Member',
      email: json['email'] ?? '',
      role: json['role'] ?? 'QA Analyst',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'] ?? 'https://i.pravatar.cc/150?u=${json['id']}',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
