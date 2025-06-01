import 'dart:async';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/action/product_action/product_action.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:pos/presentation/widgets/notification.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductCartScreen extends StatefulWidget {
  final FocusNode? searchFocusNode;
  final bool isGridView;

  const ProductCartScreen({
    Key? key,
    this.searchFocusNode,
    this.isGridView = true,
  }) : super(key: key);

  @override
  State<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends State<ProductCartScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> _listTherapist = [];
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final Color _primaryColor = const Color(0xFF533F77);
  bool _isLoading = false;
  Timer? _debounce;
  bool _isCartView = false;
  bool _allowStock = false;
  bool _searchByCode = true;
  bool _showBelumLaku = false;
  SharedPreferences? _prefs;
  final Map<String, Timer?> _debounceTimers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Clear any existing items when widget is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).clearItems();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!ConfigService.isUsingListProductTherapist) {
      _loadTherapist();
    }
    _checkCart();
    await _handleCheckPosSettings();
  }

  Future<void> _handleCheckPosSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final allowStock = _prefs?.getBool('allow_stock') ?? false;
    if (mounted) {
      setState(() {
        _allowStock = allowStock;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length < 4 && query.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan minimal 4 karakter untuk mencari'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            _isCartView = true;
            Provider.of<ProductProvider>(context, listen: false).clearItems();
          });
        }
        return;
      }
      _handleSearch(query);
    });
  }

  void _loadTherapist() {
    final List<String> listTherapist = [
      'Therapist 1',
      'Therapist 2',
      'Therapist 3'
    ];
    if (mounted) {
      setState(() {
        _listTherapist.addAll(listTherapist);
      });
    }
  }

  void _checkCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isCartEmpty = cartProvider.cartItems.isNotEmpty;
    if (mounted) {
      setState(() {
        _isCartView = isCartEmpty;
      });
    }
  }

  Future<bool> _handleLoadCustomer() async {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);
    return customerProvider.customer != null;
  }

  Future<void> _handleSearch(String query) async {
    if (ConfigService.isCustomerMandatory) {
      final hasCustomer = await _handleLoadCustomer();
      if (!hasCustomer) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                'Silahkan pilih customer terlebih dahulu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return;
      }
    }

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _isCartView = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCartView = false;
        _isLoading = true;
      });
    }

    try {
      final warehouseName = _prefs?.getString('warehouse_name') ?? '';
      final customerProvider =
          Provider.of<CustomerProvider>(context, listen: false);
      final priceListGroup =
          customerProvider.customer?.default_price_list ?? "Standard Selling";

      final items = await ItemActions.getItemData(
        query.length < 4 ? 10 : 20,
        0,
        query,
        warehouseName,
        priceListGroup,
        searchByCode: _searchByCode,
        allowStock: _allowStock,
      );

      if (mounted) {
        // Filter items based on _showBelumLaku
        final filteredItems = _showBelumLaku
            ? items
                .where((item) => item.stockQty != null && item.stockQty! > 0)
                .toList()
            : items;

        Provider.of<ProductProvider>(context, listen: false)
            .setItems(filteredItems);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart(Item item) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final voucher = _prefs?.getBool('voucher_used') ?? false;

    if (voucher) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Ada Voucher aktif, Silahkan hapus voucher terlebih dahulu'),
          ),
        );
      }
      return;
    }

    final existingItemIndex = cart.cartItems.indexWhere(
      (cartItem) => cartItem.itemCode == item.itemCode,
    );

    if (existingItemIndex != -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item sudah ada di keranjang')),
        );
      }
      return;
    }

    cart.addItem(
      item,
      1,
      discountValue: 0,
      isDiscountPercent: true,
    );

    searchController.clear();
    if (mounted) {
      setState(() {
        _isCartView = true;
      });
    }
  }

  void _debounceDiscountInput(String itemId, String value,
      CartProvider cartProvider, bool isPercentDiscount) {
    _debounceTimers[itemId]?.cancel();
    _debounceTimers[itemId] = Timer(const Duration(milliseconds: 500), () {
      final cartItem =
          cartProvider.cartItems.firstWhere((item) => item.id == itemId);
      double discountValue = isPercentDiscount
          ? (double.tryParse(value) ?? 0)
          : double.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      if (isPercentDiscount && discountValue > 100) {
        discountValue = 100;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diskon maksimal 100%')),
          );
        }
      } else if (!isPercentDiscount) {
        final maxDiscount = cartItem.baseRate! * cartItem.qty!.toDouble();
        if (discountValue > maxDiscount) {
          discountValue = maxDiscount;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Diskon maksimal ${currencyFormat.format(maxDiscount)}')),
            );
          }
        }
      }

      cartProvider.updateCartItemDiscount(
          itemId, discountValue, isPercentDiscount);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: TextField(
                focusNode: widget.searchFocusNode,
                controller: searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: _searchByCode
                      ? 'Cari produk berdasarkan kode...'
                      : 'Cari produk berdasarkan nama...',
                  labelStyle: TextStyle(color: _primaryColor),
                  prefixIcon: Icon(Icons.search, color: _primaryColor),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              _isCartView = true;
                              Provider.of<ProductProvider>(context,
                                      listen: false)
                                  .clearItems();
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  border: _customOutlineInputBorder(),
                  focusedBorder: _customOutlineInputBorder(isFocused: true),
                ),
              ),
            ),

            // Toggle Filters Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle for Search By Name/Code
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _searchByCode = true;
                            if (searchController.text.isNotEmpty) {
                              _onSearchChanged(searchController.text);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'kode',
                              groupValue: _searchByCode ? 'kode' : 'nama',
                              activeColor: _primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _searchByCode = value == 'kode';
                                  if (searchController.text.isNotEmpty) {
                                    _onSearchChanged(searchController.text);
                                  }
                                });
                              },
                            ),
                            Text(
                              'Kode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10), // Spasi antara opsi
                      InkWell(
                        onTap: () {
                          setState(() {
                            _searchByCode = false;
                            if (searchController.text.isNotEmpty) {
                              _onSearchChanged(searchController.text);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Radio<String>(
                              value: 'nama',
                              groupValue: _searchByCode ? 'kode' : 'nama',
                              activeColor: _primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _searchByCode = value == 'kode';
                                  if (searchController.text.isNotEmpty) {
                                    _onSearchChanged(searchController.text);
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
                  ),
                  // Toggle for Sold/Unsold Items
                  if (_allowStock)
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showBelumLaku = false;
                              if (searchController.text.isNotEmpty) {
                                _onSearchChanged(searchController.text);
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'semua',
                                groupValue:
                                    _showBelumLaku ? 'belumlaku' : 'semua',
                                activeColor: _primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    _showBelumLaku = false;
                                    if (searchController.text.isNotEmpty) {
                                      _onSearchChanged(searchController.text);
                                    }
                                  });
                                },
                              ),
                              Text(
                                'Semua Item',
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
                              _showBelumLaku = true;
                              if (searchController.text.isNotEmpty) {
                                _onSearchChanged(searchController.text);
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'belumlaku',
                                groupValue:
                                    _showBelumLaku ? 'belumlaku' : 'semua',
                                activeColor: _primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    _showBelumLaku = true;
                                    if (searchController.text.isNotEmpty) {
                                      _onSearchChanged(searchController.text);
                                    }
                                  });
                                },
                              ),
                              Text(
                                'Belum Laku',
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
                    ),
                ],
              ),
            ),
            if (cartProvider.cartItems.isNotEmpty)
              if (_isCartView)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 0, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor.withOpacity(0.8),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(50, 25),
                            ),
                            onPressed: () {
                              showCustomPopup(
                                context: context,
                                title: "Konfirmasi",
                                message: "Apakah anda yakin ingin menghapus?",
                                confirmText: "OK",
                                cancelText: "Batal",
                                icon: Icons.help_outline,
                                iconColor: Colors.red,
                                onConfirm: () {
                                  final cartProvider =
                                      Provider.of<CartProvider>(context,
                                          listen: false);
                                  final customerProvider =
                                      Provider.of<CustomerProvider>(context,
                                          listen: false);

                                  customerProvider.deleteCustomer();
                                  cartProvider.loadPesanan().then((test) {
                                    for (var a in test) {
                                      cartProvider.deletePesananById(
                                          a['invoiceNumber']);
                                    }
                                  });

                                  context.read<CartProvider>().clearCart();
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          KasirScreenDesktop(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Reset",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Divider(
                        color: Colors.grey.withOpacity(0.3),
                        thickness: 1.0,
                      ),
                    ),
                  ],
                ),

            // Dynamic Content Area
            Expanded(
              child: _isCartView
                  ? _buildCartContent(cartProvider)
                  : _buildProductSearchContent(productProvider),
            ),

            // Total Price and Cart Summary (moved to bottom)
            if (_isCartView)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Tagihan (${cartProvider.totalItems} Item) ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      currencyFormat.format(cartProvider.totalPrice),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Product Search Content
  Widget _buildProductSearchContent(ProductProvider productProvider) {
    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        child: widget.isGridView
            ? GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          const Spacer(),
                          Container(
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 36,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text('Loading Sales Invoice'),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loading Price', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+++', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
      );
    }

    if (productProvider.filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: productProvider.filteredItems.length,
        itemBuilder: (context, index) {
          final item = productProvider.filteredItems[index];
          bool isInStock =
              !_allowStock || (item.stockQty != null && item.stockQty! > 0);

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                if (isInStock) {
                  _addToCart(item);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stok tidak tersedia'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Code and Name
                    Text(
                      item.itemCode ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.itemName ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Item Image
                    Expanded(
                      child: Center(
                        child: item.image != null && item.image!.isNotEmpty
                            ? Image.network(
                                item.image!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  );
                                },
                              )
                            : Icon(
                                Icons.image_not_supported_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    // Price and Stock
                    Text(
                      currencyFormat.format(item.standardRate ?? 0),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_allowStock)
                      Text(
                        isInStock
                            ? "(${item.stockQty!.toStringAsFixed(0)} ${item.stockUom})"
                            : "Stok tidak tersedia",
                        style: TextStyle(
                          color: isInStock ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight:
                              isInStock ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Add to Cart Button
                    if (isInStock)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(item),
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: productProvider.filteredItems.length,
        itemBuilder: (context, index) {
          final item = productProvider.filteredItems[index];
          bool isInStock =
              !_allowStock || (item.stockQty != null && item.stockQty! > 0);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () {
                if (isInStock) {
                  _addToCart(item);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stok tidak tersedia'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              title: Text(
                "${item.itemCode} - ${item.itemName}" ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(item.standardRate ?? 0),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_allowStock)
                    Text(
                      isInStock
                          ? "(${item.stockQty!.toStringAsFixed(0)} ${item.stockUom})"
                          : "Stok tidak tersedia",
                      style: TextStyle(
                        color: isInStock ? Colors.green : Colors.red,
                        fontSize: isInStock ? 14 : 12,
                        fontWeight:
                            isInStock ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                ],
              ),
              trailing: isInStock
                  ? IconButton(
                      tooltip: "Add to Cart",
                      icon: Icon(Icons.add, color: _primaryColor),
                      onPressed: () => _addToCart(item),
                    )
                  : null,
            ),
          );
        },
      );
    }
  }

  // Cart Content
  Widget _buildCartContent(CartProvider cartProvider) {
    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Keranjang Kosong',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartProvider.cartItems[index];

        // Discount controller with initial formatting
        final discountController = TextEditingController(
            text: cartItem.isDiscountPercent
                ? (cartItem.discountValue?.toString() ?? '0')
                : currencyFormat.format(cartItem.discountValue ?? 0));

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${cartItem.itemName} - ${cartItem.itemCode}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final voucher =
                            _prefs?.getBool('voucher_used') ?? false;
                        if (voucher == false) {
                          cartProvider.removeCartItem(cartItem.id!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Tidak dapat menghapus item karena terdapat voucher yang aktif,Silahkan hapus voucher terlebih dahulu'),
                            ),
                          );
                        }

                        // Switch to product view if cart is empty
                        if (cartProvider.cartItems.isEmpty) {
                          // clear pesanan if empty
                          final cartProvider =
                              Provider.of<CartProvider>(context, listen: false);

                          cartProvider.loadPesanan().then((test) {
                            for (var a in test) {
                              cartProvider
                                  .deletePesananById(a['invoiceNumber']);
                            }
                          });

                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      KasirScreenDesktop(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                          setState(() {
                            _isCartView = false;
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pricing Information - using a Row with three columns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // First column: Price × Qty (combined in single container)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Qty input
                        SizedBox(
                          width: 60,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              final controller = TextEditingController();
                              controller.text = cartItem.qty.toString();
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );

                              return TextField(
                                controller: controller,
                                enabled: ConfigService.isUsingQtyItem,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 13),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 6),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (value) async {
                                  final voucher =
                                      _prefs?.getBool('voucher_used') ?? false;
                                  if (ConfigService.isUsingQtyItem) {
                                    if (voucher == false) {
                                      if (value.isEmpty) return;
                                      final newQty = int.tryParse(value) ?? 1;
                                      if (newQty == cartItem.qty) return;
                                      Future.microtask(() {
                                        cartProvider.updateCartItemQuantity(
                                            cartItem.id!, newQty);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Tidak dapat mengubah jumlah karena terdapat voucher yang aktif,Silahkan hapus voucher terlebih dahulu'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          ' x ',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 5),

                        // Base price
                        Text(
                          currencyFormat.format(cartItem.baseRate),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Notes
                    if (ConfigService.isUsingListProductTherapist)
                      SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatefulBuilder(builder: (context, setState) {
                                final controller = TextEditingController();
                                controller.text = cartItem.notes.toString();
                                controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );
                                return CustomDropdown<String>.multiSelectSearch(
                                  hintText: 'Select Therapist',
                                  items: _listTherapist,
                                  onListChanged: (value) {
                                    cartProvider.updateCartItemNotes(
                                        cartItem.id!, value.toString());
                                  },
                                );
                              }),
                            ],
                          )),
                    if (!ConfigService.isUsingListProductTherapist &&
                        ConfigService.isUsingListProductDiscountPerItem)
                      // Second column: Discount controls
                      SizedBox(
                        width: 240, // Fixed width for the discount controls
                        child: Row(
                          children: [
                            // Discount Type Dropdown
                            SizedBox(
                              width: 90, // Smaller width for dropdown
                              child: CustomDropdown<String>(
                                closedHeaderPadding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                hintText: "Pilih Metode Pembayaran",
                                items: ['Rp', '%'],
                                initialItem: "%",
                                decoration: CustomDropdownDecoration(
                                    closedBorder: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1),
                                      top: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1),
                                      left: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1),
                                      right: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1),
                                    ),
                                    listItemStyle: TextStyle(fontSize: 12),
                                    closedFillColor: Colors.grey.shade100),
                                onChanged: (value) {
                                  if (value == "%") {
                                    discountController.text = "0";
                                    cartProvider.updateCartItemDiscount(
                                        cartItem.id!, 0, true);
                                  } else {
                                    discountController.text =
                                        currencyFormat.format(0);
                                    cartProvider.updateCartItemDiscount(
                                        cartItem.id!, 0, false);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Discount Input Field
                            Expanded(
                              child: TextField(
                                controller: discountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 13),
                                inputFormatters: [
                                  // Custom formatter for Rupiah input when not in percentage mode
                                  if (!cartItem.isDiscountPercent)
                                    TextInputFormatter.withFunction(
                                        (oldValue, newValue) {
                                      // Remove non-numeric characters
                                      String cleanValue = newValue.text
                                          .replaceAll(RegExp(r'[^\d]'), '');

                                      // Convert to number
                                      final value =
                                          int.tryParse(cleanValue) ?? 0;

                                      // Format as currency
                                      return TextEditingValue(
                                        text: currencyFormat.format(value),
                                        selection: TextSelection.collapsed(
                                            offset: currencyFormat
                                                .format(value)
                                                .length),
                                      );
                                    }),
                                  // For percentage mode, only allow numeric input
                                  if (cartItem.isDiscountPercent)
                                    FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  labelText: cartItem.isDiscountPercent
                                      ? 'Diskon (%)'
                                      : 'Diskon',
                                  labelStyle: TextStyle(fontSize: 11),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  _debounceDiscountInput(cartItem.id!, value,
                                      cartProvider, cartItem.isDiscountPercent);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Third column: Final price
                    Text(
                      currencyFormat.format(cartItem.amount ??
                          cartItem.baseRate! * cartItem.qty!),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Border method
  OutlineInputBorder _customOutlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isFocused ? const Color(0xFF533F77) : Colors.grey.shade400,
        width: isFocused ? 2 : 1,
      ),
    );
  }
}
