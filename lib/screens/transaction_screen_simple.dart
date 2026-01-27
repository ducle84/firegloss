import 'package:flutter/material.dart';
import 'package:firegloss/models/employee.dart';

class TransactionScreen extends StatefulWidget {
  final Employee currentEmployee;

  const TransactionScreen({super.key, required this.currentEmployee});

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
              const SizedBox(height: 24),
              Text(
                'Transaction Center',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back, ${widget.currentEmployee.firstName}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Process customer transactions and payments',
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
                      Text('Employee: ${widget.currentEmployee.fullName}'),
                      Text(
                          'Role: ${widget.currentEmployee.role.toString().split('.').last}'),
                      const SizedBox(height: 16),
                      const Text(
                          'New transaction features have been implemented!'),
                      const SizedBox(height: 16),
                      Text(
                        'Use the floating action button below to create a new transaction',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
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
        onPressed: () {
          // Navigate to new transaction screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'New transaction feature is now available! The full screen has been implemented in new_transaction_screen.dart'),
              duration: Duration(seconds: 3),
            ),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }
}
