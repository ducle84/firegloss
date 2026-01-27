import 'package:flutter/material.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/models/company.dart';
import 'package:firegloss/services/management_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<Employee> _employees = [];
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        ManagementService.getEmployees(),
        ManagementService.getCompanies(),
      ]);
      setState(() {
        _employees = futures[0] as List<Employee>;
        _companies = futures[1] as List<Company>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading data: $e', isError: true);
    }
  }

  String _getCompanyName(String companyId) {
    final company = _companies.firstWhere(
      (comp) => comp.id == companyId,
      orElse: () => Company(
        id: '',
        uid: '',
        name: 'Unknown Company',
        address: '',
        phone: '',
        email: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return company.name;
  }

  void _showAddEmployeeDialog() {
    if (_companies.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Company Required'),
          content: const Text(
            'You must create a company first before adding employees. '
            'Please ask an admin to set up the company.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        onSaved: (employee) async {
          final success = await ManagementService.createEmployee(employee);
          if (success) {
            _showMessage('Employee added successfully!');
            _loadData();
          } else {
            _showMessage('Failed to add employee', isError: true);
          }
        },
      ),
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        employee: employee,
        onSaved: (updatedEmployee) async {
          final success =
              await ManagementService.updateEmployee(updatedEmployee);
          if (success) {
            _showMessage('Employee updated successfully!');
            _loadData();
          } else {
            _showMessage('Failed to update employee', isError: true);
          }
        },
      ),
    );
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ManagementService.deleteEmployee(employee.id);
      if (success) {
        _showMessage('Employee deleted successfully!');
        _loadData();
      } else {
        _showMessage('Failed to delete employee', isError: true);
      }
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
        title: const Text('Employee Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No employees found'),
                      Text('Tap + to add your first employee'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(employee.role),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(employee.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(employee.email),
                              Text(
                                  'Company: ${_getCompanyName(employee.companyId)}'),
                              Text(
                                  'Role: ${employee.role.toString().split('.').last}'),
                              if (employee.hourlyRate != null)
                                Text(
                                    'Rate: \$${employee.hourlyRate!.toStringAsFixed(2)}/hr'),
                              if (!employee.isEmployed)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
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
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditEmployeeDialog(employee);
                              } else if (value == 'delete') {
                                _deleteEmployee(employee);
                              }
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
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

class EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  final Function(Employee) onSaved;

  const EmployeeFormDialog({
    super.key,
    this.employee,
    required this.onSaved,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _commissionRateController = TextEditingController();

  EmployeeRole _selectedRole = EmployeeRole.technician;
  DateTime _hiredDate = DateTime.now();
  List<Company> _companies = [];
  String? _selectedCompanyId;
  bool _loadingCompanies = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    if (widget.employee != null) {
      final emp = widget.employee!;
      _firstNameController.text = emp.firstName;
      _lastNameController.text = emp.lastName;
      _emailController.text = emp.email;
      _phoneController.text = emp.phone ?? '';
      _hourlyRateController.text = emp.hourlyRate?.toString() ?? '';
      _commissionRateController.text = emp.commissionRate?.toString() ?? '';
      _selectedRole = emp.role;
      _hiredDate = emp.hiredDate;
      _selectedCompanyId = emp.companyId;
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await ManagementService.getCompanies();
      setState(() {
        _companies = companies;
        _loadingCompanies = false;
        // Default to the first (and should be only) company
        if (_selectedCompanyId == null && companies.isNotEmpty) {
          _selectedCompanyId = companies.first.id;
        }
      });
    } catch (e) {
      setState(() => _loadingCompanies = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value!)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Company Selection (Read-only since only one company allowed)
                _loadingCompanies
                    ? const CircularProgressIndicator()
                    : _companies.isNotEmpty
                        ? TextFormField(
                            initialValue: _companies.first.name,
                            decoration: const InputDecoration(
                              labelText: 'Company',
                              suffixIcon: Icon(Icons.lock, color: Colors.grey),
                            ),
                            enabled: false,
                          )
                        : const Text(
                            'No company found. Company setup required first.',
                            style: TextStyle(color: Colors.red),
                          ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Phone (Optional)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EmployeeRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: EmployeeRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                      labelText: 'Hourly Rate (Optional)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isNotEmpty == true) {
                      final rate = double.tryParse(value!);
                      if (rate == null || rate < 0) return 'Invalid rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commissionRateController,
                  decoration: const InputDecoration(
                      labelText: 'Commission Rate % (Optional)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isNotEmpty == true) {
                      final rate = double.tryParse(value!);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Rate must be 0-100%';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Hired Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _hiredDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _hiredDate = date);
                        }
                      },
                      child: Text(
                          '${_hiredDate.month}/${_hiredDate.day}/${_hiredDate.year}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final employee = Employee(
                id: widget.employee?.id ?? '',
                uid: widget.employee?.uid ??
                    'new_${DateTime.now().millisecondsSinceEpoch}',
                companyId: _selectedCompanyId ?? '',
                email: _emailController.text,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                phone: _phoneController.text.isEmpty
                    ? null
                    : _phoneController.text,
                role: _selectedRole,
                hourlyRate: _hourlyRateController.text.isEmpty
                    ? null
                    : double.tryParse(_hourlyRateController.text),
                commissionRate: _commissionRateController.text.isEmpty
                    ? null
                    : double.tryParse(_commissionRateController.text),
                hiredDate: _hiredDate,
                createdAt: widget.employee?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSaved(employee);
              Navigator.pop(context);
            }
          },
          child: Text(widget.employee == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
