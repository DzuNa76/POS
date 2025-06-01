import 'package:pos/data/models/models.dart';

class ProductDetailModel {
  final String id;
  final String name;
  final String description;
  final String price;
  final List<String> options;
  final List<String> preferences;
  final List<Addon> addons;

  ProductDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.options,
    required this.preferences,
    required this.addons,
  });

  // Tambahkan dari JSON jika diperlukan
  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      options: List<String>.from(json['options'] ?? []),
      preferences: List<String>.from(json['preferences'] ?? []),
      addons: (json['addons'] as List<dynamic>?)
              ?.map((addon) => Addon.fromJson(addon))
              .toList() ??
          [],
    );
  }
}
