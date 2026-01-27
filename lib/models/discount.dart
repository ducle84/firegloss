import 'transaction.dart';

enum DiscountType { percentage, fixed }

class Discount {
  final String id;
  final String name;
  final String description;
  final DiscountType type;
  final double value; // Percentage (0-100) or fixed amount
  final double? minimumAmount; // Minimum transaction amount required
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Discount({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.minimumAmount,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isValid {
    final now = DateTime.now();
    if (!isActive) return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  double calculateDiscount(double amount) {
    if (!isValid || (minimumAmount != null && amount < minimumAmount!)) {
      return 0.0;
    }

    switch (type) {
      case DiscountType.percentage:
        return amount * (value / 100);
      case DiscountType.fixed:
        return value;
    }
  }

  String get formattedValue {
    switch (type) {
      case DiscountType.percentage:
        return '${value.toStringAsFixed(0)}% off';
      case DiscountType.fixed:
        return '\$${value.toStringAsFixed(2)} off';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'minimumAmount': minimumAmount,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: DiscountType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DiscountType.percentage,
      ),
      value: json['value'].toDouble(),
      minimumAmount: json['minimumAmount']?.toDouble(),
      validFrom:
          json['validFrom'] != null ? DateTime.parse(json['validFrom']) : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Payment {
  final String id;
  final String transactionId;
  final PaymentMethod method;
  final double amount;
  final DateTime paymentDate;
  final String? referenceNumber; // Check number, card transaction ID, etc.
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.transactionId,
    required this.method,
    required this.amount,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  String get methodName {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'method': method.toString().split('.').last,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      transactionId: json['transactionId'],
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      referenceNumber: json['referenceNumber'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// Sample discounts for development
class SampleDiscounts {
  static final List<Discount> discounts = [
    Discount(
      id: 'disc_1',
      name: 'First Time Customer',
      description: '20% off first visit',
      type: DiscountType.percentage,
      value: 20.0,
      minimumAmount: 25.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Discount(
      id: 'disc_2',
      name: 'Senior Discount',
      description: '15% off for seniors (65+)',
      type: DiscountType.percentage,
      value: 15.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Discount(
      id: 'disc_3',
      name: 'Student Discount',
      description: '\$5 off with valid student ID',
      type: DiscountType.fixed,
      value: 5.0,
      minimumAmount: 20.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
