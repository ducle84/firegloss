import 'package:flutter/material.dart';
import 'package:firegloss/models/transaction.dart';
import 'package:firegloss/models/customer.dart';
import 'package:firegloss/models/employee.dart';
import 'package:firegloss/models/item.dart';
import 'package:firegloss/models/item_category.dart';
import 'package:firegloss/models/discount.dart';

class NewTransactionScreen extends StatefulWidget {
  final Employee currentEmployee;
  final Transaction? existingTransaction;

  const NewTransactionScreen({
    super.key,
    required this.currentEmployee,
    this.existingTransaction,
  });

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  late TransactionHeader _header;
  final List<TransactionLine> _lines = [];
  Customer? _selectedCustomer;
  Discount? _selectedDiscount;
  final List<Payment> _payments = [];
  Employee? _defaultTechnician;

  // Controllers
  final _notesController = TextEditingController();
  final _tipController = TextEditingController();
  final _taxRateController = TextEditingController(text: '8.25');

  // Sample data (in real app, load from service)
  final List<Customer> _customers = SampleCustomers.customers;
  final List<Employee> _technicians =
      _getSampleTechnicians(); // Load technicians from service
  final List<Item> _items = SampleItems.items;
  final List<Discount> _discounts = SampleDiscounts.discounts;

  // Sample technicians for demo
  static List<Employee> _getSampleTechnicians() {
    return [
      Employee(
        id: 'tech_1',
        uid: 'tech_uid_1',
        companyId: 'comp_1',
        email: 'sarah.johnson@firegloss.com',
        firstName: 'Sarah',
        lastName: 'Johnson',
        role: EmployeeRole.technician,
        hourlyRate: 25.0,
        commissionRate: 15.0,
        hiredDate: DateTime(2023, 1, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Employee(
        id: 'tech_2',
        uid: 'tech_uid_2',
        companyId: 'comp_1',
        email: 'mike.chen@firegloss.com',
        firstName: 'Mike',
        lastName: 'Chen',
        role: EmployeeRole.technician,
        hourlyRate: 30.0,
        commissionRate: 18.0,
        hiredDate: DateTime(2022, 8, 10),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Employee(
        id: 'tech_3',
        uid: 'tech_uid_3',
        companyId: 'comp_1',
        email: 'emily.davis@firegloss.com',
        firstName: 'Emily',
        lastName: 'Davis',
        role: EmployeeRole.manager,
        hourlyRate: 35.0,
        commissionRate: 20.0,
        hiredDate: DateTime(2021, 5, 20),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeTransaction();
  }

  void _initializeTransaction() {
    if (widget.existingTransaction != null) {
      _header = widget.existingTransaction!.header;
      _lines.addAll(widget.existingTransaction!.lines);
      // Load customer if exists
      if (_header.customerId != null) {
        _selectedCustomer = _customers.firstWhere(
          (c) => c.id == _header.customerId,
          orElse: () => Customer(
            id: _header.customerId!,
            firstName: _header.customerName?.split(' ').first ?? 'Unknown',
            lastName: _header.customerName?.split(' ').skip(1).join(' ') ?? '',
            phone: _header.customerPhone,
            email: _header.customerEmail,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    } else {
      _header = TransactionHeader(
        id: 'trans_${DateTime.now().millisecondsSinceEpoch}',
        companyId: widget.currentEmployee.companyId,
        transactionNumber:
            '#${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}${(DateTime.now().millisecond ~/ 100)}',
        transactionDate: DateTime.now(),
        employeeId: widget.currentEmployee.id,
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
    }

    // Set default technician (first available technician)
    if (_technicians.isNotEmpty) {
      _defaultTechnician = _technicians.first;
    }
    _notesController.text = _header.notes ?? '';
    _tipController.text = _header.tip > 0 ? _header.tip.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTransaction != null
            ? 'Edit Transaction'
            : 'New Transaction'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Left side - Item catalog
              Container(
                width: constraints.maxWidth * 0.7,
                child: _buildItemCatalog(),
              ),
              // Right side - Receipt preview with edit capabilities
              Container(
                width: constraints.maxWidth * 0.3,
                child: _buildReceiptPreview(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCatalog() {
    // Group items by category using categoryId
    Map<String, List<Item>> itemsByCategoryId = {};
    for (var item in _items) {
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
          // Header information
          _buildHeaderSection(),
          const SizedBox(height: 20),

          // Item catalog
          const Text(
            'Select Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: itemsByCategoryId.entries.map((entry) {
                String categoryId = entry.key;
                List<Item> items = entry.value;
                // Find the category object
                ItemCategory? category;
                try {
                  category = SampleItems.categories.firstWhere(
                    (c) => c.id == categoryId,
                  );
                } catch (e) {
                  // Create a fallback category if not found
                  category = ItemCategory(
                    id: categoryId,
                    name: 'Unknown Category',
                    description: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                }
                return _buildCategorySection(category, items);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ItemCategory category, List<Item> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${items.length} items'),
        initiallyExpanded: true,
        children: items.map((item) => _buildItemTile(item)).toList(),
      ),
    );
  }

  Widget _buildItemTile(Item item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.formattedPrice),
      trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
      onTap: () => _addItemToTransaction(item),
    );
  }

  void _addItemToTransaction(Item item) {
    final line = TransactionLine(
      id: 'line_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: _header.id,
      itemId: item.id,
      itemName: item.name,
      itemType: item.type,
      quantity: 1,
      unitPrice: item.price,
      lineTotal: item.price * 1, // quantity * unitPrice
      technicianId: _defaultTechnician?.id,
      serviceDuration: item.durationMinutes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _lines.add(line);
      _calculateTotals();
    });
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transaction #: ${_header.transactionNumber}'),
                      const SizedBox(height: 8),
                      Text('Date: ${_formatDate(_header.transactionDate)}'),
                      const SizedBox(height: 8),
                      Text('Employee: ${widget.currentEmployee.fullName}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Status: '),
                          _buildStatusDropdown(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildCustomerSelector(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _updateHeader(notes: value),
                  ),
                ),
                const SizedBox(width: 16),
                _buildDiscountSelector(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButton<TransactionStatus>(
      value: _header.status,
      items: TransactionStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(_getStatusName(status)),
        );
      }).toList(),
      onChanged: (status) {
        if (status != null) {
          _updateHeader(status: status);
        }
      },
    );
  }

  String _getStatusName(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.newTransaction:
        return 'New';
      case TransactionStatus.assigned:
        return 'Assigned';
      case TransactionStatus.inProgress:
        return 'In Progress';
      case TransactionStatus.onHold:
        return 'On Hold';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.voided:
        return 'Voided';
      case TransactionStatus.complete:
        return 'Complete';
    }
  }

  Widget _buildCustomerSelector() {
    return Row(
      children: [
        Expanded(
          child: _selectedCustomer == null
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Select Customer'),
                  onPressed: _selectCustomer,
                )
              : Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(_selectedCustomer!.displayName),
                  onDeleted: () => _clearCustomer(),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: _addNewCustomer,
          tooltip: 'Add New Customer',
        ),
      ],
    );
  }

  Widget _buildDiscountSelector() {
    return DropdownButtonFormField<Discount>(
      value: _selectedDiscount,
      decoration: const InputDecoration(
        labelText: 'Discount',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: _discounts.where((d) => d.isValid).map((discount) {
        return DropdownMenuItem(
          value: discount,
          child: Text(
            discount.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (discount) {
        setState(() {
          _selectedDiscount = discount;
          _calculateTotals();
        });
      },
    );
  }

  Widget _buildTransactionLines() {
    if (_lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Tap the + button to add items'),
          ],
        ),
      );
    }

    // Group lines by technician
    Map<String?, List<TransactionLine>> linesByTech = {};
    for (var line in _lines) {
      String? techId = line.technicianId;
      if (!linesByTech.containsKey(techId)) {
        linesByTech[techId] = [];
      }
      linesByTech[techId]!.add(line);
    }

    return ListView.builder(
      itemCount: linesByTech.length,
      itemBuilder: (context, index) {
        var techId = linesByTech.keys.elementAt(index);
        var techLines = linesByTech[techId]!;
        var techName = techId != null
            ? _technicians
                .firstWhere((t) => t.id == techId,
                    orElse: () => Employee(
                          id: techId,
                          uid: '',
                          companyId: '',
                          email: '',
                          firstName: 'Unknown',
                          lastName: 'Technician',
                          role: EmployeeRole.technician,
                          hiredDate: DateTime.now(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ))
                .fullName
            : 'Unassigned';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Technician header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: techId != null ? Colors.green[50] : Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: techId != null ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      techName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: techId != null
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${techLines.fold(0.0, (sum, line) => sum + line.lineTotal).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              // Lines for this technician
              ...techLines.map((line) => _buildTransactionLineItem(line)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionLineItem(TransactionLine line) {
    return ListTile(
      leading: Icon(
        line.isService ? Icons.design_services : Icons.inventory_2,
        color: line.isService ? Colors.blue : Colors.orange,
      ),
      title: Text(line.itemName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${line.formattedUnitPrice} × ${line.quantity}'),
          if (line.isService && line.serviceDuration != null)
            Text('Duration: ${line.formattedDuration}'),
          if (line.notes?.isNotEmpty == true) Text('Notes: ${line.notes}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line.formattedLineTotal,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editLine(line),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _removeLine(line),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Transaction Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _getDerivedStatus(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildReceipt(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDerivedStatus() {
    if (_lines.isEmpty) return 'NEW';
    if (_payments.isEmpty) return 'PENDING';
    final total = _calculateTotal();
    final paidAmount = _payments.fold(0.0, (sum, p) => sum + p.amount);
    if (paidAmount >= total) return 'COMPLETE';
    if (paidAmount > 0) return 'PARTIAL';
    return 'PENDING';
  }

  Widget _buildReceipt() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'FireGloss Nail Salon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const Divider(),

            // Customer info
            if (_selectedCustomer != null) ...[
              Text('Customer: ${_selectedCustomer!.displayName}'),
              if (_selectedCustomer!.phone != null)
                Text('Phone: ${_selectedCustomer!.phone}'),
              const SizedBox(height: 8),
            ],

            Text('Transaction: ${_header.transactionNumber}'),
            Text('Date: ${_formatDate(_header.transactionDate)}'),
            const SizedBox(height: 16),

            // Customer and discount selectors
            _buildCustomerSection(),
            const SizedBox(height: 16),

            // Transaction items with edit capabilities
            Expanded(
              child: SingleChildScrollView(
                child: _buildEditableTransactionItems(),
              ),
            ),

            const Divider(),
            _buildReceiptTotals(),

            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomerSelector(),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildDiscountSelector(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _tipController,
                  decoration: const InputDecoration(
                    labelText: 'Tip',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateTotals(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTransactionItems() {
    if (_lines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No items added',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Select items from the catalog',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Group lines by technician
    Map<String?, List<TransactionLine>> linesByTech = {};
    for (var line in _lines) {
      String? techId = line.technicianId;
      if (!linesByTech.containsKey(techId)) {
        linesByTech[techId] = [];
      }
      linesByTech[techId]!.add(line);
    }

    return Column(
      children: linesByTech.entries.map((entry) {
        String? techId = entry.key;
        List<TransactionLine> techLines = entry.value;
        String techName = techId != null
            ? _technicians
                .firstWhere(
                  (t) => t.id == techId,
                  orElse: () => Employee(
                    id: 'unknown',
                    uid: 'unknown',
                    companyId: '',
                    email: '',
                    firstName: 'Unknown',
                    lastName: 'Technician',
                    role: EmployeeRole.technician,
                    hiredDate: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                )
                .fullName
            : 'Unassigned';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (linesByTech.length > 1)
                  Text(
                    'Technician: $techName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ...techLines.map((line) => _buildEditableLineItem(line)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditableLineItem(TransactionLine line) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  line.formattedUnitPrice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: line.quantity.toString(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 1;
                _updateLineQuantity(line, qty);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              line.formattedLineTotal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              onPressed: () => _removeLine(line),
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateLineQuantity(TransactionLine line, int quantity) {
    setState(() {
      final index = _lines.indexOf(line);
      if (index >= 0) {
        _lines[index] = line.copyWith(
          quantity: quantity,
          lineTotal: line.unitPrice * quantity,
          updatedAt: DateTime.now(),
        );
        _calculateTotals();
      }
    });
  }

  double _calculateTotal() {
    final subtotal = _lines.fold(0.0, (sum, line) => sum + line.lineTotal);
    final discountAmount =
        _selectedDiscount?.calculateDiscount(subtotal) ?? 0.0;
    final discountedSubtotal = subtotal - discountAmount;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final tax = discountedSubtotal * (taxRate / 100);
    final tip = double.tryParse(_tipController.text) ?? 0.0;
    return discountedSubtotal + tax + tip;
  }

  Widget _buildReceiptLines() {
    if (_lines.isEmpty) {
      return const Center(
        child: Text(
          'No items added',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group by technician for receipt
    Map<String?, List<TransactionLine>> linesByTech = {};
    for (var line in _lines) {
      String? techId = line.technicianId;
      if (!linesByTech.containsKey(techId)) {
        linesByTech[techId] = [];
      }
      linesByTech[techId]!.add(line);
    }

    return ListView(
      children: linesByTech.entries.map((entry) {
        var techId = entry.key;
        var techLines = entry.value;
        var techName = techId != null
            ? _technicians
                .firstWhere((t) => t.id == techId,
                    orElse: () => Employee(
                          id: techId,
                          uid: '',
                          companyId: '',
                          email: '',
                          firstName: 'Staff',
                          lastName: '',
                          role: EmployeeRole.technician,
                          hiredDate: DateTime.now(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ))
                .fullName
            : 'General';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (linesByTech.length > 1) ...[
              Text(
                'Technician: $techName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            ...techLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.itemName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${line.formattedUnitPrice} × ${line.quantity}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        line.formattedLineTotal,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )),
            if (techLines.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal ($techName):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '\$${techLines.fold(0.0, (sum, line) => sum + line.lineTotal).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReceiptTotals() {
    final subtotal = _lines.fold(0.0, (sum, line) => sum + line.lineTotal);
    final discountAmount =
        _selectedDiscount?.calculateDiscount(subtotal) ?? 0.0;
    final discountedSubtotal = subtotal - discountAmount;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final tax = discountedSubtotal * (taxRate / 100);
    final tip = double.tryParse(_tipController.text) ?? 0.0;
    final total = discountedSubtotal + tax + tip;

    return Column(
      children: [
        _buildReceiptRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        if (discountAmount > 0) ...[
          _buildReceiptRow(
            'Discount (${_selectedDiscount!.name})',
            '-\$${discountAmount.toStringAsFixed(2)}',
            color: Colors.green,
          ),
          _buildReceiptRow(
            'Discounted Subtotal',
            '\$${discountedSubtotal.toStringAsFixed(2)}',
          ),
        ],
        _buildReceiptRow('Tax (${taxRate.toStringAsFixed(2)}%)',
            '\$${tax.toStringAsFixed(2)}'),
        if (tip > 0) _buildReceiptRow('Tip', '\$${tip.toStringAsFixed(2)}'),
        const Divider(),
        _buildReceiptRow(
          'Total',
          '\$${total.toStringAsFixed(2)}',
          bold: true,
          fontSize: 18,
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool bold = false, double? fontSize, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? 14,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateTotals(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _tipController,
                      decoration: const InputDecoration(
                        labelText: 'Tip (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateTotals(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Add Payment'),
                    onPressed: _addPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                    onPressed: _printReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _updateHeader({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? tax,
    double? discount,
    double? tip,
    double? total,
    String? notes,
  }) {
    setState(() {
      _header = _header.copyWith(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        status: status,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        tip: tip,
        total: total,
        notes: notes,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _calculateTotals() {
    final subtotal = _lines.fold(0.0, (sum, line) => sum + line.lineTotal);
    final discountAmount =
        _selectedDiscount?.calculateDiscount(subtotal) ?? 0.0;
    final discountedSubtotal = subtotal - discountAmount;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final tax = discountedSubtotal * (taxRate / 100);
    final tip = double.tryParse(_tipController.text) ?? 0.0;
    final total = discountedSubtotal + tax + tip;

    _updateHeader(
      subtotal: subtotal,
      tax: tax,
      discount: discountAmount,
      tip: tip,
      total: total,
    );
  }

  void _selectCustomer() {
    showDialog(
      context: context,
      builder: (context) => CustomerSelectionDialog(
        customers: _customers,
        onCustomerSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
            _updateHeader(
              customerId: customer.id,
              customerName: customer.fullName,
              customerPhone: customer.phone,
              customerEmail: customer.email,
            );
          });
        },
      ),
    );
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _updateHeader(
        customerId: null,
        customerName: null,
        customerPhone: null,
        customerEmail: null,
      );
    });
  }

  void _addNewCustomer() {
    // In real app, navigate to customer creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Add new customer functionality would be implemented here')),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => ItemSelectionDialog(
        items: _items,
        technicians: _technicians,
        onItemAdded: (item, quantity, technician, notes) {
          _addTransactionLine(item, quantity, technician, notes);
        },
      ),
    );
  }

  void _addTransactionLine(
      Item item, int quantity, Employee? technician, String? notes) {
    // Validate service items have technician
    if (item.isService && technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Service items must have a technician assigned')),
      );
      return;
    }

    final line = TransactionLine(
      id: 'line_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: _header.id,
      itemId: item.id,
      itemName: item.name,
      itemType: item.type,
      quantity: quantity,
      unitPrice: item.price,
      lineTotal: item.price * quantity,
      technicianId: technician?.id,
      serviceDuration: item.durationMinutes != null
          ? item.durationMinutes! * quantity
          : null,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _lines.add(line);
      _calculateTotals();
    });
  }

  void _editLine(TransactionLine line) {
    // In real app, show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Edit line functionality would be implemented here')),
    );
  }

  void _removeLine(TransactionLine line) {
    setState(() {
      _lines.remove(line);
      _calculateTotals();
    });
  }

  void _addPayment() {
    // In real app, show payment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Add payment functionality would be implemented here')),
    );
  }

  void _printReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Print receipt functionality would be implemented here')),
    );
  }

  void _saveTransaction() {
    // Validate transaction
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Check if all service items have technicians
    final servicesWithoutTech =
        _lines.where((line) => line.isService && line.technicianId == null);
    if (servicesWithoutTech.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All service items must have a technician assigned')),
      );
      return;
    }

    // In real app, save to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved successfully!')),
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tipController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }
}

// Dialog for customer selection
class CustomerSelectionDialog extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onCustomerSelected;

  const CustomerSelectionDialog({
    super.key,
    required this.customers,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
    _searchController.addListener(_filterCustomers);
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = widget.customers.where((customer) {
        return customer.fullName.toLowerCase().contains(query) ||
            (customer.phone?.contains(query) ?? false) ||
            (customer.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _filteredCustomers[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(customer.fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.phone != null)
                          Text('Phone: ${customer.phone}'),
                        if (customer.email != null)
                          Text('Email: ${customer.email}'),
                      ],
                    ),
                    onTap: () {
                      widget.onCustomerSelected(customer);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Walk-in customer
            widget.onCustomerSelected(WalkInCustomer());
            Navigator.of(context).pop();
          },
          child: const Text('Walk-in Customer'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Dialog for item selection
class ItemSelectionDialog extends StatefulWidget {
  final List<Item> items;
  final List<Employee> technicians;
  final Function(Item, int, Employee?, String?) onItemAdded;

  const ItemSelectionDialog({
    super.key,
    required this.items,
    required this.technicians,
    required this.onItemAdded,
  });

  @override
  State<ItemSelectionDialog> createState() => _ItemSelectionDialogState();
}

class _ItemSelectionDialogState extends State<ItemSelectionDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  List<Item> _filteredItems = [];
  Item? _selectedItem;
  Employee? _selectedTechnician;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items.where((item) => item.isActive).toList();
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.isActive &&
            (item.name.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Item list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return Card(
                    color:
                        _selectedItem?.id == item.id ? Colors.green[50] : null,
                    child: ListTile(
                      leading: Icon(
                        item.isService
                            ? Icons.design_services
                            : Icons.inventory_2,
                        color: item.isService ? Colors.blue : Colors.orange,
                      ),
                      title: Text(item.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description),
                          Row(
                            children: [
                              Text(item.formattedPrice),
                              if (item.isService &&
                                  item.durationMinutes != null) ...[
                                const SizedBox(width: 16),
                                Text('${item.formattedDuration}'),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: _selectedItem?.id == item.id
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => _selectItem(item),
                    ),
                  );
                },
              ),
            ),

            if (_selectedItem != null) ...[
              const Divider(),
              // Item configuration
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  if (_selectedItem!.isService) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<Employee>(
                        decoration: InputDecoration(
                          labelText: 'Technician*',
                          border: const OutlineInputBorder(),
                          errorText: _selectedItem!.isService &&
                                  _selectedTechnician == null
                              ? 'Required for services'
                              : null,
                        ),
                        value: _selectedTechnician,
                        items: widget.technicians.map((tech) {
                          return DropdownMenuItem(
                            value: tech,
                            child: Text(tech.fullName),
                          );
                        }).toList(),
                        onChanged: (tech) =>
                            setState(() => _selectedTechnician = tech),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedItem != null ? _addItem : null,
          child: const Text('Add Item'),
        ),
      ],
    );
  }

  void _selectItem(Item item) {
    setState(() {
      _selectedItem = item;
      _selectedTechnician = null; // Reset technician selection
    });
  }

  void _addItem() {
    if (_selectedItem == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    if (_selectedItem!.isService && _selectedTechnician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a technician for service items')),
      );
      return;
    }

    widget.onItemAdded(
      _selectedItem!,
      quantity,
      _selectedTechnician,
      _notesController.text.trim().isNotEmpty ? _notesController.text : null,
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
