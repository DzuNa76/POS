import 'package:flutter/material.dart';
import 'package:pos/data/models/models.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductDetailModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // States for dropdown and quantity
  String? selectedOption;
  String? selectedPreference;
  Map<String, int> addonQuantities = {};
  int orderQuantity = 1;

  @override
  void initState() {
    super.initState();
    // Initialize add-on quantities to 0
    for (var addon in widget.product.addons) {
      addonQuantities[addon.id] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Box
              _buildProductInfo(),
              const SizedBox(height: 16),

              // Dropdown for Options
              _buildDropdownField(
                label: 'Opsi',
                items: widget.product.options,
                onChanged: (value) => setState(() {
                  selectedOption = value;
                }),
              ),
              const SizedBox(height: 16),

              // Dropdown for Preferences
              _buildDropdownField(
                label: 'Preferensi',
                items: widget.product.preferences,
                onChanged: (value) => setState(() {
                  selectedPreference = value;
                }),
              ),
              const SizedBox(height: 16),

              // Add-On List
              _buildAddonList(),
              const SizedBox(height: 16),

              // Quantity Selector for Main Order
              const Text(
                'Jumlah Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              QuantitySelector(
                quantity: orderQuantity,
                onIncrement: () => setState(() {
                  orderQuantity++;
                }),
                onDecrement: () => setState(() {
                  if (orderQuantity > 1) orderQuantity--;
                }),
              ),
              const SizedBox(height: 16),

              // Total Price Button
              _buildTotalPriceButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(widget.product.description),
          const SizedBox(height: 8),
          Text(
            widget.product.price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownField(
      label: label,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildAddonList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add-On',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.product.addons.map((addon) {
          return AddonItem(
            name: addon.name,
            price: addon.price.toString(),
            quantity: addonQuantities[addon.id]!,
            onIncrement: () => setState(() {
              addonQuantities[addon.id] = addonQuantities[addon.id]! + 1;
            }),
            onDecrement: () => setState(() {
              if (addonQuantities[addon.id]! > 0) {
                addonQuantities[addon.id] = addonQuantities[addon.id]! - 1;
              }
            }),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalPriceButton() {
    final basePrice = int.parse(
        widget.product.price.replaceAll(RegExp(r'[^\d]'), ''));
    final totalBasePrice = basePrice * orderQuantity;

    final totalAddonPrice = widget.product.addons.fold<int>(
      0,
      (sum, addon) => sum + (addon.price * addonQuantities[addon.id]!),
    );

    final totalPrice = totalBasePrice + totalAddonPrice;

    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context, {
          'name': widget.product.name,
          'quantity': orderQuantity,
          'totalPrice': totalPrice,
          'options': selectedOption ?? '-',
          'preferences': selectedPreference ?? '-',
          'addons': addonQuantities.entries
              .where((entry) => entry.value > 0)
              .map((entry) => {
                    'id': entry.key,
                    'quantity': entry.value,
                  })
              .toList(),
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(
        'Total: Rp$totalPrice',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
