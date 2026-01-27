import 'package:flutter/material.dart';
import 'package:firegloss/models/employee.dart';

class ReportsScreen extends StatefulWidget {
  final Employee currentEmployee;

  const ReportsScreen({super.key, required this.currentEmployee});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
                Icons.assessment,
                size: 100,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),
              Text(
                'Reports & Analytics',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'View financial reports and business analytics',
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
                      Icon(
                        Icons.lock,
                        color: Colors.amber,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sensitive Area',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                          'Financial reports and analytics coming soon...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
