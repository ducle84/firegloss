import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firegloss/models/company.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/models/item_category.dart';
import 'package:firegloss/models/item.dart';

class ManagementService {
  static const String baseUrl = 'http://127.0.0.1:8000';

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
              print('Error parsing company: $e');
              print('Company data: $company');
              rethrow;
            }
          }).toList();
        }
      }
      throw Exception('Failed to load companies: ${response.statusCode}');
    } catch (e) {
      print('Error getting companies: $e');
      return [];
    }
  }

  static Future<bool> createCompany(Company company) async {
    try {
      print('Creating company: ${company.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/companies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(company.toJson()),
      );
      print(
          'Create company response: ${response.statusCode} - ${response.body}');
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      print('Error creating company: $e');
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
      print('Error updating company: $e');
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
      print('Error deleting company: $e');
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
      print('Error getting employees: $e');
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
      print('Error getting employees for company: $e');
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
      print('Error getting active employees for company: $e');
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
      print('Error creating employee: $e');
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
      print('Error updating employee: $e');
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
      print('Error deleting employee: $e');
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
      print('Error getting categories: $e');
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
      print('Error creating category: $e');
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
      print('Error updating category: $e');
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
      print('Error deleting category: $e');
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
      print('Error getting items: $e');
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
      print('Error creating item: $e');
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
      print('Error updating item: $e');
      return false;
    }
  }

  static Future<bool> deleteItem(String itemId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/items/$itemId'));
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }
}
