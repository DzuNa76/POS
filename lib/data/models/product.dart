import 'addon.dart';
import 'package:pos/data/models/item_model.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final int price;
  final String imageUrl;
  final bool isAvailable;
  final List<Addon>? addons;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
    this.addons,
  });

  // Metode konversi dari Item ke Product
  factory Product.fromItem(Item item) {
    return Product(
      id: item.itemCode ??
          'default-id', // Gunakan item_code sebagai ID jika ada
      name: item.name,
      category:
          item.itemGroup ?? 'Uncategorized', // Ambil kategori dari item_group
      description: item.description ??
          'No description available', // Ambil deskripsi dari Item
      price: item.standardRate?.toInt() ??
          0, // Ambil harga dari standard_rate, default ke 0
      imageUrl: item.image ??
          'assets/test.jpg', // Gunakan image dari database jika ada
      isAvailable:
          item.disabled == 0, // Jika disabled = 0, berarti item tersedia
      addons: [], // Tambahkan jika ada data add-on
    );
  }
}
