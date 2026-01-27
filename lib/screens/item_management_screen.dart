import 'package:flutter/material.dart';
import 'package:firegloss/models/item.dart';
import 'package:firegloss/models/item_category.dart';
import 'package:firegloss/models/company.dart';
import 'package:firegloss/services/management_service.dart';

class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  List<Item> _items = [];
  List<ItemCategory> _categories = [];
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
        ManagementService.getItems(),
        ManagementService.getCategories(),
        ManagementService.getCompanies(),
      ]);
      setState(() {
        _items = futures[0] as List<Item>;
        _categories = futures[1] as List<ItemCategory>;
        _companies = futures[2] as List<Company>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading data: $e', isError: true);
    }
  }

  void _showAddItemDialog() {
    if (_companies.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Company Required'),
          content: const Text(
            'You must create a company first before adding items. '
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

    if (_categories.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Categories Required'),
          content: const Text(
            'You must create at least one category first before adding items.',
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
      builder: (context) => ItemFormDialog(
        categories: _categories,
        onSaved: (item) async {
          final success = await ManagementService.createItem(item);
          if (success) {
            _showMessage('Item added successfully!');
            _loadData();
          } else {
            _showMessage('Failed to add item', isError: true);
          }
        },
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => ItemFormDialog(
        categories: _categories,
        item: item,
        onSaved: (updatedItem) async {
          final success = await ManagementService.updateItem(updatedItem);
          if (success) {
            _showMessage('Item updated successfully!');
            _loadData();
          } else {
            _showMessage('Failed to update item', isError: true);
          }
        },
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
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
      final success = await ManagementService.deleteItem(item.id);
      if (success) {
        _showMessage('Item deleted successfully!');
        _loadData();
      } else {
        _showMessage('Failed to delete item', isError: true);
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

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => ItemCategory(
        id: '',
        name: 'Unknown',
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Products'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No items found'),
                      Text('Tap + to add your first service or product'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                item.isService ? Colors.blue : Colors.green,
                            child: Icon(
                              item.isService ? Icons.spa : Icons.shopping_bag,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(item.name),
                              if (!item.isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description),
                              Text(
                                  'Category: ${_getCategoryName(item.categoryId)}'),
                              Text('Price: ${item.formattedPrice}'),
                              if (item.isService &&
                                  item.durationMinutes != null)
                                Text('Duration: ${item.formattedDuration}'),
                              if (item.isProduct && item.stockQuantity != null)
                                Text('Stock: ${item.stockQuantity}'),
                              if (item.isProduct && item.sku != null)
                                Text('SKU: ${item.sku}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.isService
                                      ? Colors.blue[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.type
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.isService
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ),
                              PopupMenuButton(
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
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditItemDialog(item);
                                  } else if (value == 'delete') {
                                    _deleteItem(item);
                                  }
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ItemFormDialog extends StatefulWidget {
  final Item? item;
  final List<ItemCategory> categories;
  final Function(Item) onSaved;

  const ItemFormDialog({
    super.key,
    this.item,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();

  ItemType _selectedType = ItemType.service;
  String? _selectedCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final item = widget.item!;
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _priceController.text = item.price.toString();
      _durationController.text = item.durationMinutes?.toString() ?? '';
      _skuController.text = item.sku ?? '';
      _stockController.text = item.stockQuantity?.toString() ?? '';
      _selectedType = item.type;
      _selectedCategoryId = item.categoryId;
      _isActive = item.isActive;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: SizedBox(
        width: 400,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                // Type Selection
                DropdownButtonFormField<ItemType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ItemType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child:
                          Text(type.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 8),

                // Category Selection
                if (widget.categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: widget.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Required';
                    final price = double.tryParse(value!);
                    if (price == null || price < 0) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Service-specific fields
                if (_selectedType == ItemType.service) ...[
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final duration = int.tryParse(value!);
                        if (duration == null || duration <= 0) {
                          return 'Invalid duration';
                        }
                      }
                      return null;
                    },
                  ),
                ],

                // Product-specific fields
                if (_selectedType == ItemType.product) ...[
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (Optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        final stock = int.tryParse(value!);
                        if (stock == null || stock < 0) {
                          return 'Invalid quantity';
                        }
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Active Toggle
                Row(
                  children: [
                    const Text('Active: '),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
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
              final item = Item(
                id: widget.item?.id ?? '',
                name: _nameController.text,
                description: _descriptionController.text,
                type: _selectedType,
                categoryId: _selectedCategoryId!,
                price: double.parse(_priceController.text),
                durationMinutes: _selectedType == ItemType.service &&
                        _durationController.text.isNotEmpty
                    ? int.tryParse(_durationController.text)
                    : null,
                sku: _selectedType == ItemType.product &&
                        _skuController.text.isNotEmpty
                    ? _skuController.text
                    : null,
                stockQuantity: _selectedType == ItemType.product &&
                        _stockController.text.isNotEmpty
                    ? int.tryParse(_stockController.text)
                    : null,
                isActive: _isActive,
                createdAt: widget.item?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSaved(item);
              Navigator.pop(context);
            }
          },
          child: Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
