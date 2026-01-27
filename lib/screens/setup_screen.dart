import 'package:flutter/material.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/models/company.dart';
import 'package:firegloss/models/item.dart';
import 'package:firegloss/services/settings_service.dart';
import 'package:firegloss/services/management_service.dart';
import 'package:firegloss/screens/employee_management_screen.dart';
import 'package:firegloss/screens/company_management_screen.dart';
import 'package:firegloss/screens/category_management_screen.dart';
import 'package:firegloss/screens/item_management_screen.dart';

class SetupScreen extends StatefulWidget {
  final Employee currentEmployee;

  const SetupScreen({super.key, required this.currentEmployee});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isDefaultPasscode = true;
  final TextEditingController _passcodeController = TextEditingController();
  bool _hasPasscodeText = false;
  Company? _currentCompany;
  bool _isLoadingCompany = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPasscode();
    _loadCompanyData();
    _passcodeController.addListener(_onPasscodeTextChanged);
  }

  @override
  void dispose() {
    _passcodeController.removeListener(_onPasscodeTextChanged);
    _passcodeController.dispose();
    super.dispose();
  }

  void _onPasscodeTextChanged() {
    final hasText = _passcodeController.text.trim().isNotEmpty;
    if (hasText != _hasPasscodeText) {
      setState(() {
        _hasPasscodeText = hasText;
      });
    }
  }

  Future<void> _loadCurrentPasscode() async {
    final passcode = await SettingsService.getPasscode();
    final isDefault = await SettingsService.isDefaultPasscode();
    setState(() {
      _isDefaultPasscode = isDefault;
    });
  }

  Future<void> _loadCompanyData() async {
    try {
      final companies = await ManagementService.getCompanies();
      setState(() {
        _currentCompany = companies.isNotEmpty ? companies.first : null;
        _isLoadingCompany = false;
      });
    } catch (e) {
      setState(() => _isLoadingCompany = false);
    }
  }

  bool get _hasCompany => _currentCompany != null;
  bool get _isAdmin => widget.currentEmployee.role == EmployeeRole.admin;

  void _showCompanyRequiredDialog(String actionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Required'),
        content: Text(
          'You must create a company first before setting up $actionName. '
          'Please ask an admin to set up the company.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (_isAdmin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCompanyManagement();
              },
              child: const Text('Set Up Company'),
            ),
        ],
      ),
    );
  }

  Future<void> _changePasscode() async {
    final newPasscode = _passcodeController.text.trim();

    if (newPasscode.length < 4) {
      _showMessage('Passcode must be at least 4 characters long',
          isError: true);
      return;
    }

    final success = await SettingsService.setPasscode(newPasscode);
    if (success) {
      _showMessage('Passcode updated successfully!');
      _passcodeController.clear();
      _loadCurrentPasscode();
    } else {
      _showMessage('Failed to update passcode', isError: true);
    }
  }

  Future<void> _resetPasscode() async {
    final confirmed = await _showConfirmDialog('Reset Passcode',
        'Are you sure you want to reset the passcode to default?');

    if (confirmed) {
      final success = await SettingsService.resetPasscode();
      if (success) {
        _showMessage('Passcode reset to default');
        _loadCurrentPasscode();
      } else {
        _showMessage('Failed to reset passcode', isError: true);
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Management Methods
  void _showCompanyManagement() {
    if (!_isAdmin) {
      _showMessage('Only administrators can manage company settings',
          isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyManagementScreen()),
    ).then((_) => _loadCompanyData()); // Reload company data when returning
  }

  void _showEmployeeManagement() {
    if (!_hasCompany) {
      _showCompanyRequiredDialog('employees');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeManagementScreen()),
    );
  }

  void _showCategoryManagement() {
    if (!_hasCompany) {
      _showCompanyRequiredDialog('service categories');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );
  }

  void _showItemManagement() {
    if (!_hasCompany) {
      _showCompanyRequiredDialog('services and products');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemManagementScreen()),
    );
  }

  void _showSampleDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Sample Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text('This will load sample nail salon data including:'),
            SizedBox(height: 12),
            Text('• 4 Service categories'),
            Text('• 9 Sample services and products'),
            Text('• Pricing and duration information'),
            SizedBox(height: 12),
            Text('This is perfect for testing and demo purposes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSampleData();
            },
            child: const Text('Load Sample Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSampleData() async {
    try {
      // Load sample categories first
      for (final category in SampleItems.categories) {
        await ManagementService.createCategory(category);
      }

      // Load sample items
      for (final item in SampleItems.items) {
        await ManagementService.createItem(item);
      }

      _showMessage(
          'Sample data loaded successfully! All data saved to Firebase.');
    } catch (e) {
      _showMessage('Failed to load sample data: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Text(
                  'System Setup',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure system settings and security',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),

            // User Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Current User',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Name: ${widget.currentEmployee.fullName}'),
                    Text('Email: ${widget.currentEmployee.email}'),
                    Text(
                        'Role: ${widget.currentEmployee.role.toString().split('.').last}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Security Settings Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Security Settings',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Current Passcode Status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDefaultPasscode
                            ? Colors.amber[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _isDefaultPasscode ? Colors.amber : Colors.green,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isDefaultPasscode
                                ? Icons.warning
                                : Icons.check_circle,
                            color: _isDefaultPasscode
                                ? Colors.amber[700]
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isDefaultPasscode
                                      ? 'Using Default Passcode'
                                      : 'Custom Passcode Set',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isDefaultPasscode
                                        ? Colors.amber[700]
                                        : Colors.green[700],
                                  ),
                                ),
                                Text(
                                  _isDefaultPasscode
                                      ? 'Consider changing the default passcode for security'
                                      : 'Passcode has been customized',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isDefaultPasscode
                                        ? Colors.amber[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change Passcode Section
                    Text(
                      'Change Passcode',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passcodeController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'New Passcode',
                        hintText: 'Enter at least 4 characters',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                !_hasPasscodeText ? null : _changePasscode,
                            icon: const Icon(Icons.save),
                            label: const Text('Update Passcode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _resetPasscode,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Setup Options
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'System Configuration',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Company Status Banner
                    if (_isLoadingCompany)
                      const LinearProgressIndicator()
                    else if (!_hasCompany)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company Setup Required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  Text(
                                    _isAdmin
                                        ? 'Set up your company first to unlock all features'
                                        : 'Ask an admin to set up the company first',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company: ${_currentCompany!.name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    'Company is set up and ready',
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Company Settings - Only visible to admins
                    if (_isAdmin)
                      ListTile(
                        leading: const Icon(Icons.business, color: Colors.blue),
                        title: const Text('Company Settings'),
                        subtitle:
                            const Text('Business information and preferences'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _showCompanyManagement,
                      ),

                    // Employee Management
                    ListTile(
                      enabled: _hasCompany,
                      leading: Icon(
                        Icons.people,
                        color: _hasCompany ? Colors.green : Colors.grey,
                      ),
                      title: const Text('Employee Management'),
                      subtitle: Text(
                        _hasCompany
                            ? 'Manage staff roles and permissions'
                            : 'Company setup required first',
                      ),
                      trailing: _hasCompany
                          ? const Icon(Icons.arrow_forward_ios)
                          : const Icon(Icons.lock, color: Colors.grey),
                      onTap: _showEmployeeManagement,
                    ),

                    // Item Categories
                    ListTile(
                      enabled: _hasCompany,
                      leading: Icon(
                        Icons.category,
                        color: _hasCompany ? Colors.orange : Colors.grey,
                      ),
                      title: const Text('Service Categories'),
                      subtitle: Text(
                        _hasCompany
                            ? 'Manage service and product categories'
                            : 'Company setup required first',
                      ),
                      trailing: _hasCompany
                          ? const Icon(Icons.arrow_forward_ios)
                          : const Icon(Icons.lock, color: Colors.grey),
                      onTap: _showCategoryManagement,
                    ),

                    // Items/Services
                    ListTile(
                      enabled: _hasCompany,
                      leading: Icon(
                        Icons.inventory,
                        color: _hasCompany ? Colors.purple : Colors.grey,
                      ),
                      title: const Text('Services & Products'),
                      subtitle: Text(
                        _hasCompany
                            ? 'Manage salon services and retail items'
                            : 'Company setup required first',
                      ),
                      trailing: _hasCompany
                          ? const Icon(Icons.arrow_forward_ios)
                          : const Icon(Icons.lock, color: Colors.grey),
                      onTap: _showItemManagement,
                    ),

                    // Sample Data
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.download, color: Colors.indigo),
                      title: const Text('Load Sample Data'),
                      subtitle:
                          const Text('Initialize with nail salon sample data'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showSampleDataDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
