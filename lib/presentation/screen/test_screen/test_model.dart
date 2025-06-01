import 'dart:convert';

class SalesInvoice1 {
  final String name;
  final String customerName;
  final double total;
  final String status;
  final List<Item> items;

  SalesInvoice1({
    required this.name,
    required this.customerName,
    required this.total,
    required this.status,
    required this.items,
  });

  factory SalesInvoice1.fromJson(Map<String, dynamic> json) {
    return SalesInvoice1(
      name: json['name'],
      customerName: json['customer_name'],
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      items: (json['items'] as List).map((item) => Item.fromJson(item)).toList(),
    );
  }
}

class Item {
  final String itemCode;
  final String itemName;
  final double qty;
  final double rate;
  final double amount;

  Item({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      qty: (json['qty'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
