import 'package:flutter/material.dart';
import 'package:firegloss/models/company.dart';
import 'package:firegloss/services/management_service.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try {
      final companies = await ManagementService.getCompanies();
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading companies: $e', isError: true);
    }
  }

  void _showAddCompanyDialog() {
    if (_companies.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Company Already Exists'),
          content: const Text(
            'Only one company is allowed per database. You can edit the existing company instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditCompanyDialog(_companies.first);
              },
              child: const Text('Edit Existing'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CompanyFormDialog(
        onSaved: (company) async {
          final success = await ManagementService.createCompany(company);
          if (success) {
            _showMessage('Company added successfully!');
            _loadCompanies();
          } else {
            _showMessage('Failed to add company', isError: true);
          }
        },
      ),
    );
  }

  void _showEditCompanyDialog(Company company) {
    showDialog(
      context: context,
      builder: (context) => CompanyFormDialog(
        company: company,
        onSaved: (updatedCompany) async {
          final success = await ManagementService.updateCompany(updatedCompany);
          if (success) {
            _showMessage('Company updated successfully!');
            _loadCompanies();
          } else {
            _showMessage('Failed to update company', isError: true);
          }
        },
      ),
    );
  }

  Future<void> _deleteCompany(Company company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete ${company.name}?'),
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
      final success = await ManagementService.deleteCompany(company.id);
      if (success) {
        _showMessage('Company deleted successfully!');
        _loadCompanies();
      } else {
        _showMessage('Failed to delete company', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _companies.isEmpty
            ? _showAddCompanyDialog
            : () {
                _showEditCompanyDialog(_companies.first);
              },
        backgroundColor: Colors.blue,
        child: Icon(_companies.isEmpty ? Icons.add : Icons.edit),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _companies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No company found'),
                      Text('Tap + to create your company'),
                      SizedBox(height: 8),
                      Text(
                        'Note: Only one company per database is allowed',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompanies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _companies.length,
                    itemBuilder: (context, index) {
                      final company = _companies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.business,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(company.name),
                              if (!company.isActive)
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
                              Text(company.email),
                              Text(company.phone),
                              Text(company.address),
                              if (company.website != null)
                                Text('Website: ${company.website}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
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
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCompanyDialog(company);
                              } else if (value == 'delete') {
                                _deleteCompany(company);
                              }
                            },
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

class CompanyFormDialog extends StatefulWidget {
  final Company? company;
  final Function(Company) onSaved;

  const CompanyFormDialog({
    super.key,
    this.company,
    required this.onSaved,
  });

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      final company = widget.company!;
      _nameController.text = company.name;
      _addressController.text = company.address;
      _phoneController.text = company.phone;
      _emailController.text = company.email;
      _websiteController.text = company.website ?? '';
      _taxIdController.text = company.taxId ?? '';
      _logoUrlController.text = company.logoUrl ?? '';
      _isActive = company.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.company == null ? 'Add Company' : 'Edit Company'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value!)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    hintText: 'https://example.com',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _taxIdController,
                  decoration: const InputDecoration(
                    labelText: 'Tax ID (Optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _logoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Logo URL (Optional)',
                    hintText: 'https://example.com/logo.png',
                  ),
                ),
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
              final company = Company(
                id: widget.company?.id ?? '',
                uid: widget.company?.uid ??
                    'company_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text,
                address: _addressController.text,
                phone: _phoneController.text,
                email: _emailController.text,
                website: _websiteController.text.isEmpty
                    ? null
                    : _websiteController.text,
                taxId: _taxIdController.text.isEmpty
                    ? null
                    : _taxIdController.text,
                logoUrl: _logoUrlController.text.isEmpty
                    ? null
                    : _logoUrlController.text,
                isActive: _isActive,
                createdAt: widget.company?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSaved(company);
              Navigator.pop(context);
            }
          },
          child: Text(widget.company == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
