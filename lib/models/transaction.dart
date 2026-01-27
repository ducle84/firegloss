import 'item.dart';

enum TransactionStatus { pending, completed, cancelled, refunded }

enum PaymentMethod { cash, card, check, other }

class TransactionHeader {
  final String id;
  final String companyId;
  final String transactionNumber;
  final DateTime transactionDate;
  final String? customerId; // Customer information (optional for walk-ins)
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String employeeId; // Employee who processed the transaction
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double tax;
  final double discount;
  final double tip;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionHeader({
    required this.id,
    required this.companyId,
    required this.transactionNumber,
    required this.transactionDate,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.employeeId,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.tip,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';
  String get formattedDiscount => '\$${discount.toStringAsFixed(2)}';
  String get formattedTip => '\$${tip.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'transactionNumber': transactionNumber,
      'transactionDate': transactionDate.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'employeeId': employeeId,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'tip': tip,
      'total': total,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionHeader.fromJson(Map<String, dynamic> json) {
    return TransactionHeader(
      id: json['id'],
      companyId: json['companyId'],
      transactionNumber: json['transactionNumber'],
      transactionDate: DateTime.parse(json['transactionDate']),
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      employeeId: json['employeeId'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      discount: json['discount'].toDouble(),
      tip: json['tip'].toDouble(),
      total: json['total'].toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  TransactionHeader copyWith({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? tax,
    double? discount,
    double? tip,
    double? total,
    String? notes,
    DateTime? updatedAt,
  }) {
    return TransactionHeader(
      id: id,
      companyId: companyId,
      transactionNumber: transactionNumber,
      transactionDate: transactionDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      employeeId: employeeId,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class TransactionLine {
  final String id;
  final String transactionId;
  final String itemId;
  final String itemName; // Stored for historical purposes
  final ItemType itemType;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? technicianId; // Employee who performed the service
  final int? serviceDuration; // Actual duration for services
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionLine({
    required this.id,
    required this.transactionId,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.technicianId,
    this.serviceDuration,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
  String get formattedLineTotal => '\$${lineTotal.toStringAsFixed(2)}';

  bool get isService => itemType == ItemType.service;
  bool get isProduct => itemType == ItemType.product;

  String get formattedDuration => serviceDuration != null
      ? '${serviceDuration! ~/ 60}h ${serviceDuration! % 60}m'
      : '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'itemId': itemId,
      'itemName': itemName,
      'itemType': itemType.toString().split('.').last,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'technicianId': technicianId,
      'serviceDuration': serviceDuration,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionLine.fromJson(Map<String, dynamic> json) {
    return TransactionLine(
      id: json['id'],
      transactionId: json['transactionId'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      itemType: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['itemType'],
        orElse: () => ItemType.service,
      ),
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      lineTotal: json['lineTotal'].toDouble(),
      technicianId: json['technicianId'],
      serviceDuration: json['serviceDuration'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  TransactionLine copyWith({
    int? quantity,
    double? unitPrice,
    double? lineTotal,
    String? technicianId,
    int? serviceDuration,
    String? notes,
    DateTime? updatedAt,
  }) {
    return TransactionLine(
      id: id,
      transactionId: transactionId,
      itemId: itemId,
      itemName: itemName,
      itemType: itemType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      technicianId: technicianId ?? this.technicianId,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class Transaction {
  final TransactionHeader header;
  final List<TransactionLine> lines;

  Transaction({
    required this.header,
    required this.lines,
  });

  double get calculatedSubtotal =>
      lines.fold(0.0, (sum, line) => sum + line.lineTotal);
  double get calculatedTotal =>
      header.subtotal + header.tax - header.discount + header.tip;

  int get totalItems => lines.fold(0, (sum, line) => sum + line.quantity);

  List<TransactionLine> get services =>
      lines.where((line) => line.isService).toList();
  List<TransactionLine> get products =>
      lines.where((line) => line.isProduct).toList();

  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      header: TransactionHeader.fromJson(json['header']),
      lines: (json['lines'] as List)
          .map((lineJson) => TransactionLine.fromJson(lineJson))
          .toList(),
    );
  }
}
