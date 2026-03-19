class RecyclingPoint {
  final int? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final String? phone;
  final String? workingHours;
  final List<String> acceptedTypes;
  final DateTime createdAt;

  RecyclingPoint({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.phone,
    this.workingHours,
    required this.acceptedTypes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'phone': phone,
      'working_hours': workingHours,
      'accepted_types': acceptedTypes.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecyclingPoint.fromMap(Map<String, dynamic> map) {
    return RecyclingPoint(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'],
      phone: map['phone'],
      workingHours: map['working_hours'],
      acceptedTypes: map['accepted_types'] != null
          ? (map['accepted_types'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  RecyclingPoint copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    String? phone,
    String? workingHours,
    List<String>? acceptedTypes,
    DateTime? createdAt,
  }) {
    return RecyclingPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      workingHours: workingHours ?? this.workingHours,
      acceptedTypes: acceptedTypes ?? this.acceptedTypes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RecyclingType {
  final String id;
  final String name;
  final String icon;

  const RecyclingType({
    required this.id,
    required this.name,
    required this.icon,
  });

  static const List<RecyclingType> all = [
    RecyclingType(id: 'paper', name: 'Бумага', icon: '📄'),
    RecyclingType(id: 'plastic', name: 'Пластик', icon: '🥤'),
    RecyclingType(id: 'glass', name: 'Стекло', icon: '🫙'),
    RecyclingType(id: 'metal', name: 'Металл', icon: '🥫'),
    RecyclingType(id: 'electronics', name: 'Электроника', icon: '📱'),
    RecyclingType(id: 'batteries', name: 'Батарейки', icon: '🔋'),
    RecyclingType(id: 'clothes', name: 'Одежда', icon: '👕'),
    RecyclingType(id: 'organic', name: 'Органика', icon: '🍂'),
  ];

  static RecyclingType? fromId(String id) {
    try {
      return all.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}
