// // lib/presentation/widgets/product_grid/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/models/item_model.dart';

class ProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Expanded to prevent overflow
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.asset(
                  'assets/testing.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductTitle(),
                  _buildProductPrice(),
                  _buildStockInfo(),
                  _buildDiscountInfo(),
                  _buildCategoryBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      item.itemName ?? '-',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductPrice() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Text(
      item.standardRate != null ? formatter.format(item.standardRate) : 'N/A',
      style: const TextStyle(
        color: Colors.green,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStockInfo() {
    if (item.totalProjectedQty == null) return const SizedBox.shrink();

    return Text(
      "Stok: ${item.totalProjectedQty!.toStringAsFixed(0)}",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildDiscountInfo() {
    if ((item.maxDiscount ?? 0) <= 0) return const SizedBox.shrink();

    return Text(
      "Diskon: ${item.maxDiscount?.toStringAsFixed(2)}%",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.red,
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.itemGroup ?? 'Kategori Tidak Diketahui',
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}