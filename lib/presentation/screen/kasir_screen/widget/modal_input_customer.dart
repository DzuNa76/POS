import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pos/core/action/customer/customer_actions.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'dart:async';

import 'package:pos/data/models/customer/customer.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomerModal extends StatefulWidget {
  const CustomerModal({Key? key}) : super(key: key);

  @override
  _CustomerModalState createState() => _CustomerModalState();
}

class _CustomerModalState extends State<CustomerModal> {
  // Color theme as specified
  final Color _primaryColor = const Color(0xFF533F77);

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Store original customer list for filtering
  List<Customer> _filteredCustomers = [];

  bool _isLoading = false;

  Timer? _debounce;
  bool _searchByPhone = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await CustomerActions.getAllCustomers('');
      setState(() {
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _handleSaveCustomer(Customer customer) async {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    await customerProvider.saveCustomer(customer);
  }

// search
  void _searchCustomers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 750), () {
      _handleSearch(query);
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.isNotEmpty && query.length < 4) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final customer = await CustomerActions.getCustomers(
          query.length < 4 ? 10 : 20, 0, query,
          searchByPhone: _searchByPhone);
      if (mounted) {
        setState(() {
          _filteredCustomers = customer;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Simulated API call to add customer
  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await CustomerActions.addCustomer(
          token: '',
          address: _addressController.text,
          email: _emailController.text,
          name: _nameController.text,
          phone: _phoneController.text,
          socmed: '');

      if (result.containsKey('_server_messages')) {
        List<dynamic> serverMessages = jsonDecode(result['_server_messages']);
        Map<String, dynamic> messageData = jsonDecode(serverMessages[0]);
        String errorMessage =
            messageData['message'] ?? 'An unexpected error occurred';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        final id = result['name'];
        final code = result['name'];
        final name = result['customer_name'];
        final phone = result['custom_phone'];
        final address = result['custom_address'];
        final uuid = result['name'];
        final createdAt = result['creation'];
        final updatedAt = result['modified'];

        Customer customer = Customer(
            id: id,
            code: code,
            name: name,
            phone: phone,
            address: address,
            uuid: uuid,
            created_at: createdAt,
            updated_at: updatedAt);

        _handleSaveCustomer(customer);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully!')),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // Left Section: Input Form
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Customer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Customer Name',
                          labelStyle: TextStyle(color: _primaryColor),
                          prefixIcon: Icon(Icons.person, color: _primaryColor),
                          border: _customOutlineInputBorder(),
                          focusedBorder:
                              _customOutlineInputBorder(isFocused: true),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number (Whatsapp)',
                          labelStyle: TextStyle(color: _primaryColor),
                          prefixIcon: Icon(Icons.phone, color: _primaryColor),
                          border: _customOutlineInputBorder(),
                          focusedBorder:
                              _customOutlineInputBorder(isFocused: true),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(color: _primaryColor),
                          prefixIcon: Icon(Icons.home, color: _primaryColor),
                          border: _customOutlineInputBorder(),
                          focusedBorder:
                              _customOutlineInputBorder(isFocused: true),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: _primaryColor),
                          prefixIcon: Icon(Icons.email, color: _primaryColor),
                          border: _customOutlineInputBorder(),
                          focusedBorder:
                              _customOutlineInputBorder(isFocused: true),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Spacer(),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),

            // Right Section: Customer List with Search
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        _buildRefreshButton(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: _searchByPhone
                            ? 'Search Customer by Phone'
                            : 'Search Customers by Name',
                        labelStyle: TextStyle(color: _primaryColor),
                        prefixIcon: Icon(Icons.search, color: _primaryColor),
                        border: _customOutlineInputBorder(),
                        focusedBorder:
                            _customOutlineInputBorder(isFocused: true),
                      ),
                      onChanged: _searchCustomers,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _searchByPhone = true;
                                  if (_searchController.text.isNotEmpty) {
                                    _searchCustomers(_searchController.text);
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'phone',
                                    groupValue:
                                        _searchByPhone ? 'phone' : 'nama',
                                    activeColor: _primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchByPhone = value == 'phone';
                                        if (_searchController.text.isNotEmpty) {
                                          _searchCustomers(
                                              _searchController.text);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'Phone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _searchByPhone = false;
                                  if (_searchController.text.isNotEmpty) {
                                    _searchCustomers(_searchController.text);
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'nama',
                                    groupValue:
                                        _searchByPhone ? 'phone' : 'nama',
                                    activeColor: _primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchByPhone = value == 'phone';
                                        if (_searchController.text.isNotEmpty) {
                                          _searchCustomers(
                                              _searchController.text);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'Nama',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                    Divider(color: _primaryColor.withOpacity(0.2)),
                    Expanded(
                      child: _isLoading
                          ? Skeletonizer(
                              enabled: true,
                              child: ListView.separated(
                                padding: const EdgeInsets.only(top: 16),
                                itemCount: 10,
                                separatorBuilder: (context, index) => Divider(
                                  color: _primaryColor.withOpacity(0.2),
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                itemBuilder: (context, index) => ListTile(
                                  title: Text('Loading Custoner Name'),
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Loading Phone',
                                          style: TextStyle(fontSize: 12)),
                                      Text('Loading address',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('+++'),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (context, index) => Divider(
                                color: _primaryColor.withOpacity(0.3),
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                return ListTile(
                                  title: Text(
                                    '${customer.name}',
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${customer.phone}'),
                                        Text('${customer.address}'),
                                      ]),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      color: _primaryColor,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(customer);
                                      _handleSaveCustomer(customer);
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop(customer);
                                    _handleSaveCustomer(customer);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom method for creating consistent OutlineInputBorder
  OutlineInputBorder _customOutlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isFocused ? _primaryColor : Colors.grey.shade400,
        width: isFocused ? 2 : 1,
      ),
    );
  }

  // Improved Submit Button
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Add Customer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // New Refresh Button with Icon
  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _searchCustomers(_searchController.text);
      },
      icon: const Icon(
        Icons.refresh,
        size: 20,
        color: Colors.white,
      ),
      label: const Text('Refresh'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 3,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// CustomerPage remains the same as in the previous implementation
