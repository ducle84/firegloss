class ItemCategory {
  final String id;
  final String name;
  final String description;
  final String? color; // Hex color code for UI display
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemCategory({
    required this.id,
    required this.name,
    required this.description,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  ItemCategory copyWith({
    String? name,
    String? description,
    String? color,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ItemCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
