class Payment {
  final String modeOfPayment;
  final double amount;
  final double baseAmount;
  final String referenceNumber;
  final String account;

  Payment({
    required this.modeOfPayment,
    required this.amount,
    required this.baseAmount,
    required this.referenceNumber,
    required this.account,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      modeOfPayment: json['mode_of_payment'],
      amount: json['amount'].toDouble(),
      baseAmount: json['base_amount'].toDouble(),
      referenceNumber: json['reference_number'],
      account: json['account'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode_of_payment': modeOfPayment,
      'amount': amount,
      'base_amount': baseAmount,
      'reference_number': referenceNumber,
      'account': account,
    };
  }
}