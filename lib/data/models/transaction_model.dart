class TransactionModel {
  final String transactionId;
  final String customerName;
  final String paymentMethod;
  final String referralCode;
  final String cashierName;
  final String transactionDate;
  final int subtotal;
  final int tax;
  final int total;
  final int paid;
  final int change;
  final int timestamp;
  final List<OrderItemModel> orderItems;

  TransactionModel({
    required this.transactionId,
    required this.customerName,
    required this.paymentMethod,
    required this.referralCode,
    required this.cashierName,
    required this.transactionDate,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.timestamp,
    required this.orderItems,
  });

  // Convert TransactionModel to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'referralCode': referralCode,
      'cashierName': cashierName,
      'transactionDate': transactionDate,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paid': paid,
      'change': change,
      'timestamp': timestamp,
    };
  }

  // Create TransactionModel from Map (from database)
  factory TransactionModel.fromMap(Map<String, dynamic> map, List<OrderItemModel> items) {
    return TransactionModel(
      transactionId: map['transactionId'],
      customerName: map['customerName'],
      paymentMethod: map['paymentMethod'],
      referralCode: map['referralCode'] ?? '',
      cashierName: map['cashierName'],
      transactionDate: map['transactionDate'],
      subtotal: map['subtotal'],
      tax: map['tax'],
      total: map['total'],
      paid: map['paid'],
      change: map['change'],
      timestamp: map['timestamp'],
      orderItems: items,
    );
  }
}

class OrderItemModel {
  final String transactionId;
  final String name;
  final int quantity;
  final int price;

  OrderItemModel({
    required this.transactionId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  // Convert OrderItemModel to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  // Create OrderItemModel from Map (from database)
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      transactionId: map['transactionId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
    );
  }
}