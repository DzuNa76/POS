import 'dart:math';

class CartItem {
  final String? id;
  final String? itemCode;
  final String? itemName;
  final String? description;
  final String? uom;
  final int? conversionFactor;
  final int? qty;
  final int? rate;
  final int? amount;
  final int? baseRate;
  final int? baseAmount;
  final int? priceListRate;
  final String? costCenter;
  final String? notes;
  final bool? voucherApplied;

  final double? discountValue; // Nilai diskon
  final bool isDiscountPercent; // True jika diskon dalam persen

  CartItem({
    this.id,
    this.itemCode,
    this.itemName,
    this.description,
    this.uom,
    this.conversionFactor,
    this.qty,
    this.rate,
    this.amount,
    this.baseRate,
    this.baseAmount,
    this.priceListRate,
    this.costCenter,
    this.notes,
    this.discountValue, // Diskon opsional
    this.isDiscountPercent = true, // Default: diskon persen
    this.voucherApplied,
  });

  /// Hitung subtotal dengan diskon
  int get subtotal {
    double initialSubtotal = rate! * qty!.toDouble();

    if (discountValue != null && discountValue! > 0) {
      if (isDiscountPercent) {
        // Diskon dalam persen
        double discountAmount = initialSubtotal * (discountValue! / 100);
        return (initialSubtotal - discountAmount).round();
      } else {
        // Diskon dalam nominal
        double discountAmount = discountValue!;
        return (initialSubtotal - discountAmount)
            .clamp(0, double.infinity)
            .round();
      }
    }

    return initialSubtotal.round();
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      itemCode: json['itemCode'],
      itemName: json['itemName'],
      description: json['description'],
      uom: json['uom'],
      conversionFactor: json['conversionFactor'],
      qty: json['qty'],
      rate: json['rate'],
      amount: json['amount'],
      baseRate: json['baseRate'],
      baseAmount: json['baseAmount'],
      priceListRate: json['priceListRate'],
      costCenter: json['costCenter'],
      notes: json['notes'],
      discountValue: json['discountValue']?.toDouble(),
      isDiscountPercent: json['isDiscountPercent'] ?? true,
      voucherApplied: json['voucherApplied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCode': itemCode,
      'itemName': itemName,
      'description': description,
      'uom': uom,
      'conversionFactor': conversionFactor,
      'qty': qty,
      'rate': rate,
      'amount': amount,
      'baseRate': baseRate,
      'baseAmount': baseAmount,
      'priceListRate': priceListRate,
      'costCenter': costCenter,
      'notes': notes,
      'discountValue': discountValue,
      'isDiscountPercent': isDiscountPercent,
      'voucherApplied': voucherApplied,
    };
  }

  CartItem copyWith({
    String? id,
    String? notes,
    int? qty,
    int? amount, // Tambahkan parameter untuk amount
    double? discountValue,
    bool? isDiscountPercent,
    bool? voucherApplied,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemCode: itemCode,
      itemName: itemName,
      description: description,
      uom: uom,
      conversionFactor: conversionFactor,
      qty: qty ?? this.qty,
      rate: rate,
      amount: amount ?? this.amount, // Perbarui amount
      baseRate: baseRate,
      baseAmount: baseAmount,
      priceListRate: priceListRate,
      costCenter: costCenter,
      notes: notes ?? this.notes,
      discountValue: discountValue ?? this.discountValue,
      isDiscountPercent: isDiscountPercent ?? this.isDiscountPercent,
      voucherApplied: voucherApplied ?? this.voucherApplied,
    );
  }

  static String generateRandomId() {
    final random = Random();
    return random.nextInt(1000000).toString();
  }
}
