class Customer {
  final String id;
  final String? companyId; // For business customers
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime? dateOfBirth;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    this.companyId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.dateOfBirth,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => fullName;

  String get formattedAddress {
    List<String> parts = [];
    if (address?.isNotEmpty == true) parts.add(address!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (zipCode?.isNotEmpty == true) parts.add(zipCode!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      companyId: json['companyId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Customer copyWith({
    String? companyId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    DateTime? dateOfBirth,
    String? notes,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      companyId: companyId ?? this.companyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// For walk-in customers who don't want to provide details
class WalkInCustomer extends Customer {
  WalkInCustomer({String? id})
      : super(
          id: id ?? 'walk-in-${DateTime.now().millisecondsSinceEpoch}',
          firstName: 'Walk-in',
          lastName: 'Customer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
}

// Sample customers for development
class SampleCustomers {
  static final List<Customer> customers = [
    Customer(
      id: 'cust_1',
      firstName: 'Emily',
      lastName: 'Johnson',
      phone: '(555) 123-4567',
      email: 'emily.johnson@email.com',
      address: '123 Main St',
      city: 'Anytown',
      state: 'CA',
      zipCode: '12345',
      notes: 'Prefers gel manicures',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_2',
      firstName: 'Sarah',
      lastName: 'Williams',
      phone: '(555) 987-6543',
      email: 'sarah.williams@email.com',
      address: '456 Oak Ave',
      city: 'Anytown',
      state: 'CA',
      zipCode: '12345',
      notes: 'Regular customer, comes every 2 weeks',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_3',
      firstName: 'Michael',
      lastName: 'Brown',
      phone: '(555) 456-7890',
      email: 'mike.brown@email.com',
      notes: 'New customer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
