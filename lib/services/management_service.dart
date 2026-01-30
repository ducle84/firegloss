import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firegloss/models/company.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/models/item_category.dart';
import 'package:firegloss/models/item.dart';
import 'package:firegloss/models/transaction.dart';
import 'package:firegloss/models/discount.dart'; // For Payment model

class ManagementService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // In-memory storage for transaction lines (for UI testing when backend is not available)
  static final Map<String, List<TransactionLine>> _transactionLinesCache = {};

  // In-memory storage for updated transactions (for UI testing when backend is not available)
  static final Map<String, TransactionHeader> _transactionUpdatesCache = {};

  // Track deleted transactions to prevent them from appearing in merged results
  static final Set<String> _deletedTransactionIds = {};

  // Company Services
  static Future<List<Company>> getCompanies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/companies'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> companies = data['data']['companies'];
          return companies.map((company) {
            try {
              return Company.fromJson(company);
            } catch (e) {
              rethrow;
            }
          }).toList();
        }
      }
      throw Exception('Failed to load companies: ${response.statusCode}');
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createCompany(Company company) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/companies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(company.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateCompany(Company company) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/companies/${company.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(company.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteCompany(String companyId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/companies/$companyId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Employee Services
  static Future<List<Employee>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/employees'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> employees = data['data']['employees'];
          return employees
              .map((employee) => Employee.fromJson(employee))
              .toList();
        }
      }
      throw Exception('Failed to load employees');
    } catch (e) {
      return [];
    }
  }

  // Get employees for a specific company (many-to-one relationship)
  static Future<List<Employee>> getEmployeesByCompany(String companyId) async {
    try {
      final allEmployees = await getEmployees();
      return allEmployees
          .where((employee) => employee.belongsToCompany(companyId))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get active employees for a specific company
  static Future<List<Employee>> getActiveEmployeesByCompany(
      String companyId) async {
    try {
      final companyEmployees = await getEmployeesByCompany(companyId);
      return companyEmployees.where((employee) => employee.isEmployed).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createEmployee(Employee employee) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employee.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateEmployee(Employee employee) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/employees/${employee.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(employee.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteEmployee(String employeeId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/employees/$employeeId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Category Services
  static Future<List<ItemCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> categories = data['data']['categories'];
          return categories
              .map((category) => ItemCategory.fromJson(category))
              .toList();
        }
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createCategory(ItemCategory category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateCategory(ItemCategory category) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/${category.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteCategory(String categoryId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/categories/$categoryId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Item Services
  static Future<List<Item>> getItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> items = data['data']['items'];
          return items.map((item) => Item.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to load items');
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createItem(Item item) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateItem(Item item) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/items/${item.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteItem(String itemId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/items/$itemId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Transaction Services
  static Future<List<TransactionHeader>> getTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> transactions = data['data']['transactions'];
          final transactionList = transactions
              .map((transaction) => TransactionHeader.fromJson(transaction))
              .toList();
          return transactionList;
        }
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        final mergedTransactions = _getMergedTransactions();
        return mergedTransactions;
      }

      throw Exception(
          'Failed to load transactions: Status ${response.statusCode}');
    } catch (e) {
      final mergedTransactions = _getMergedTransactions();
      return mergedTransactions;
    }
  }

  static Future<TransactionHeader?> createTransaction(
      TransactionHeader transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] && data['data']['transaction'] != null) {
          return TransactionHeader.fromJson(data['data']['transaction']);
        }
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        return TransactionHeader(
          id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          companyId: transaction.companyId,
          transactionNumber: transaction.transactionNumber,
          transactionDate: transaction.transactionDate,
          customerId: transaction.customerId,
          customerName: transaction.customerName,
          customerPhone: transaction.customerPhone,
          customerEmail: transaction.customerEmail,
          employeeId: transaction.employeeId,
          status: transaction.status,
          paymentMethod: transaction.paymentMethod,
          subtotal: transaction.subtotal,
          tax: transaction.tax,
          discount: transaction.discount,
          tip: transaction.tip,
          total: transaction.total,
          notes: transaction.notes,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
        );
      } else {
        return TransactionHeader(
          id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          companyId: transaction.companyId,
          transactionNumber: transaction.transactionNumber,
          transactionDate: transaction.transactionDate,
          customerId: transaction.customerId,
          customerName: transaction.customerName,
          customerPhone: transaction.customerPhone,
          customerEmail: transaction.customerEmail,
          employeeId: transaction.employeeId,
          status: transaction.status,
          paymentMethod: transaction.paymentMethod,
          subtotal: transaction.subtotal,
          tax: transaction.tax,
          discount: transaction.discount,
          tip: transaction.tip,
          total: transaction.total,
          notes: transaction.notes,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
        );
      }
    } catch (e) {
      // Return a mock transaction with an ID for frontend testing
      // In production, this would be handled properly with a database
      return TransactionHeader(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        companyId: transaction.companyId,
        transactionNumber: transaction.transactionNumber,
        transactionDate: transaction.transactionDate,
        customerId: transaction.customerId,
        customerName: transaction.customerName,
        customerPhone: transaction.customerPhone,
        customerEmail: transaction.customerEmail,
        employeeId: transaction.employeeId,
        status: transaction.status,
        paymentMethod: transaction.paymentMethod,
        subtotal: transaction.subtotal,
        tax: transaction.tax,
        discount: transaction.discount,
        tip: transaction.tip,
        total: transaction.total,
        notes: transaction.notes,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
    }
  }

  static Future<bool> updateTransaction(TransactionHeader transaction) async {
    // Always cache the transaction first, especially if it has payments
    _transactionUpdatesCache[transaction.id] = transaction;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/${transaction.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        _transactionUpdatesCache[transaction.id] = transaction;
        return true;
      }

      return false;
    } catch (e) {
      _transactionUpdatesCache[transaction.id] = transaction;
      return true; // Mock success for frontend testing
    }
  }

  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/transactions/$transactionId'));
      final data = json.decode(response.body);
      bool success = data['success'] ?? false;

      if (success) {
        // Remove from local caches
        _removeTransactionFromCache(transactionId);
      }

      return success;
    } catch (e) {
      // For UI testing, remove from local caches even when backend fails
      _removeTransactionFromCache(transactionId);

      return true; // Mock success for frontend testing
    }
  }

  // Helper method to remove transaction from all local caches
  static void _removeTransactionFromCache(String transactionId) {
    // Remove from transaction updates cache
    _transactionUpdatesCache.remove(transactionId);

    // Remove transaction lines associated with this transaction
    _transactionLinesCache.remove(transactionId);

    // Add to a deleted transactions set to prevent it from showing up in merged results
    _deletedTransactionIds.add(transactionId);
  }

  // Method to clear all cached data (useful for testing/debugging)
  static void clearAllCaches() {
    _transactionLinesCache.clear();
    _transactionUpdatesCache.clear();
    _deletedTransactionIds.clear();
  }

  static Future<List<TransactionLine>> getTransactionLines(
      String transactionId) async {
    // Check cache first - if we have cached data, use it as it's more recent
    if (_transactionLinesCache.containsKey(transactionId)) {
      final cachedLines = _transactionLinesCache[transactionId]!;
      return List<TransactionLine>.from(cachedLines);
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/transactions/$transactionId/lines'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> lines = data['data']['lines'];
          final transactionLines =
              lines.map((line) => TransactionLine.fromJson(line)).toList();

          // Initialize cache with backend data for future modifications
          _transactionLinesCache[transactionId] =
              List<TransactionLine>.from(transactionLines);

          return transactionLines;
        }
      }
      throw Exception('Failed to load transaction lines');
    } catch (e) {
      // Check in-memory cache first
      if (_transactionLinesCache.containsKey(transactionId)) {
        final cachedLines = _transactionLinesCache[transactionId]!;
        return List<TransactionLine>.from(cachedLines);
      }

      // Fall back to sample transaction lines for UI testing ONLY if no cache exists
      final sampleLines = _getSampleTransactionLines(transactionId);
      if (sampleLines.isNotEmpty) {
        // Initialize cache with sample data so future modifications work correctly
        _transactionLinesCache[transactionId] =
            List<TransactionLine>.from(sampleLines);
        return sampleLines;
      }

      // If no sample data exists for this transaction, return empty list
      return [];
    }
  }

  static Future<bool> addTransactionLine(TransactionLine line) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/${line.transactionId}/lines'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(line.toJson()),
      );
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      // Store in memory cache for UI testing
      if (!_transactionLinesCache.containsKey(line.transactionId)) {
        _transactionLinesCache[line.transactionId] = [];
      }

      // Check if line already exists (by unique ID first, then by item+technician combination)
      final existingLines = _transactionLinesCache[line.transactionId]!;

      // First check if exact same line ID exists
      final existingIdIndex = existingLines
          .indexWhere((existingLine) => existingLine.id == line.id);

      if (existingIdIndex >= 0) {
        // Update existing line with same ID
        existingLines[existingIdIndex] = line;
      } else {
        // Check if same item with same technician already exists (different line ID)
        final existingItemIndex = existingLines.indexWhere((existingLine) =>
            existingLine.itemId == line.itemId &&
            existingLine.technicianId == line.technicianId);

        if (existingItemIndex >= 0) {
          // Update existing line with new quantity/total but keep original ID
          final updatedLine = existingLines[existingItemIndex].copyWith(
            quantity: line.quantity,
            lineTotal: line.lineTotal,
            updatedAt: line.updatedAt,
          );
          existingLines[existingItemIndex] = updatedLine;
        } else {
          // Add completely new line
          existingLines.add(line);
        }
      }

      return true;
    }
  }

  static Future<bool> removeTransactionLine(
      String transactionId, String lineId) async {
    try {
      final response = await http.delete(
          Uri.parse('$baseUrl/transactions/$transactionId/lines/$lineId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      // Remove from memory cache for UI testing
      if (_transactionLinesCache.containsKey(transactionId)) {
        final existingLines = _transactionLinesCache[transactionId]!;
        existingLines.removeWhere((line) => line.id == lineId);
        return true;
      }
      return false;
    }
  }

  static Future<bool> setTransactionLines(
      String transactionId, List<TransactionLine> lines) async {
    try {
      // For now, store all lines in cache to replace existing ones
      _transactionLinesCache[transactionId] = List<TransactionLine>.from(lines);

      // In a real implementation, this would sync with the backend
      // by sending the complete list of lines to replace the existing ones
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<TransactionHeader?> getCachedTransactionUpdate(
      String transactionId) async {
    final result = _transactionUpdatesCache[transactionId];
    return result;
  }

  static String generateTransactionNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'TXN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  // Helper method to merge sample transactions with cached updates
  static List<TransactionHeader> _getMergedTransactions() {
    final sampleTransactions = _getSampleTransactions();
    final Map<String, TransactionHeader> mergedMap = {};

    // Start with sample transactions, excluding deleted ones
    for (final transaction in sampleTransactions) {
      if (!_deletedTransactionIds.contains(transaction.id)) {
        mergedMap[transaction.id] = transaction;
      }
    }

    // Override with any cached updates, excluding deleted ones
    for (final entry in _transactionUpdatesCache.entries) {
      if (!_deletedTransactionIds.contains(entry.key)) {
        mergedMap[entry.key] = entry.value;
      }
    }

    return mergedMap.values.toList();
  }

  // Sample data methods for UI testing
  static List<TransactionHeader> _getSampleTransactions() {
    final now = DateTime.now();
    return [
      TransactionHeader(
        id: 'txn_sample_1',
        companyId: 'comp_sample_1',
        transactionNumber: generateTransactionNumber(),
        transactionDate: now.subtract(const Duration(hours: 2)),
        customerId: 'cust_1',
        customerName: 'Sarah Johnson',
        customerPhone: '(555) 123-4567',
        employeeId: 'emp_sample_1',
        status: TransactionStatus.complete,
        paymentMethod: PaymentMethod.card,
        subtotal: 90.00,
        tax: 0.00,
        discount: 5.00,
        tip: 15.00,
        total: 100.00,
        notes: 'Regular customer - loves gel manicures',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      TransactionHeader(
        id: 'txn_sample_2',
        companyId: 'comp_sample_1',
        transactionNumber: generateTransactionNumber(),
        transactionDate: now.subtract(const Duration(hours: 4)),
        customerId: 'cust_2',
        customerName: 'Maria Garcia',
        customerPhone: '(555) 987-6543',
        employeeId: 'emp_sample_2',
        status: TransactionStatus.complete,
        paymentMethod: PaymentMethod.cash,
        subtotal: 125.00,
        tax: 0.00,
        discount: 0.00,
        tip: 20.00,
        total: 145.00,
        notes: 'Spa pedicure with nail art',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      TransactionHeader(
        id: 'txn_sample_3',
        companyId: 'comp_sample_1',
        transactionNumber: generateTransactionNumber(),
        transactionDate: now.subtract(const Duration(minutes: 30)),
        customerId: null,
        customerName: 'Walk-in Customer',
        employeeId: 'emp_sample_1',
        status: TransactionStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        subtotal: 65.00,
        tax: 0.00,
        discount: 0.00,
        tip: 0.00,
        total: 65.00,
        notes: 'Classic manicure and pedicure',
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  static List<TransactionLine> _getSampleTransactionLines(
      String transactionId) {
    final now = DateTime.now();

    switch (transactionId) {
      case 'txn_sample_1':
        return [
          TransactionLine(
            id: 'line_1_1',
            transactionId: transactionId,
            itemId: 'item_2',
            itemName: 'Gel Manicure',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 35.00,
            lineTotal: 35.00,
            technicianId: 'emp_sample_1',
            serviceDuration: 60,
            createdAt: now.subtract(const Duration(hours: 2)),
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
          TransactionLine(
            id: 'line_1_2',
            transactionId: transactionId,
            itemId: 'item_8',
            itemName: 'Simple Nail Art',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 15.00,
            lineTotal: 15.00,
            technicianId: 'emp_sample_1',
            serviceDuration: 30,
            createdAt: now.subtract(const Duration(hours: 2)),
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
          TransactionLine(
            id: 'line_1_3',
            transactionId: transactionId,
            itemId: 'item_11',
            itemName: 'Nail Polish',
            itemType: ItemType.product,
            quantity: 2,
            unitPrice: 20.00,
            lineTotal: 40.00,
            createdAt: now.subtract(const Duration(hours: 2)),
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
        ];

      case 'txn_sample_2':
        return [
          TransactionLine(
            id: 'line_2_1',
            transactionId: transactionId,
            itemId: 'item_5',
            itemName: 'Spa Pedicure',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 55.00,
            lineTotal: 55.00,
            technicianId: 'emp_sample_2',
            serviceDuration: 75,
            createdAt: now.subtract(const Duration(hours: 4)),
            updatedAt: now.subtract(const Duration(hours: 4)),
          ),
          TransactionLine(
            id: 'line_2_2',
            transactionId: transactionId,
            itemId: 'item_9',
            itemName: 'Complex Nail Art',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 45.00,
            lineTotal: 45.00,
            technicianId: 'emp_sample_2',
            serviceDuration: 60,
            createdAt: now.subtract(const Duration(hours: 4)),
            updatedAt: now.subtract(const Duration(hours: 4)),
          ),
          TransactionLine(
            id: 'line_2_3',
            transactionId: transactionId,
            itemId: 'item_12',
            itemName: 'Cuticle Oil',
            itemType: ItemType.product,
            quantity: 1,
            unitPrice: 25.00,
            lineTotal: 25.00,
            createdAt: now.subtract(const Duration(hours: 4)),
            updatedAt: now.subtract(const Duration(hours: 4)),
          ),
        ];

      case 'txn_sample_3':
        return [
          TransactionLine(
            id: 'line_3_1',
            transactionId: transactionId,
            itemId: 'item_1',
            itemName: 'Classic Manicure',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 25.00,
            lineTotal: 25.00,
            technicianId: 'emp_sample_1',
            serviceDuration: 45,
            createdAt: now.subtract(const Duration(minutes: 30)),
            updatedAt: now.subtract(const Duration(minutes: 30)),
          ),
          TransactionLine(
            id: 'line_3_2',
            transactionId: transactionId,
            itemId: 'item_4',
            itemName: 'Classic Pedicure',
            itemType: ItemType.service,
            quantity: 1,
            unitPrice: 40.00,
            lineTotal: 40.00,
            technicianId: 'emp_sample_1',
            serviceDuration: 60,
            createdAt: now.subtract(const Duration(minutes: 30)),
            updatedAt: now.subtract(const Duration(minutes: 30)),
          ),
        ];

      default:
        return [];
    }
  }

  // Payment management methods
  static Future<bool> savePayment(Payment payment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payment.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] ?? true;
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        return true;
      }

      return false;
    } catch (e) {
      return true; // Mock success for frontend testing
    }
  }

  static Future<List<Payment>> getPaymentsForTransaction(
      String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$transactionId/payments'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => Payment.fromJson(json)).toList();
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        return [];
      }

      return [];
    } catch (e) {
      return []; // Return empty list for frontend testing
    }
  }

  static Future<bool> deletePayment(String paymentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payments/$paymentId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? true;
      }

      // Handle 404 specifically (endpoint not implemented)
      if (response.statusCode == 404) {
        return true;
      }

      return false;
    } catch (e) {
      return true; // Mock success for frontend testing
    }
  }
}
