class Addon {
  final String id;
  final String name;
  final int price;

  Addon({
    required this.id,
    required this.name,
    required this.price,
  });

  // Tambahkan dari JSON jika diperlukan
  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] is int ? json['price'] : int.parse(json['price'] ?? '0'),
    );
  }
}
