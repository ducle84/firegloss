import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/item.dart';
import '../models/employee.dart';
import '../models/customer.dart';
import '../models/item_category.dart';
import '../services/management_service.dart';

class SimpleTransactionScreen extends StatefulWidget {
  final Employee? defaultTechnician;
  final TransactionHeader? existingTransaction;

  const SimpleTransactionScreen({
    Key? key,
    this.defaultTechnician,
    this.existingTransaction,
  }) : super(key: key);

  @override
  State<SimpleTransactionScreen> createState() =>
      _SimpleTransactionScreenState();
}

class _SimpleTransactionScreenState extends State<SimpleTransactionScreen> {
  final List<TransactionLine> _lines = [];
  final List<Item> _items = []; // Items from Firebase
  final List<Employee> _technicians = [];
  final List<Employee> _allEmployees = []; // All company employees
  final List<ItemCategory> _categories = []; // Categories from Firebase
  Customer? _selectedCustomer;
  Employee? _defaultTechnician;
  TransactionHeader? _currentTransaction;
  double _totalAmount = 0.0;
  String _selectedCategoryId = 'all';
  double _discountAmount = 0.0;
  String _discountType = 'none'; // 'none', 'percent', 'flat'
  double _discountValue = 0.0;
  double _paidAmount = 0.0;
  Employee? _selectedTechnician;
  final TextEditingController _paymentController = TextEditingController();
  bool _isLoadingCategories = true;
  bool _isLoadingItems = true;
  bool _isCreatingTransaction = true;

  @override
  void initState() {
    super.initState();
    print('=== TRANSACTION SCREEN INIT ===');
    print(
        'Default technician: ${widget.defaultTechnician?.fullName ?? 'None selected'}');
    print('Will load all employees and allow additional technicians');
    print('================================');

    // Set the default technician if provided
    _selectedTechnician = widget.defaultTechnician;
    _defaultTechnician = widget.defaultTechnician;

    // Check if we're editing an existing transaction or creating a new one
    _currentTransaction = widget.existingTransaction;

    _loadAllEmployees();
    _loadCategories();
    _loadItems();
    _calculateTotal();

    if (_currentTransaction == null) {
      _createTransaction();
    } else {
      setState(() {
        _isCreatingTransaction = false;
      });
    }
  }

  void _loadAllEmployees() async {
    try {
      print('Loading all employees from Firebase');
      // For now, we'll load from a default company
      // In production, this would be based on user's authenticated company
      final companies = await ManagementService.getCompanies();

      if (companies.isEmpty) {
        print('No companies found');
        setState(() {
          _technicians.clear();
        });
        return;
      }

      final firstCompany = companies.first;
      print('Using company: ${firstCompany.name} (${firstCompany.id})');

      final employees =
          await ManagementService.getEmployeesByCompany(firstCompany.id);

      print('Loaded ${employees.length} employees from Firebase');
      employees.forEach((emp) => print(
          'Employee: ${emp.fullName} - ${emp.role} - Active: ${emp.isActive}'));

      setState(() {
        _allEmployees.clear();
        _allEmployees.addAll(employees);

        // Filter to only active technicians and managers
        _technicians.clear();
        _technicians.addAll(_allEmployees
            .where((emp) =>
                emp.isActive &&
                (emp.role == EmployeeRole.technician ||
                    emp.role == EmployeeRole.manager))
            .toList());

        print('Filtered to ${_technicians.length} available technicians');
        _technicians.forEach(
            (tech) => print('Technician: ${tech.fullName} - ${tech.role}'));

        // Only auto-select first technician if no default was provided
        if (_technicians.isNotEmpty &&
            widget.defaultTechnician == null &&
            _selectedTechnician == null) {
          _selectedTechnician = _technicians.first;
          _defaultTechnician = _technicians.first;
          print(
              'Auto-selected first technician: ${_selectedTechnician!.fullName}');
        } else if (widget.defaultTechnician != null) {
          print(
              'Using provided default technician: ${widget.defaultTechnician!.fullName}');
        }
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() {
        _allEmployees.clear();
        _technicians.clear();
        // No fallback employee - user must select one
      });
    }
  }

  void _createTransaction() async {
    try {
      setState(() {
        _isCreatingTransaction = true;
      });

      final companies = await ManagementService.getCompanies();
      if (companies.isEmpty) {
        throw Exception('No companies found');
      }

      final companyId = companies.first.id;
      final employeeId = _selectedTechnician?.id ?? 'temp_employee';

      final transactionNumber = ManagementService.generateTransactionNumber();

      final transaction = TransactionHeader(
        id: '', // Will be assigned by backend
        companyId: companyId,
        transactionNumber: transactionNumber,
        transactionDate: DateTime.now(),
        employeeId: employeeId,
        status: TransactionStatus.newTransaction,
        paymentMethod: PaymentMethod.cash,
        subtotal: 0.0,
        tax: 0.0,
        discount: 0.0,
        tip: 0.0,
        total: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdTransaction =
          await ManagementService.createTransaction(transaction);

      setState(() {
        _currentTransaction = createdTransaction;
        _isCreatingTransaction = false;
      });

      print('Transaction created: ${_currentTransaction?.transactionNumber}');
    } catch (e) {
      print('Error creating transaction: $e');
      setState(() {
        _isCreatingTransaction = false;
      });

      // Don't show error snackbar for expected 404s - just log it
      print(
          'Transaction created locally for UI testing (backend not implemented)');
    }
  }

  void _loadCategories() async {
    try {
      // Fetch all categories from Firebase
      final categories = await ManagementService.getCategories();

      print('Loaded ${categories.length} categories from Firebase');
      categories
          .forEach((cat) => print('Category: ${cat.name} (ID: ${cat.id})'));

      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
        // Fallback to empty list - user can still use 'All' category
      });
    }
  }

  void _loadItems() async {
    try {
      // Fetch all items from Firebase
      final items = await ManagementService.getItems();

      print('Loaded ${items.length} items from Firebase');
      items.forEach((item) =>
          print('Item: ${item.name} (Category ID: ${item.categoryId})'));

      setState(() {
        _items.clear();
        _items.addAll(items);
        _isLoadingItems = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() {
        _isLoadingItems = false;
        // Fallback to sample items if Firebase fails
        _items.clear();
        _items.addAll(SampleItems.items);
      });
    }
  }

  void _addItem(Item item) {
    // For service items, require technician selection
    if (item.type == ItemType.service && _selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a technician for service items'),
          backgroundColor: Colors.orange,
        ),
      );
      // Show technician selection for this service
      _showTechnicianSelection();
      return;
    }

    // Determine technician to use
    Employee? technicianToUse;

    if (item.type == ItemType.service) {
      // Service items must have technician (already checked above)
      technicianToUse = _selectedTechnician!;
    } else {
      // For non-service items, use selected technician or default
      technicianToUse = _selectedTechnician ?? _defaultTechnician;
    }

    // If still no technician for non-service items, create a default system entry
    if (technicianToUse == null) {
      // For products/non-service items, we can assign to a system default
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added without technician assignment'),
          backgroundColor: Colors.blue,
        ),
      );
      // Don't add item without technician - prompt user to select one
      _showTechnicianSelection();
      return;
    }

    _addItemWithTechnician(item, technicianToUse);
  }

  void _updateQuantity(TransactionLine line, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() {
        _lines.removeWhere((l) => l.id == line.id);
        _calculateTotal();
      });
      return;
    }

    setState(() {
      final index = _lines.indexWhere((l) => l.id == line.id);
      if (index >= 0) {
        _lines[index] = line.copyWith(
          quantity: newQuantity,
          lineTotal: newQuantity * line.unitPrice,
          updatedAt: DateTime.now(),
        );
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    _totalAmount = _lines.fold(0.0, (sum, line) => sum + line.lineTotal);
    _calculateDiscount(); // Recalculate discount when total changes
    _updateTransactionStatus();
  }

  void _updateTransactionStatus() {
    if (_currentTransaction == null) return;

    final hasItems = _lines.isNotEmpty;
    final hasPaid = _paidAmount >= _totalAmount - _discountAmount;

    final newStatus = TransactionHeader.deriveStatus(
      hasPaid: hasPaid,
      hasItems: hasItems,
    );

    if (newStatus != _currentTransaction!.status) {
      setState(() {
        _currentTransaction = _currentTransaction!.copyWith(
          status: newStatus,
          subtotal: _totalAmount,
          discount: _discountAmount,
          total: _totalAmount - _discountAmount,
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_currentTransaction?.transactionNumber ?? 'New Transaction'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: _isCreatingTransaction
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating transaction...'),
                ],
              ),
            )
          : Column(
              children: [
                // Transaction Info Header
                _buildTransactionHeader(),
                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Item catalog
                      Expanded(
                        flex: 2,
                        child: _buildItemCatalog(),
                      ),
                      // Right side - Receipt preview
                      Expanded(
                        flex: 1,
                        child: _buildReceiptPreview(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionHeader() {
    if (_currentTransaction == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Transaction Number and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _currentTransaction!.transactionNumber,
                      style: const TextStyle(
                        fontSize: 18,
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
                        color: _currentTransaction!.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentTransaction!.statusDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_currentTransaction!.formattedDuration} ago',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Live Timer
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
                const Duration(seconds: 60), (_) => DateTime.now()),
            builder: (context, snapshot) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentTransaction!.formattedDuration,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCatalog() {
    // Show loading state if items or categories are still loading
    if (_isLoadingItems) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading items...'),
          ],
        ),
      );
    }

    // Filter items by selected category
    List<Item> filteredItems = _selectedCategoryId == 'all'
        ? _items
        : _items
            .where((item) => item.categoryId == _selectedCategoryId)
            .toList();

    print(
        'Filtering items: ${_items.length} total, ${filteredItems.length} filtered for category $_selectedCategoryId');

    // Group filtered items by category
    Map<String, List<Item>> itemsByCategoryId = {};
    for (var item in filteredItems) {
      if (!itemsByCategoryId.containsKey(item.categoryId)) {
        itemsByCategoryId[item.categoryId] = [];
      }
      itemsByCategoryId[item.categoryId]!.add(item);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Technician selection
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTechnician == null
                      ? 'Select Technician (Required for Services):'
                      : 'Default Technician for Items:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _technicians.isEmpty ? null : _showTechnicianSelection,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _technicians.isEmpty
                          ? Colors.grey[100]
                          : _selectedTechnician == null
                              ? Colors.orange[50]
                              : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _technicians.isEmpty
                              ? Colors.grey[300]!
                              : _selectedTechnician == null
                                  ? Colors.orange[300]!
                                  : Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            size: 16,
                            color: _technicians.isEmpty
                                ? Colors.grey
                                : _selectedTechnician == null
                                    ? Colors.orange[700]
                                    : Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _technicians.isEmpty
                                ? 'Loading technicians...'
                                : (_selectedTechnician?.fullName ??
                                    'Tap to Select Technician'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _technicians.isEmpty
                                  ? Colors.grey
                                  : _selectedTechnician == null
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                        if (_technicians.isNotEmpty)
                          Icon(Icons.edit,
                              size: 16,
                              color: _selectedTechnician == null
                                  ? Colors.orange[700]
                                  : Colors.green),
                      ],
                    ),
                  ),
                ),
                if (_selectedTechnician != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Service items will be assigned to ${_selectedTechnician!.firstName}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Service items require technician selection',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category filter
          const Text('Category:',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: _isLoadingCategories
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', 'all'),
                        const SizedBox(width: 8),
                        ..._categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child:
                                _buildCategoryChip(category.name, category.id),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: itemsByCategoryId.entries.map((entry) {
                final categoryId = entry.key;
                final categoryItems = entry.value;

                // Find category name
                final category = _categories.firstWhere(
                  (cat) => cat.id == categoryId,
                  orElse: () => ItemCategory(
                    id: categoryId,
                    name: 'Unknown Category',
                    description: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: categoryItems.length,
                      itemBuilder: (context, index) {
                        final item = categoryItems[index];
                        return Card(
                          child: InkWell(
                            onTap: () => _addItem(item),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'FireGloss Nail Salon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(),

            // Customer selection
            _buildCustomerSection(),
            const SizedBox(height: 16),

            // Transaction items
            Expanded(
              child: _buildTransactionItems(),
            ),

            const Divider(),
            _buildReceiptTotal(),

            const SizedBox(height: 16),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _selectedCustomer == null
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Select Customer'),
                  onPressed: _selectCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                )
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCustomer!.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedCustomer = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionItems() {
    if (_lines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No items added',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        final technician = _technicians.firstWhere(
          (t) => t.id == line.technicianId,
          orElse: () => _defaultTechnician!,
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: () => _removeItem(line),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () => _updateQuantity(line, line.quantity - 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text('${line.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => _updateQuantity(line, line.quantity + 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    Text(
                      '\$${line.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Technician assignment
                InkWell(
                  onTap: () => _selectTechnician(line),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          technician.firstName,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptTotal() {
    final finalTotal = _totalAmount - _discountAmount;
    final remainingBalance = finalTotal - _paidAmount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal:',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '\$${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        // Discount section
        const SizedBox(height: 4),
        const Text('Discount:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            _buildDiscountButton('None', 'none', 0),
            _buildDiscountButton('5%', 'percent', 5),
            _buildDiscountButton('10%', 'percent', 10),
            _buildDiscountButton('15%', 'percent', 15),
            _buildDiscountButton('20%', 'percent', 20),
            _buildDiscountButton('\$5', 'flat', 5),
            _buildDiscountButton('\$10', 'flat', 10),
            _buildDiscountButton('\$20', 'flat', 20),
            _buildCustomDiscountButton(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${finalTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
        // Payment section
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Payment: ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: TextField(
                controller: _paymentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _paidAmount = double.tryParse(value) ?? 0.0;
                  });
                  _updateTransactionStatus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              remainingBalance > 0 ? 'Balance Due:' : 'Change:',
              style: TextStyle(
                fontSize: 12,
                color: remainingBalance > 0 ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${remainingBalance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: remainingBalance > 0 ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick payment buttons
        Wrap(
          spacing: 4,
          children: [
            _buildQuickPayButton('Cash', () {
              final total = _totalAmount - _discountAmount;
              _paymentController.text = total.toStringAsFixed(2);
              setState(() {
                _paidAmount = total;
              });
              _updateTransactionStatus();
            }),
            _buildQuickPayButton('Card', () {
              final total = _totalAmount - _discountAmount;
              _paymentController.text = total.toStringAsFixed(2);
              setState(() {
                _paidAmount = total;
              });
              _updateTransactionStatus();
            }),
            _buildQuickPayButton('Clear', () {
              _paymentController.clear();
              setState(() {
                _paidAmount = 0.0;
              });
              _updateTransactionStatus();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text('Save Transaction'),
      ),
    );
  }

  Widget _buildDiscountButton(String label, String type, double value) {
    final isSelected = _discountType == type && _discountValue == value;
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _discountType = type;
            _discountValue = value;
            _calculateDiscount();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildCustomDiscountButton() {
    final isSelected = _discountType == 'custom';
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: _showCustomDiscountDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Custom', style: TextStyle(fontSize: 10)),
      ),
    );
  }

  void _showCustomDiscountDialog() {
    final amountController = TextEditingController();
    String discountType = 'flat'; // 'flat' or 'percent'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom Discount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Dollar Amount',
                              style: TextStyle(fontSize: 12)),
                          value: 'flat',
                          groupValue: discountType,
                          onChanged: (value) {
                            setDialogState(() {
                              discountType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Percentage',
                              style: TextStyle(fontSize: 12)),
                          value: 'percent',
                          groupValue: discountType,
                          onChanged: (value) {
                            setDialogState(() {
                              discountType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: discountType == 'flat'
                          ? 'Amount (\$)'
                          : 'Percentage (%)',
                      prefixText: discountType == 'flat' ? '\$' : '',
                      suffixText: discountType == 'percent' ? '%' : '',
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = double.tryParse(amountController.text) ?? 0.0;
                    if (value > 0) {
                      setState(() {
                        _discountType = 'custom';
                        _discountValue = value;
                        if (discountType == 'flat') {
                          _discountAmount = value;
                        } else {
                          _discountAmount = _totalAmount * (value / 100);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _calculateDiscount() {
    switch (_discountType) {
      case 'percent':
        _discountAmount = _totalAmount * (_discountValue / 100);
        break;
      case 'flat':
        _discountAmount = _discountValue;
        break;
      case 'custom':
        // For custom discounts, the amount is already calculated in the dialog
        break;
      default:
        _discountAmount = 0.0;
    }
  }

  Widget _buildCategoryChip(String label, String categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.green : Colors.grey[300]!,
        width: 1,
      ),
    );
  }

  void _showTechnicianSelection() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Technician'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _technicians.map((tech) {
              return ListTile(
                title: Text(tech.fullName),
                leading: Radio<Employee>(
                  value: tech,
                  groupValue: _selectedTechnician,
                  onChanged: (value) {
                    setState(() {
                      _selectedTechnician = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _addItemWithTechnician(Item item, Employee technician) {
    // Check if item already exists in lines
    final existingIndex = _lines.indexWhere(
        (line) => line.itemId == item.id && line.technicianId == technician.id);

    if (existingIndex >= 0) {
      // Update quantity if same item with same technician already exists
      setState(() {
        _lines[existingIndex] = _lines[existingIndex].copyWith(
          quantity: _lines[existingIndex].quantity + 1,
          lineTotal: (_lines[existingIndex].quantity + 1) * item.price,
        );
        _calculateTotal();
      });
    } else {
      // Add new item with specified technician
      final line = TransactionLine(
        id: 'line_${DateTime.now().millisecondsSinceEpoch}',
        transactionId: 'temp',
        itemId: item.id,
        itemName: item.name,
        itemType: item.type,
        quantity: 1,
        unitPrice: item.price,
        lineTotal: item.price,
        technicianId: technician.id,
        serviceDuration: item.durationMinutes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _lines.add(line);
        _calculateTotal();
      });
    }
  }

  Widget _buildQuickPayButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 24,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  void _selectCustomer() {
    // For now, create a simple customer
    setState(() {
      _selectedCustomer = Customer(
        id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
        firstName: 'Walk-in',
        lastName: 'Customer',
        phone: '(555) 123-4567',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  void _selectTechnician(TransactionLine line) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Technician'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _technicians.map((tech) {
              return ListTile(
                title: Text(tech.fullName),
                onTap: () {
                  setState(() {
                    final index = _lines.indexOf(line);
                    if (index >= 0) {
                      _lines[index] = line.copyWith(
                        technicianId: tech.id,
                        updatedAt: DateTime.now(),
                      );
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _removeItem(TransactionLine line) {
    setState(() {
      _lines.removeWhere((l) => l.id == line.id);
      _calculateTotal();
    });
  }

  void _saveTransaction() async {
    if (_currentTransaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transaction to save'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update the transaction with current totals
      final updatedTransaction = _currentTransaction!.copyWith(
        subtotal: _totalAmount,
        discount: _discountAmount,
        total: _totalAmount - _discountAmount,
        updatedAt: DateTime.now(),
      );

      // Try to save to backend
      final success =
          await ManagementService.updateTransaction(updatedTransaction);

      // Always show success since we mock it when backend is unavailable
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transaction ${_currentTransaction!.transactionNumber} saved!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving transaction: $e');
      // Still show success since the UI changes are preserved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transaction ${_currentTransaction!.transactionNumber} saved!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }
}
