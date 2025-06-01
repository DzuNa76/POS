import 'package:flutter/material.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:provider/provider.dart';

class ProductCategories extends StatelessWidget {
  // Map of common item groups to icons
  final Map<String, IconData> categoryIcons = {
    'Makanan': Icons.restaurant,
    'Minuman': Icons.local_drink,
    'Camilan': Icons.fastfood,
    'Dessert': Icons.icecream,
    'Kopi': Icons.coffee,
    'Teh': Icons.emoji_food_beverage,
    'Jus': Icons.local_cafe,
    'Paket': Icons.local_offer,
    'Promo': Icons.card_giftcard,
    // Default icon for other categories
  };

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Get unique item groups from all items
    final Set<String> uniqueItemGroups = productProvider.allItems
        .where((item) => item.itemGroup != null && item.itemGroup!.isNotEmpty)
        .map((item) => item.itemGroup!)
        .toSet();

    // Convert to list for the ListView
    final List<String> itemGroups = uniqueItemGroups.toList()..sort();

    // If no categories available yet, show loading indicator
    if (itemGroups.isEmpty && productProvider.isLoading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // If no categories available and not loading, show a message
    if (itemGroups.isEmpty && !productProvider.isLoading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text("Tidak ada kategori tersedia"),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemGroups.length + 1, // +1 for "All" category
        itemBuilder: (context, index) {
          // First item is "All" category
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton.icon(
                onPressed: productProvider.isCategoryLoading
                    ? null // Disable button when loading
                    : () {
                        // Reset the category filter to show all items
                        productProvider.filterByCategory(null);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 14),
                  backgroundColor: productProvider.selectedCategory == null
                      ? Color(0xFF533F77)
                      : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[500],
                ),
                icon: productProvider.isCategoryLoading &&
                        productProvider.selectedCategory == null
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.all_inclusive,
                        size: 18,
                        color: Colors.white,
                      ),
                label: Text("Semua"),
              ),
            );
          }

          final category = itemGroups[index - 1];
          final bool isSelected = productProvider.selectedCategory == category;
          final bool isLoading =
              productProvider.isCategoryLoading && isSelected;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton.icon(
              onPressed: productProvider.isCategoryLoading
                  ? null // Disable all buttons when any category is loading
                  : () {
                      // Filter products by this category
                      productProvider.filterByCategory(category);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 14),
                backgroundColor:
                    isSelected ? Color(0xFF533F77) : Colors.grey[500],
                disabledBackgroundColor: isSelected
                    ? Color(0xFF533F77).withOpacity(0.7)
                    : Colors.grey[500],
              ),
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      categoryIcons[category] ?? Icons.category,
                      size: 18,
                      color: Colors.white,
                    ),
              label: Text(category),
            ),
          );
        },
      ),
    );
  }
}
