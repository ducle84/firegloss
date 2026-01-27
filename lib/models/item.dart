import 'item_category.dart';

enum ItemType { service, product }

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final String categoryId;
  final double price;
  final int? durationMinutes; // For services only
  final String? sku; // For products only
  final int? stockQuantity; // For products only
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.categoryId,
    required this.price,
    this.durationMinutes,
    this.sku,
    this.stockQuantity,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'categoryId': categoryId,
      'price': price,
      'durationMinutes': durationMinutes,
      'sku': sku,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ItemType.service,
      ),
      categoryId: json['categoryId'],
      price: json['price'].toDouble(),
      durationMinutes: json['durationMinutes'],
      sku: json['sku'],
      stockQuantity: json['stockQuantity'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isService => type == ItemType.service;
  bool get isProduct => type == ItemType.product;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get formattedDuration => durationMinutes != null
      ? '${durationMinutes! ~/ 60}h ${durationMinutes! % 60}m'
      : '';

  Item copyWith({
    String? name,
    String? description,
    ItemType? type,
    String? categoryId,
    double? price,
    int? durationMinutes,
    String? sku,
    int? stockQuantity,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sku: sku ?? this.sku,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Sample nail salon items
class SampleItems {
  static final List<ItemCategory> categories = [
    ItemCategory(
      id: 'cat_1',
      name: 'Manicure Services',
      description: 'Hand and nail care services',
      color: '#E91E63',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ItemCategory(
      id: 'cat_2',
      name: 'Pedicure Services',
      description: 'Foot and nail care services',
      color: '#9C27B0',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ItemCategory(
      id: 'cat_3',
      name: 'Nail Art & Design',
      description: 'Creative nail designs and art',
      color: '#FF5722',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ItemCategory(
      id: 'cat_4',
      name: 'Retail Products',
      description: 'Nail care products for sale',
      color: '#4CAF50',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<Item> items = [
    // Manicure Services
    Item(
      id: 'item_1',
      name: 'Classic Manicure',
      description: 'Basic nail shaping, cuticle care, and polish',
      type: ItemType.service,
      categoryId: 'cat_1',
      price: 25.00,
      durationMinutes: 45,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 'item_2',
      name: 'Gel Manicure',
      description: 'Long-lasting gel polish manicure',
      type: ItemType.service,
      categoryId: 'cat_1',
      price: 35.00,
      durationMinutes: 60,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 'item_3',
      name: 'French Manicure',
      description: 'Classic French tip manicure',
      type: ItemType.service,
      categoryId: 'cat_1',
      price: 30.00,
      durationMinutes: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Pedicure Services
    Item(
      id: 'item_4',
      name: 'Classic Pedicure',
      description: 'Basic foot care and nail polish',
      type: ItemType.service,
      categoryId: 'cat_2',
      price: 40.00,
      durationMinutes: 60,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 'item_5',
      name: 'Spa Pedicure',
      description: 'Luxurious foot treatment with massage',
      type: ItemType.service,
      categoryId: 'cat_2',
      price: 55.00,
      durationMinutes: 75,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Nail Art
    Item(
      id: 'item_6',
      name: 'Simple Nail Art',
      description: 'Basic designs and patterns',
      type: ItemType.service,
      categoryId: 'cat_3',
      price: 15.00,
      durationMinutes: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 'item_7',
      name: 'Complex Nail Art',
      description: 'Detailed custom designs',
      type: ItemType.service,
      categoryId: 'cat_3',
      price: 25.00,
      durationMinutes: 45,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Products
    Item(
      id: 'item_8',
      name: 'Nail Polish',
      description: 'Premium nail polish',
      type: ItemType.product,
      categoryId: 'cat_4',
      price: 12.00,
      sku: 'NP001',
      stockQuantity: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 'item_9',
      name: 'Cuticle Oil',
      description: 'Nourishing cuticle treatment oil',
      type: ItemType.product,
      categoryId: 'cat_4',
      price: 8.00,
      sku: 'CO001',
      stockQuantity: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
