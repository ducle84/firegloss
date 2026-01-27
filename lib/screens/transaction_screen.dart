import 'package:flutter/material.dart';
import 'package:firegloss/screens/simple_transaction_screen.dart';
import 'package:firegloss/screens/transaction_dashboard_screen.dart';
import 'package:firegloss/services/management_service.dart';
import 'package:firegloss/models/employee.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction Center',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Process customer transactions and payments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create transactions and assign technicians',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Ready to process transactions!'),
                      const SizedBox(height: 16),
                      Text(
                        'Use the button below to create a new transaction or view the dashboard to manage existing transactions',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionDashboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dashboard),
                        label: const Text('View Transaction Dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTechnicianSelectionDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }

  void _showTechnicianSelectionDialog() async {
    try {
      // Load companies and employees
      final companies = await ManagementService.getCompanies();

      if (companies.isEmpty) {
        _showNoDataDialog(
            'No companies found. Please set up your company first.');
        return;
      }

      final firstCompany = companies.first;
      final employees =
          await ManagementService.getEmployeesByCompany(firstCompany.id);

      final technicians = employees
          .where((emp) =>
              emp.isActive &&
              (emp.role == EmployeeRole.technician ||
                  emp.role == EmployeeRole.manager))
          .toList();

      if (technicians.isEmpty) {
        _showNoDataDialog(
            'No active technicians found. Please add technicians first.');
        return;
      }

      // Show technician selection dialog
      Employee? selectedTechnician = await showDialog<Employee>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Default Technician'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose a default technician for this transaction (optional):',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...technicians.map((tech) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(tech.fullName),
                    subtitle: Text(tech.role.toString().split('.').last),
                    onTap: () {
                      Navigator.pop(context, tech);
                    },
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, null), // No default technician
                child: const Text('Skip (No Default)'),
              ),
            ],
          );
        },
      );

      // Navigate to transaction screen with selected technician (or null)
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleTransactionScreen(
            defaultTechnician: selectedTechnician,
          ),
        ),
      );
    } catch (e) {
      print('Error loading technicians: $e');
      _showNoDataDialog('Error loading technicians. Please try again.');
    }
  }

  void _showNoDataDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Setup Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
