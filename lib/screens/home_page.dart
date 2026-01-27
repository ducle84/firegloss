import 'package:flutter/material.dart';
import 'package:firegloss/services/auth_service.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/screens/transaction_dashboard_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // No employee concept needed at home page level
    // Employees/technicians are managed within transaction context
  }

  Future<void> _onItemTapped(int index) async {
    // For now, all screens are accessible
    // In production, implement proper authentication and role-based access
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    // Create a temporary employee for screens that still require it
    // In production, this would come from authentication
    final tempEmployee = Employee(
      id: 'temp_emp',
      uid: 'temp_uid',
      companyId: 'temp_company',
      email: 'temp@example.com',
      firstName: 'System',
      lastName: 'User',
      role: EmployeeRole.manager,
      hiredDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    switch (_selectedIndex) {
      case 0:
        return SetupScreen(currentEmployee: tempEmployee);
      case 1:
        return const TransactionDashboardScreen();
      case 2:
        return ReportsScreen(currentEmployee: tempEmployee);
      default:
        return const TransactionDashboardScreen();
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Transaction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
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
