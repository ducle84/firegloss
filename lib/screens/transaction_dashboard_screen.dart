import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firegloss/models/transaction.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/services/management_service.dart';
import 'package:firegloss/screens/simple_transaction_screen.dart';

class TransactionDashboardScreen extends StatefulWidget {
  const TransactionDashboardScreen({super.key});

  @override
  State<TransactionDashboardScreen> createState() =>
      _TransactionDashboardScreenState();
}

class _TransactionDashboardScreenState
    extends State<TransactionDashboardScreen> {
  List<TransactionHeader> _transactions = [];
  Map<String, Employee> _employees = {};
  Map<String, List<TransactionLine>> _transactionLines = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Force rebuild to update running timers and "created ago" times
        });
      }
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await ManagementService.getTransactions();

      // Load employees for technician names
      await _loadEmployees();

      // Load transaction lines for each transaction
      await _loadTransactionLines(transactions);

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      // Only log to console - the developer notice card provides UI feedback
      if (transactions.isEmpty && mounted) {
        print(
            'Transaction backend not implemented. UI is functional for testing.');
      }
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
      // Remove the snackbar notification since this is expected behavior
      print('Transaction backend not available. Using local UI testing mode.');
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final companies = await ManagementService.getCompanies();
      if (companies.isNotEmpty) {
        final employees =
            await ManagementService.getEmployeesByCompany(companies.first.id);
        _employees.clear();
        for (final employee in employees) {
          _employees[employee.id] = employee;
        }
      }
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  Future<void> _loadTransactionLines(
      List<TransactionHeader> transactions) async {
    try {
      for (final transaction in transactions) {
        final lines =
            await ManagementService.getTransactionLines(transaction.id);
        _transactionLines[transaction.id] = lines;
      }
    } catch (e) {
      print('Error loading transaction lines: $e');
      // Don't fail the entire load process if lines fail
    }
  }

  List<TransactionHeader> get _filteredTransactions {
    if (_selectedFilter == 'all') {
      return _transactions;
    }

    // Check if it's a technician filter (starts with 'tech_')
    if (_selectedFilter.startsWith('tech_')) {
      final technicianId =
          _selectedFilter.substring(5); // Remove 'tech_' prefix
      return _transactions.where((t) => t.employeeId == technicianId).toList();
    }

    switch (_selectedFilter) {
      case 'new':
        return _transactions
            .where((t) => t.status == TransactionStatus.newTransaction)
            .toList();
      case 'in_progress':
        return _transactions
            .where((t) => t.status == TransactionStatus.inProgress)
            .toList();
      case 'complete':
        return _transactions
            .where((t) => t.status == TransactionStatus.complete)
            .toList();
      default:
        return _transactions;
    }
  }

  List<Employee> get _techniciansWithTransactions {
    final technicianIds = _transactions.map((t) => t.employeeId).toSet();
    return _employees.values
        .where((employee) => technicianIds.contains(employee.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Developer Notice
          if (_transactions.isEmpty) _buildDeveloperNotice(),
          // Status Summary Cards
          _buildStatusSummary(),
          // Filters
          _buildFilters(),
          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTechnicianSelectionDialog();
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildDeveloperNotice() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developer Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Transaction backend endpoints are not yet implemented. Transactions are created locally for UI testing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    final summary = <String, int>{};
    for (final status in TransactionStatus.values) {
      summary[status.toString().split('.').last] =
          _transactions.where((t) => t.status == status).length;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Transaction Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard(
                  'New',
                  summary['newTransaction'] ?? 0,
                  Colors.blue,
                  Icons.fiber_new,
                ),
                _buildSummaryCard(
                  'In Progress',
                  summary['inProgress'] ?? 0,
                  Colors.purple,
                  Icons.hourglass_bottom,
                ),
                _buildSummaryCard(
                  'Complete',
                  summary['complete'] ?? 0,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildSummaryCard(
                  'Total',
                  _transactions.length,
                  Colors.grey[700]!,
                  Icons.receipt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filters
          Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('New', 'new'),
                      _buildFilterChip('In Progress', 'in_progress'),
                      _buildFilterChip('Complete', 'complete'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Technician filters (only show if there are technicians with transactions)
          if (_techniciansWithTransactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Technician: '),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _techniciansWithTransactions
                          .map((tech) => _buildFilterChip(
                                tech.firstName,
                                'tech_${tech.id}',
                                icon: Icons.person,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
          });
        },
        selectedColor: Colors.green.withOpacity(0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction backend is not yet implemented.',
            style: TextStyle(
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You can still create and test transactions - they just won\'t persist.',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(TransactionHeader transaction) {
    final employee = _employees[transaction.employeeId];
    final lines = _transactionLines[transaction.id] ?? [];
    final isComplete = transaction.status == TransactionStatus.complete;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openTransaction(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with transaction number, status, and total
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                transaction.transactionNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: transaction.statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  transaction.statusDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          transaction.formattedTotal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (!isComplete)
                          Text(
                            transaction.formattedDuration,
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Technician info
                if (employee != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Technician: ${employee.fullName}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Customer info
                if (transaction.customerName != null)
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 16,
                        color: Colors.purple[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Customer: ${transaction.customerName}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Items info
                if (lines.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items: ${lines.length} item${lines.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lines
                                      .take(2)
                                      .map((line) =>
                                          '• ${line.itemName} (${line.quantity})')
                                      .join('\\n') +
                                  (lines.length > 2
                                      ? '\\n• +${lines.length - 2} more items'
                                      : ''),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Bottom row with creation time and arrow
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${transaction.formattedDuration} ago',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (!isComplete)
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live Timer: ${transaction.formattedDuration}',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTransaction(TransactionHeader transaction) {
    // Get the transaction lines for this transaction
    final lines = _transactionLines[transaction.id] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleTransactionScreen(
          existingTransaction: transaction,
          existingTransactionLines: lines,
        ),
      ),
    ).then((_) => _loadTransactions());
  }

  void _showTechnicianSelectionDialog() async {
    try {
      // Load employees from the first available company
      final companies = await ManagementService.getCompanies();
      if (companies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No companies found. Please add a company first.')),
        );
        return;
      }

      final employees =
          await ManagementService.getEmployeesByCompany(companies.first.id);
      if (employees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No employees found. Please add an employee first.')),
        );
        return;
      }

      Employee? selectedTechnician = await showDialog<Employee>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Technician'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(employee.firstName.substring(0, 1)),
                    ),
                    title: Text(employee.fullName),
                    subtitle: Text(employee.role.toString().split('.').last),
                    onTap: () {
                      Navigator.of(context).pop(employee);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedTechnician != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleTransactionScreen(
              defaultTechnician: selectedTechnician,
            ),
          ),
        ).then((_) => _loadTransactions());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading employees: $e')),
      );
    }
  }
}
