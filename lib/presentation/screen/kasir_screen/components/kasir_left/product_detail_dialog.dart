import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/providers/discount_provider.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/product_detail_form.dart';
import 'package:provider/provider.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/core/providers/cart_provider.dart';

class ProductDetailDialog extends StatefulWidget {
  final Item item;

  const ProductDetailDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  int quantity = 1;

  // Discount related variables
  bool applyDiscount = false;
  String discountType = 'Rupiah'; // Default discount type
  final List<String> discountTypes = ['Persen', 'Rupiah'];
  final TextEditingController discountController = TextEditingController();

  // Calculate total price with discount
  double get totalBeforeDiscount => (widget.item.standardRate ?? 0) * quantity;
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

  // Form data
  String? customerName;
  String? selectedOption;
  List<String> selectedFeatures = [];

  // Controllers for form fields
  final TextEditingController noteController = TextEditingController();

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
      dialogWidth = screenSize.width * 0.7; // 50% of screen width for desktop
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
            _buildCheckoutButton(),
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
            widget.item.itemName ?? "Item Detail",
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
    // Periksa apakah opsi ukuran tersedia
    final List<String>? sizeOptions =
        widget.item.assetCategory as List<String>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Size",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        sizeOptions == null || sizeOptions.isEmpty
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
    // Periksa apakah opsi add-on tersedia
    final List<String>? addOnOptions = widget.item.hasVariants as List<String>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add-ons",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        addOnOptions == null || addOnOptions.isEmpty
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
    // Get the discount settings from provider
    final discountSettings = Provider.of<DiscountSettingsProvider>(context);

    // If discount is disabled globally, don't show the section at all
    if (!discountSettings.isDiscountEnabled) {
      return Container(); // Return empty container
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Diskon",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Checkbox for applying discount
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

        // Show dropdown and text field below checkbox if discount is enabled
        if (applyDiscount) ...[
          const SizedBox(height: 8),
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
                  // Reset discount value when changing type
                  discountController.clear();
                });
              }
            },
            decoration: const InputDecoration(
              labelText: "Pilih Tipe Diskon",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: discountType == 'Persen' ? "0%" : "Rp 0",
              labelText:
                  discountType == 'Persen' ? "Diskon (%)" : "Diskon (Rp)",
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              // Add validation based on max discount percentage
              if (discountType == 'Persen' && value.isNotEmpty) {
                try {
                  double enteredValue = double.parse(value);
                  if (enteredValue > discountSettings.maxDiscountPercentage) {
                    discountController.text =
                        discountSettings.maxDiscountPercentage.toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Diskon maksimal: ${discountSettings.maxDiscountPercentage}%'),
                      ),
                    );
                  }
                } catch (_) {}
              }
              setState(() {});
            },
          ),
        ],

        // Show discount summary if discount is applied
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

  // In mobile this appears above the checkout button
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

  Widget _buildCheckoutButton() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    // For desktop/tablet, show the quantity control alongside the button
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    final formattedTotalPrice = formatter.format(totalPrice);

    if (isMobile) {
      // Mobile layout: Just the button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Checkout - $formattedTotalPrice",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      // Desktop/Tablet layout: Quantity control + button in a row
      return Row(
        children: [
          Expanded(child: _buildQuantityControl()),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Checkout - $formattedTotalPrice",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Ambil dan validasi input diskon jika berlaku
    double discountAmount = 0;
    if (applyDiscount) {
      try {
        String discountValue = discountController.text.trim();
        if (discountValue.isEmpty || double.tryParse(discountValue) == null) {
          throw Exception('Nilai diskon tidak valid.');
        }

        discountAmount = double.parse(discountValue);

        if (discountType == 'Persen') {
          if (discountAmount < 0 || discountAmount > 100) {
            throw Exception('Diskon persen harus di antara 0 dan 100.');
          }
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Input diskon tidak valid: ${e.toString()}')),
        );
        return;
      }
    }

    // Hitung total harga sebelum dan setelah diskon
    final basePrice = (widget.item.standardRate ?? 0) * quantity;
    double totalPrice = basePrice;

    if (applyDiscount && discountAmount > 0) {
      if (discountType == 'Persen') {
        totalPrice -= (basePrice * discountAmount / 100);
      } else {
        totalPrice -= discountAmount;
      }
    }

    // Pastikan totalPrice tidak negatif
    if (totalPrice < 0) totalPrice = 0;

    // Panggil addItem dengan totalPrice
    cart.addItem(
      widget.item,
      quantity,
      notes:
          "Customer: $customerName, Size: $selectedOption, Add-ons: ${selectedFeatures.join(', ')}",
      discountValue: applyDiscount ? discountAmount : 0,
      isDiscountPercent: applyDiscount && discountType == 'Persen',
      totalPrice: totalPrice, // Kirim totalPrice ke CartProvider
    );

    Navigator.pop(context);
  }
}
