import 'package:flutter/material.dart';
import 'package:firegloss/services/auth_service.dart';
import 'package:firegloss/services/passcode_service.dart';
import 'package:firegloss/models/employee.dart' as app_employee;
import 'package:firegloss/screens/transaction_screen.dart';
import 'package:firegloss/screens/setup_screen.dart';
import 'package:firegloss/screens/reports_screen.dart';
import 'package:firegloss/screens/backend_test_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Default to Transaction (index 1)
  late app_employee.Employee _currentEmployee;

  @override
  void initState() {
    super.initState();
    // For demo purposes, creating a default employee
    // In production, this would come from authentication
    final authService = AuthService();
    final firebaseUser = authService.currentUser;

    _currentEmployee = app_employee.Employee(
      id: 'emp_1',
      uid: firebaseUser?.uid ?? 'demo',
      companyId: 'comp_1',
      email: firebaseUser?.email ?? 'demo@firegloss.com',
      firstName: 'Demo',
      lastName: 'Employee',
      role: app_employee
          .EmployeeRole.manager, // Change this to test different roles
      hiredDate: DateTime.now().subtract(const Duration(days: 365)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _onItemTapped(int index) async {
    // Check if accessing sensitive screens
    if ((index == 0 || index == 2) &&
        !_currentEmployee.canAccessWithoutPasscode()) {
      // Setup or Reports screen - requires passcode for non-admin users
      if (_currentEmployee.canAccessSensitiveScreens()) {
        bool authorized = await PasscodeService.showPasscodeDialog(context);
        if (!authorized) return;
      } else {
        _showAccessDeniedDialog();
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Access Denied'),
            ],
          ),
          content:
              const Text('You do not have permission to access this area.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return SetupScreen(currentEmployee: _currentEmployee);
      case 1:
        return TransactionScreen(currentEmployee: _currentEmployee);
      case 2:
        return ReportsScreen(currentEmployee: _currentEmployee);
      default:
        return TransactionScreen(currentEmployee: _currentEmployee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.spa, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Nail Salon CRM'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Backend Test Button (for developers)
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackendTestPage(),
                ),
              );
            },
            tooltip: 'Backend Testing',
          ),
          // User Role Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _currentEmployee.role.toString().split('.').last.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.settings),
                if (!_currentEmployee.canAccessSensitiveScreens())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (_currentEmployee.canAccessSensitiveScreens() &&
                    !_currentEmployee.canAccessWithoutPasscode())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            label: 'Setup',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Transaction',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assessment),
                if (!_currentEmployee.canAccessSensitiveScreens())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (_currentEmployee.canAccessSensitiveScreens() &&
                    !_currentEmployee.canAccessWithoutPasscode())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
