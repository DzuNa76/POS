class Voucher {
  final String id;
  final String name;
  final double
      discount; // Diskon dalam bentuk persentase (misalnya, 0.1 untuk 10%).
  final bool isGlobal;
  final String? applicableItemId;

  Voucher({
    required this.id,
    required this.name,
    required this.discount,
    required this.isGlobal,
    this.applicableItemId,
  });

  /// Menghitung nilai nominal diskon (amount) berdasarkan harga dasar.
  double calculateAmount(double basePrice) {
    return basePrice * discount; // Contoh: diskon dihitung dari harga dasar.
  }
}
