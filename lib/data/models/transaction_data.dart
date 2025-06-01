class TransactionData {
  final String customerName;
  final String status;
  final String type;
  final String transactionId;
  final String date;
  final String totalOrder;

  TransactionData({
    required this.customerName,
    required this.status,
    required this.type,
    required this.transactionId,
    required this.date,
    required this.totalOrder,
  });
}
