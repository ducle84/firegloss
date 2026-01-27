enum EmployeeRole { technician, manager, admin }

class Employee {
  final String id;
  final String uid; // Firebase Auth UID
  final String companyId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final EmployeeRole role;
  final double? hourlyRate;
  final double? commissionRate; // Percentage (0-100)
  final bool isActive;
  final DateTime hiredDate;
  final DateTime? terminatedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.uid,
    required this.companyId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.hourlyRate,
    this.commissionRate,
    this.isActive = true,
    required this.hiredDate,
    this.terminatedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'companyId': companyId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.toString().split('.').last,
      'hourlyRate': hourlyRate,
      'commissionRate': commissionRate,
      'isActive': isActive,
      'hiredDate': hiredDate.toIso8601String(),
      'terminatedDate': terminatedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      companyId: json['companyId'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      role: EmployeeRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => EmployeeRole.technician,
      ),
      hourlyRate: json['hourlyRate']?.toDouble(),
      commissionRate: json['commissionRate']?.toDouble(),
      isActive: json['isActive'] ?? true,
      hiredDate: json['hiredDate'] != null
          ? DateTime.parse(json['hiredDate'])
          : DateTime.now(),
      terminatedDate: json['terminatedDate'] != null
          ? DateTime.parse(json['terminatedDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  bool canAccessWithoutPasscode() {
    return role == EmployeeRole.admin;
  }

  bool canAccessSensitiveScreens() {
    return role == EmployeeRole.admin || role == EmployeeRole.manager;
  }

  bool canCreateEmployees() {
    return role == EmployeeRole.admin || role == EmployeeRole.manager;
  }

  bool canManageInventory() {
    return role == EmployeeRole.admin || role == EmployeeRole.manager;
  }

  bool canProcessTransactions() {
    return isActive &&
        (role == EmployeeRole.admin ||
            role == EmployeeRole.manager ||
            role == EmployeeRole.technician);
  }

  Employee copyWith({
    String? companyId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    EmployeeRole? role,
    double? hourlyRate,
    double? commissionRate,
    bool? isActive,
    DateTime? hiredDate,
    DateTime? terminatedDate,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      uid: uid,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      hiredDate: hiredDate ?? this.hiredDate,
      terminatedDate: terminatedDate ?? this.terminatedDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods for company relationship
  bool belongsToCompany(String companyId) => this.companyId == companyId;

  bool get isEmployed => isActive && terminatedDate == null;

  bool get isTerminated => !isActive || terminatedDate != null;

  // Calculate years of service
  double get yearsOfService {
    final endDate = terminatedDate ?? DateTime.now();
    final difference = endDate.difference(hiredDate);
    return difference.inDays / 365.25;
  }
}
