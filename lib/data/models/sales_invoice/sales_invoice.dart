import 'dart:convert';

import 'package:pos/data/models/mode_of_payment_models.dart';

class SalesInvoice {
  final String name;
  final String owner;
  final String creation;
  final String modified;
  final String modifiedBy;
  final int docstatus;
  final String title;
  final String customer;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String company;
  final String postingDate;
  final double total;
  final double netTotal;
  final double grandTotal;
  final double outstandingAmount;
  final String currency;
  final List<ModeOfPayments> mode_of_payment;
  final List<SalesInvoiceItem> items;
  final List<PaymentSchedule> paymentSchedule;
  final String status;

  SalesInvoice({
    required this.name,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
    required this.docstatus,
    required this.title,
    required this.customer,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.company,
    required this.postingDate,
    required this.total,
    required this.netTotal,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.currency,
    required this.mode_of_payment,
    required this.items,
    required this.paymentSchedule,
    required this.status,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    List<SalesInvoiceItem> parsedItems = [];
    List<ModeOfPayments> parsedModeOfPayments = [];

    // Decode custom_ui_items jika ada
    if (json['custom_ui_items'] != null && json['custom_ui_items'] is String) {
      try {
        List<dynamic> decodedItems = jsonDecode(json['custom_ui_items']);
        parsedItems = decodedItems
            .map((item) => SalesInvoiceItem.fromJson(item))
            .toList();
      } catch (e) {
        print("Error decoding custom_ui_items: $e");
      }
    }

    // decode custom_mode_of_payments jika ada
    if (json['custom_ui_mode_of_payment'] != null &&
        json['custom_ui_mode_of_payment'] is String) {
      try {
        List<dynamic> decodedItems =
            jsonDecode(json['custom_ui_mode_of_payment']);
        parsedModeOfPayments =
            decodedItems.map((item) => ModeOfPayments.fromJson(item)).toList();
      } catch (e) {
        print("Error decoding custom_mode_of_payments: $e");
      }
    }

    return SalesInvoice(
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      creation: json['creation'] ?? '',
      modified: json['modified'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      title: json['title'] ?? '',
      customer: json['customer'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['custom_customer_phone'] ?? '',
      customerAddress: json['custom_address'] ?? '',
      company: json['company'] ?? '',
      postingDate: json['posting_date'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      netTotal: (json['net_total'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount:
          (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? '',
      mode_of_payment: parsedModeOfPayments,
      items: parsedItems, // Menggunakan custom_ui_items yang sudah diproses
      paymentSchedule: (json['payment_schedule'] as List?)
              ?.map((pay) => PaymentSchedule.fromJson(pay))
              .toList() ??
          [],
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'creation': creation,
      'modified': modified,
      'modified_by': modifiedBy,
      'docstatus': docstatus,
      'title': title,
      'customer': customer,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'company': company,
      'posting_date': postingDate,
      'total': total,
      'net_total': netTotal,
      'grand_total': grandTotal,
      'outstanding_amount': outstandingAmount,
      'currency': currency,
      'mode_of_payment':
          mode_of_payment.map((payment) => payment.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(),
      'payment_schedule': paymentSchedule.map((pay) => pay.toJson()).toList(),
      'status': status,
    };
  }
}

class ModeOfPayments {
  final String mode;
  final double amount;

  ModeOfPayments({
    required this.mode,
    required this.amount,
  });

  factory ModeOfPayments.fromJson(Map<String, dynamic> json) {
    return ModeOfPayments(
      mode: json['mode_of_payment'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': mode,
      'amount': amount,
    };
  }
}

class SalesInvoiceItem {
  final String name;
  final String itemCode;
  final String itemName;
  final String description;
  final double qty;
  final String stockUom;
  final double priceListRate;
  final double discountPercentage;
  final double discountAmount;
  final double rate;
  final double amount;
  final String warehouse;
  final String? status;

  SalesInvoiceItem({
    required this.name,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.qty,
    required this.stockUom,
    required this.priceListRate,
    required this.discountPercentage,
    required this.discountAmount,
    required this.rate,
    required this.amount,
    required this.warehouse,
    this.status = '',
  });

  factory SalesInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceItem(
      name: json['name'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      stockUom: json['stock_uom'] ?? '',
      priceListRate: (json['price_list_rate'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      warehouse: json['warehouse'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'item_code': itemCode,
      'item_name': itemName,
      'description': description,
      'qty': qty,
      'stock_uom': stockUom,
      'price_list_rate': priceListRate,
      'discount_percentage': discountPercentage,
      'rate': rate,
      'amount': amount,
      'warehouse': warehouse,
    };
  }
}

class PaymentSchedule {
  final String name;
  final String dueDate;
  final double invoicePortion;
  final double paymentAmount;
  final double outstanding;

  PaymentSchedule({
    required this.name,
    required this.dueDate,
    required this.invoicePortion,
    required this.paymentAmount,
    required this.outstanding,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      name: json['name'] ?? '',
      dueDate: json['due_date'] ?? '',
      invoicePortion: (json['invoice_portion'] as num?)?.toDouble() ?? 0.0,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0.0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'due_date': dueDate,
      'invoice_portion': invoicePortion,
      'payment_amount': paymentAmount,
      'outstanding': outstanding,
    };
  }
}
