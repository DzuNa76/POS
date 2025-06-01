import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:provider/provider.dart';

class CartModal extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const CartModal({Key? key, required this.transactions}) : super(key: key);

  @override
  _CartModalState createState() => _CartModalState();
}

class _CartModalState extends State<CartModal> {
  // Color theme as specified
  final Color _primaryColor = const Color(0xFF533F77);

  // Selected transaction and item
  Map<String, dynamic>? _selectedTransaction;
  List<CartItem>? _selectedTransactionItems;
  CartItem? _selectedCartItem;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTransactions = [];

  bool _isLoading = false;

  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _filteredTransactions = widget.transactions;

    if (_filteredTransactions.isNotEmpty) {
      _selectTransaction(_filteredTransactions[0]);
    }
  }

  void _selectTransaction(Map<String, dynamic> transaction) {
    setState(() {
      _selectedTransaction = transaction;

      // Convert items from Map<String, dynamic> to CartItem objects
      List<dynamic> itemsData = transaction['items'];
      _selectedTransactionItems = itemsData.map<CartItem>((item) {
        return CartItem(
          id: item['id'],
          itemCode: item['itemCode'],
          itemName: item['itemName'],
          description: item['description'],
          uom: item['uom'],
          conversionFactor: item['conversionFactor'],
          qty: item['qty'],
          rate: item['rate'],
          amount: item['amount'],
          baseRate: item['baseRate'],
          baseAmount: item['baseAmount'],
          priceListRate: item['priceListRate'],
          costCenter: item['costCenter'],
          notes: item['notes'],
          discountValue: item['discountValue'],
          isDiscountPercent: item['isDiscountPercent'],
        );
      }).toList();

      // Select the first item by default
      if (_selectedTransactionItems!.isNotEmpty) {
        _selectedCartItem = _selectedTransactionItems![0];
      } else {
        _selectedCartItem = null;
      }
    });
  }

  void _selectCartItem(CartItem item) {
    setState(() {
      _selectedCartItem = item;
    });
  }

  void _searchTransactions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = widget.transactions;
      } else {
        _filteredTransactions = widget.transactions.where((transaction) {
          // Search by transaction ID
          if (transaction['id']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase())) {
            return true;
          }

          // Search by customer name
          if (transaction['customer']['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase())) {
            return true;
          }

          // Search in items within transaction
          List<dynamic> items = transaction['items'];
          for (var item in items) {
            if ((item['itemName']
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false) ||
                (item['itemCode']
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false)) {
              return true;
            }
          }
          return false;
        }).toList();
      }
    });
  }

  void _handleTagih() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      cartProvider.clearCart();

      if (_selectedTransaction != null && _selectedTransactionItems != null) {
        for (final item in _selectedTransactionItems!) {
          cartProvider.addToCart(item);
        }
      }

      await cartProvider.deleteTransactionById(_selectedTransaction!['id']);

      Navigator.pop(context);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              KasirScreenDesktop(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  void _deleteTransaction() {
    if (_selectedTransaction == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the provider method to delete the transaction
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.deleteTransactionById(_selectedTransaction!['id']).then((_) {
        // After deletion, update the UI
        setState(() {
          // Remove from the filtered list
          _filteredTransactions.removeWhere((transaction) =>
              transaction['id'] == _selectedTransaction!['id']);

          // Select another transaction if available
          if (_filteredTransactions.isNotEmpty) {
            _selectTransaction(_filteredTransactions[0]);
          } else {
            _selectedTransaction = null;
            _selectedTransactionItems = null;
            _selectedCartItem = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully!')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting transaction: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  double _calculateTransactionTotal(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      total += (item['amount'] ?? 0).toDouble();
    }
    return total;
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
            // Left Section: Transactions List - Changed to Card style
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by ID or Customer Name',
                        labelStyle: TextStyle(color: _primaryColor),
                        prefixIcon: Icon(Icons.search, color: _primaryColor),
                        border: _customOutlineInputBorder(),
                        focusedBorder:
                            _customOutlineInputBorder(isFocused: true),
                      ),
                      onChanged: _searchTransactions,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: _primaryColor),
                            )
                          : _filteredTransactions.isEmpty
                              ? Center(
                                  child: Text(
                                    'No saved transactions',
                                    style: TextStyle(color: _primaryColor),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filteredTransactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction =
                                        _filteredTransactions[index];
                                    final isSelected =
                                        _selectedTransaction?['id'] ==
                                            transaction['id'];
                                    final items =
                                        transaction['items'] as List<dynamic>;
                                    final transactionTotal =
                                        _calculateTransactionTotal(items);
                                    final formattedDate = _formatDateTime(
                                        transaction['timestamp']);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: isSelected ? 3 : 1,
                                      color: isSelected
                                          ? Colors.grey.shade300
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            _selectTransaction(transaction),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'ID #${transaction['id']}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                      color: _primaryColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Customer: ${transaction['customer']['name']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Items: ${items.length}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    'Total: ${_formatter.format(transactionTotal)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: _primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Section: Transaction Items - Changed to simple list
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _selectedTransaction == null
                    ? Center(
                        child: Text(
                          'Select a transaction to view items',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              Text(
                                _formatDateTime(
                                    _selectedTransaction!['timestamp']),
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID #${_selectedTransaction!['id']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _primaryColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                              'Customer : ${_selectedTransaction!['customer']['name']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _primaryColor,
                              )),
                          Text(
                            'Phone : ${_selectedTransaction!['customer']['phone']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _primaryColor,
                            ),
                          ),
                          Text(
                            'Address : ${_selectedTransaction!['customer']['address']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _primaryColor,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text(
                            'Items :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // List of items in the transaction - Changed to simple list
                          Expanded(
                              child: _selectedTransactionItems == null ||
                                      _selectedTransactionItems!.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No items in this transaction',
                                        style: TextStyle(color: _primaryColor),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount:
                                          _selectedTransactionItems!.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        height: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item =
                                            _selectedTransactionItems![index];
                                        final isSelected =
                                            _selectedCartItem?.id == item.id;

                                        // Calculate if there's a discount
                                        final hasDiscount =
                                            item.discountValue! > 0;

                                        return InkWell(
                                          // onTap: () => _selectCartItem(item),
                                          child: Container(
                                            // color: isSelected
                                            //     ? Colors.grey[200]
                                            //     : null,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${item.itemName}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: _primaryColor,
                                                        ),
                                                      ),
                                                      Text(
                                                          '${item.qty} ${item.uom} x ${_formatter.format(item.rate)}'),
                                                      if (hasDiscount)
                                                        Text(
                                                          item.isDiscountPercent
                                                              ? 'Discount: ${item.discountValue}%'
                                                              : 'Discount: ${_formatter.format(item.discountValue)}',
                                                          style: TextStyle(
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  250, 85, 73)),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      if (hasDiscount)
                                                        Text(
                                                          '${_formatter.format(item.baseAmount)}',
                                                          style: TextStyle(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            fontSize: 10,
                                                            color:
                                                                _primaryColor,
                                                          ),
                                                        ),
                                                      Text(
                                                        '${_formatter.format(item.amount)}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: _primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )),

                          // Total amount
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                Text(
                                  '${_formatter.format(_calculateTransactionTotal(_selectedTransaction!['items']))}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action buttons
                          Row(
                            children: [
                              // Tagih Button
                              Expanded(
                                flex: 1,
                                child: _buildDeleteButton(),
                              ),
                              const SizedBox(width: 12),
                              // Delete Button
                              Expanded(
                                flex: 2,
                                child: _buildTagihButton(),
                              ),
                            ],
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

  // Tagih Button
  Widget _buildTagihButton() {
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
        onPressed:
            _isLoading || _selectedTransaction == null ? null : _handleTagih,
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
                'Tagih',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Delete Button
  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red,
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
        onPressed: _isLoading || _selectedTransaction == null
            ? null
            : _deleteTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.white,
                  ),
            const SizedBox(width: 4),
            Text(
              'Hapus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
