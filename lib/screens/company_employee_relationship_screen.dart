import 'package:flutter/material.dart';
import 'package:firegloss/models/company.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/services/management_service.dart';

class CompanyEmployeeRelationshipScreen extends StatefulWidget {
  const CompanyEmployeeRelationshipScreen({super.key});

  @override
  State<CompanyEmployeeRelationshipScreen> createState() =>
      _CompanyEmployeeRelationshipScreenState();
}

class _CompanyEmployeeRelationshipScreenState
    extends State<CompanyEmployeeRelationshipScreen> {
  List<Company> _companies = [];
  Map<String, List<Employee>> _companyEmployees = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load companies and employees
      final companies = await ManagementService.getCompanies();
      final employees = await ManagementService.getEmployees();

      // Group employees by company
      final companyEmployeeMap = <String, List<Employee>>{};
      for (final company in companies) {
        companyEmployeeMap[company.id] =
            employees.where((emp) => emp.belongsToCompany(company.id)).toList();
      }

      setState(() {
        _companies = companies;
        _companyEmployees = companyEmployeeMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading data: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company-Employee Relationships'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _companies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No companies found'),
                      Text('Add companies first to see relationships'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _companies.length,
                    itemBuilder: (context, index) {
                      final company = _companies[index];
                      final employees = _companyEmployees[company.id] ?? [];
                      final activeEmployees =
                          employees.where((emp) => emp.isEmployed).length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                company.isActive ? Colors.blue : Colors.grey,
                            child:
                                const Icon(Icons.business, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Text(company.name),
                              if (!company.isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(company.email),
                              Text('Total Employees: ${employees.length}'),
                              Text('Active Employees: $activeEmployees'),
                              if (employees.isNotEmpty)
                                Text(
                                    'Average Years of Service: ${_calculateAverageYearsOfService(employees).toStringAsFixed(1)}'),
                            ],
                          ),
                          children: [
                            if (employees.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No employees in this company',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              ...employees.map((employee) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _getRoleColor(employee.role),
                                    radius: 16,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(employee.fullName),
                                      if (!employee.isEmployed)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Inactive',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Role: ${employee.role.toString().split('.').last}'),
                                      Text(
                                          'Years of Service: ${employee.yearsOfService.toStringAsFixed(1)}'),
                                      if (employee.hourlyRate != null)
                                        Text(
                                            'Rate: \$${employee.hourlyRate!.toStringAsFixed(2)}/hr'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  double _calculateAverageYearsOfService(List<Employee> employees) {
    if (employees.isEmpty) return 0;
    final total =
        employees.fold<double>(0, (sum, emp) => sum + emp.yearsOfService);
    return total / employees.length;
  }

  Color _getRoleColor(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
        return Colors.red;
      case EmployeeRole.manager:
        return Colors.orange;
      case EmployeeRole.technician:
        return Colors.blue;
    }
  }
}
