import 'package:pos/data/models/cart_item.dart'; // Ganti Item menjadi CartItem
import 'package:pos/data/models/payment_model.dart';

class Invoice {
  final int docstatus;
  final String namingSeries;
  final String company;
  final String costCenter;
  final String postingDate;
  final String postingTime;
  final int setPostingTime;
  final int isPos;
  final String currency;
  final double conversionRate;
  final String sellingPriceList;
  final String priceListCurrency;
  final double baseNetTotal;
  final double baseGrandTotal;
  final double grandTotal;
  final String customer;
  final String posProfile;
  final List<Payment> payments;
  final List<CartItem> items; // Ganti Item menjadi CartItem
  final int updateStock;
  final String debitTo;

  Invoice({
    required this.docstatus,
    required this.namingSeries,
    required this.company,
    required this.costCenter,
    required this.postingDate,
    required this.postingTime,
    required this.setPostingTime,
    required this.isPos,
    required this.currency,
    required this.conversionRate,
    required this.sellingPriceList,
    required this.priceListCurrency,
    required this.baseNetTotal,
    required this.baseGrandTotal,
    required this.grandTotal,
    required this.customer,
    required this.posProfile,
    required this.payments,
    required this.items, // Menggunakan CartItem
    required this.updateStock,
    required this.debitTo,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      docstatus: json['docstatus'],
      namingSeries: json['naming_series'],
      company: json['company'],
      costCenter: json['cost_center'],
      postingDate: json['posting_date'],
      postingTime: json['posting_time'],
      setPostingTime: json['set_posting_time'],
      isPos: json['is_pos'],
      currency: json['currency'],
      conversionRate: json['conversion_rate'].toDouble(),
      sellingPriceList: json['selling_price_list'],
      priceListCurrency: json['price_list_currency'],
      baseNetTotal: json['base_net_total'].toDouble(),
      baseGrandTotal: json['base_grand_total'].toDouble(),
      grandTotal: json['grand_total'].toDouble(),
      customer: json['customer'],
      posProfile: json['pos_profile'],
      payments: (json['payments'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item)) // Menggunakan CartItem
          .toList(),
      updateStock: json['update_stock'],
      debitTo: json['debit_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docstatus': docstatus,
      'naming_series': namingSeries,
      'company': company,
      'cost_center': costCenter,
      'posting_date': postingDate,
      'posting_time': postingTime,
      'set_posting_time': setPostingTime,
      'is_pos': isPos,
      'currency': currency,
      'conversion_rate': conversionRate,
      'selling_price_list': sellingPriceList,
      'price_list_currency': priceListCurrency,
      'base_net_total': baseNetTotal,
      'base_grand_total': baseGrandTotal,
      'grand_total': grandTotal,
      'customer': customer,
      'pos_profile': posProfile,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(), // Menggunakan CartItem
      'update_stock': updateStock,
      'debit_to': debitTo,
    };
  }
}
