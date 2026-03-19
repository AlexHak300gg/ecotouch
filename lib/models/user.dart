class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String name;
  final String? phone;
  final String? avatarPath;
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.phone,
    this.avatarPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'phone': phone,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      name: map['name'],
      phone: map['phone'],
      avatarPath: map['avatar_path'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? name,
    String? phone,
    String? avatarPath,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
