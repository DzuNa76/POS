import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/core/providers/cart_provider.dart';

class ProductDetailEditDialog extends StatefulWidget {
  final CartItem cartItem;
  final CartProvider cartProvider;
  final String initialCustomerName;
  final String? initialSize;
  final List<String> initialFeatures;
  final double? initialDiscountValue;
  final bool? initialIsDiscountPercent;

  const ProductDetailEditDialog({
    Key? key,
    required this.cartItem,
    required this.cartProvider,
    required this.initialCustomerName,
    this.initialSize,
    required this.initialFeatures,
    this.initialDiscountValue = 0.0, // Default value jika tidak disediakan
    this.initialIsDiscountPercent =
        false, // Default value jika tidak disediakan
  }) : super(key: key);

  @override
  ProductDetailEditDialogState createState() => ProductDetailEditDialogState();
}

class ProductDetailEditDialogState extends State<ProductDetailEditDialog> {
  late int quantity;
  late String customerName;
  String? selectedOption;
  late List<String> selectedFeatures;

  // Discount related variables
  bool applyDiscount = false;
  String discountType = 'Persen'; // Default discount type
  final List<String> discountTypes = ['Persen', 'Rupiah'];
  final TextEditingController discountController = TextEditingController();

  // Controllers for form fields
  final TextEditingController noteController = TextEditingController();

  // Calculate total price with discount
  double get totalBeforeDiscount => widget.cartItem.rate! * quantity.toDouble();
  double get discountAmount {
    if (!applyDiscount || discountController.text.isEmpty) return 0;

    try {
      double discountValue = double.parse(discountController.text);
      if (discountType == 'Persen') {
        return totalBeforeDiscount * (discountValue / 100);
      } else {
        return discountValue;
      }
    } catch (e) {
      return 0;
    }
  }

  double get totalPrice => totalBeforeDiscount - discountAmount;

  @override
  void initState() {
    super.initState();
    quantity = widget.cartItem.qty!;
    customerName = widget.initialCustomerName;
    selectedOption = widget.initialSize;
    selectedFeatures = List.from(widget.initialFeatures);
    noteController.text = customerName;

    // Initialize discount values if they exist
    if (widget.initialDiscountValue != null &&
        widget.initialDiscountValue! > 0) {
      applyDiscount = true;
      discountType =
          widget.initialIsDiscountPercent == true ? 'Persen' : 'Rupiah';
      discountController.text = widget.initialDiscountValue!.toString();
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width <= 1200 && screenSize.width >= 900;
    final isMobile = screenSize.width < 900;

    // Adjust dialog width based on device
    double dialogWidth;
    if (isDesktop) {
      dialogWidth = screenSize.width * 0.7; // 70% of screen width for desktop
    } else if (isTablet) {
      dialogWidth = screenSize.width * 0.7; // 70% of screen width for tablet
    } else {
      dialogWidth = screenSize.width * 0.9; // 90% of screen width for mobile
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8, // Maximum 80% of screen height
        ),
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Custom form layout based on device size
                    isMobile
                        ? _buildMobileFormLayout()
                        : _buildDesktopTabletFormLayout(),
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Mobile layout has quantity control above the checkout button
            if (isMobile) _buildQuantityControl(),
            if (isMobile) const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.cartItem.itemName!,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // Mobile form layout: vertical stacking (notes -> size -> add-ons -> discount)
  Widget _buildMobileFormLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Notes Field (at the top for mobile)
        _buildNotesField(),
        const SizedBox(height: 16),

        // Size Selection (in the middle for mobile)
        _buildSizeSelection(),
        const SizedBox(height: 16),

        // Add-ons (at the bottom for mobile)
        _buildAddOns(),
        const SizedBox(height: 16),

        // Discount section for mobile
        _buildDiscountSection(),
      ],
    );
  }

  // Desktop/Tablet form layout: side by side
  Widget _buildDesktopTabletFormLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Notes Field
            Expanded(
              flex: 2,
              child: _buildNotesField(),
            ),
            const SizedBox(width: 16),

            // Size Selection
            Expanded(
              flex: 1,
              child: _buildSizeSelection(),
            ),
            const SizedBox(width: 16),

            // Add-ons
            Expanded(
              flex: 2,
              child: _buildAddOns(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Discount section in a new row for desktop/tablet
        _buildDiscountSection(),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catatan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: "Masukkan catatan pelanggan",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => setState(() => customerName = value),
        ),
      ],
    );
  }

  Widget _buildSizeSelection() {
    // Get size options from cart item if available
    final List<String> sizeOptions = ['Small', 'Medium', 'Large'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Size",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        sizeOptions.isEmpty
            ? const Text("Tidak Ada", style: TextStyle(color: Colors.grey))
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: sizeOptions
                      .map((size) => RadioListTile<String>(
                            title: Text(size),
                            value: size,
                            groupValue: selectedOption,
                            onChanged: (value) =>
                                setState(() => selectedOption = value),
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ))
                      .toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildAddOns() {
    // Get addon options from cart item if available
    final List<String> addOnOptions = [
      'Extra Topping',
      'Spicy',
      'Extra Sauce',
      'No Ice'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add-ons",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        addOnOptions.isEmpty
            ? const Text("Tidak Ada", style: TextStyle(color: Colors.grey))
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: addOnOptions
                      .map((feature) => CheckboxListTile(
                            title: Text(feature),
                            value: selectedFeatures.contains(feature),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedFeatures.add(feature);
                                } else {
                                  selectedFeatures.remove(feature);
                                }
                              });
                            },
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ))
                      .toList(),
                ),
              ),
      ],
    );
  }

  // New widget for discount section
  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Diskon",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: applyDiscount,
              onChanged: (value) {
                setState(() {
                  applyDiscount = value ?? false;
                  if (!applyDiscount) {
                    discountController.clear();
                  }
                });
              },
            ),
            const Text("Terapkan Diskon"),
          ],
        ),

        // Dropdown and TextField will appear when the checkbox is checked
        if (applyDiscount) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: discountType,
                items: discountTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      discountType = newValue;
                      discountController
                          .clear(); // Clear value when type changes
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Tipe Diskon",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      discountType == 'Persen' ? "Diskon (%)" : "Diskon (Rp)",
                  hintText: discountType == 'Persen' ? "0%" : "Rp 0",
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    // Validate and update discount values as needed
                  });
                },
              ),
            ],
          ),
        ],

        // Summary of discount applied
        if (applyDiscount && discountAmount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:"),
                    Text(NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(totalBeforeDiscount)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        "Diskon (${discountType == 'Persen' ? '${discountController.text}%' : 'Rp'}):"),
                    Text(
                      "- ${NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp',
                        decimalDigits: 0,
                      ).format(discountAmount)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp',
                        decimalDigits: 0,
                      ).format(totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Quantity: ", style: TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.red),
          onPressed: () {
            if (quantity > 1) {
              setState(() {
                quantity--;
              });
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.green),
          onPressed: () {
            setState(() {
              quantity++;
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Get screen size to determine layout
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 900;

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (isMobile) {
      // Mobile layout: stacked buttons
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Simpan - ${formatter.format(totalPrice)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label:
                const Text("Hapus Item", style: TextStyle(color: Colors.red)),
            onPressed: () {
              widget.cartProvider.removeCartItem(widget.cartItem.id!);
              Navigator.pop(context);
            },
          ),
        ],
      );
    } else {
      // Desktop/Tablet layout: quantity control + buttons in a row
      return Row(
        children: [
          Expanded(child: _buildQuantityControl()),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Simpan - ${formatter.format(totalPrice)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    widget.cartProvider.removeCartItem(widget.cartItem.id!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _saveChanges() {
    try {
      // Ambil dan validasi input diskon jika berlaku
      double discountValue = 0;
      bool isDiscountPercent = false;

      if (applyDiscount) {
        String discountText = discountController.text.trim();
        if (discountText.isNotEmpty && double.tryParse(discountText) != null) {
          discountValue = double.parse(discountText);
          isDiscountPercent = discountType == 'Persen';

          // Validasi diskon jika tipe persen
          if (isDiscountPercent && (discountValue < 0 || discountValue > 100)) {
            throw Exception('Diskon persen harus di antara 0 dan 100.');
          }

          // Validasi diskon jika tipe nominal
          if (!isDiscountPercent && discountValue < 0) {
            throw Exception('Diskon nominal tidak boleh negatif.');
          }
        } else {
          throw Exception('Input diskon tidak valid atau kosong.');
        }
      }

      // Hitung total harga sebelum dan setelah diskon
      final basePrice = widget.cartItem.rate! * quantity.toDouble();
      double finalPrice = basePrice;

      if (applyDiscount && discountValue > 0) {
        if (isDiscountPercent) {
          finalPrice -= (basePrice * discountValue / 100);
        } else {
          finalPrice -= discountValue;
        }
      }

      // Pastikan harga final tidak negatif
      if (finalPrice < 0) finalPrice = 0;

      // Perbarui kuantitas
      widget.cartProvider.updateCartItemQuantity(widget.cartItem.id!, quantity);

      // Perbarui catatan dengan informasi customer, size, dan fitur tambahan
      final notes =
          "Customer: $customerName, Size: $selectedOption, Add-ons: ${selectedFeatures.join(', ')}";
      widget.cartProvider.updateCartItemNotes(widget.cartItem.id!, notes);

      // Perbarui informasi diskon jika berlaku
      if (applyDiscount) {
        widget.cartProvider.updateCartItemDiscount(
          widget.cartItem.id!,
          discountValue,
          isDiscountPercent,
        );

        // Perbarui harga total dengan diskon
        widget.cartProvider
            .updateCartItemTotalPrice(widget.cartItem.id!, finalPrice);
      } else {
        // Hapus diskon jika tidak berlaku
        widget.cartProvider
            .updateCartItemDiscount(widget.cartItem.id!, 0, false);

        // Reset harga total ke harga dasar
        widget.cartProvider
            .updateCartItemTotalPrice(widget.cartItem.id!, basePrice);
      }

      // Tutup dialog atau halaman edit
      Navigator.pop(context);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Input tidak valid: ${e.toString()}')),
      );
    }
  }
}
