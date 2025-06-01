import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/core/utils/resiGenerator.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:pos/data/api/sales_invoice.dart' as sales_data;
import 'package:shared_preferences/shared_preferences.dart';

class SalesDataActions {
  static Future<List<SalesInvoice>> getDataSearch(
      int limit,
      int start,
      String filter,
      String dateStart,
      String dateEnd,
      String modeOfPayment) async {
    try {
      final response = await sales_data.getSalesInvoice(
          limit, start, filter, dateStart, dateEnd, modeOfPayment, '', '');

      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }
      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      print('Error fetching sales data: $e');
      return []; // Kembalikan list kosong jika terjadi error
    }
  }

  static Future<List<SalesInvoice>> getDataSearchDraft(int limit, int start,
      String filter, String dateStart, String dateEnd) async {
    try {
      final response = await sales_data.getSalesDraft(
          limit, start, filter, dateStart, dateEnd);

      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      print('Error fetching sales data: $e');
      return []; // Kembalikan list kosong jika terjadi error
    }
  }

  static Future<List<SalesInvoice>> getDataUnpaid(String customerCode) async {
    try {
      final response = await sales_data.getSalesInvoiceUnpaid(
        999,
        0,
        '',
        '',
        '',
        customerCode,
      );
      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      print('Error fetching sales data: $e');
      return []; // Kembalikan list kosong jika terjadi error
    }
  }

  static Future<List<SalesInvoice>> getAllDatas() async {
    try {
      final now = DateTime.now();
      final formattedDate =
          '${now.year.toString().padLeft(4, '0')}-${(now.month + 1).toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await sales_data.getSalesInvoice(
          1, 0, '', formattedDate, formattedDate, '', '', '');
      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch salesss data: $e');
    }
  }

  static Future<List<SalesInvoice>> getReturDatas(String invoiceId) async {
    try {
      final response = await sales_data.getSalesInvoice(
          50, 0, '', '', '', '', 'Return', invoiceId);
      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch salesss data: $e');
    }
  }

  static Future<List<SalesInvoice>> getAllDatasDraft() async {
    try {
      final now = DateTime.now();
      final formattedDate =
          '${now.year.toString().padLeft(4, '0')}-${(now.month + 1).toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await sales_data.getSalesDraft(10, 0, '', '', '');
      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final List<dynamic> datasJson = response['data'];
        return datasJson.map((json) => SalesInvoice.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch salesss data: $e');
    }
  }

  static Future<SalesInvoice> cancelSalesInvoice(String invoiceId) async {
    try {
      final Map<String, dynamic> response =
          await sales_data.cancelSalesInvoice(invoiceId);

      // Check if response contains a message field with the invoice data
      if (response.containsKey('message')) {
        // The message field contains a single invoice object, not a list
        final Map<String, dynamic> invoiceJson = response['message'];
        return SalesInvoice.fromJson(invoiceJson);
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      print("Error in service layer: $e");
      rethrow; // Rethrow to allow handling in UI layer
    }
  }

  static Future<bool> deleteSalesInvoice(String invoiceId) async {
    try {
      final Map<String, dynamic> response =
          await sales_data.deleteSalesInvoice(invoiceId);

      // Periksa respons dengan benar
      if (response.containsKey('data') && response['data'] == "ok") {
        print("Delete successful: ${response.toString()}");
        return true;
      } else {
        print("Unexpected response format: ${response.toString()}");
        return false;
      }
    } catch (e) {
      print("Error in service layer: $e");
      rethrow; // Rethrow untuk memungkinkan penanganan di UI layer
    }
  }

  static Future<bool> returnSalesInvoiceItemAction(
      {required String originalInvoiceId,
      required String itemCode,
      required String customer,
      required double qty,
      required double rate,
      required dynamic modeOfPayment}) async {
    try {
      final Map<String, dynamic> response =
          await sales_data.returnSalesInvoiceItem(
              customer: customer,
              originalInvoiceId: originalInvoiceId,
              itemCode: itemCode,
              qty: qty,
              rate: rate,
              modeOfPayment: modeOfPayment);

      // Cek jika response punya field 'data' dengan 'name' (berarti sukses dibuat)
      if (response.containsKey('data') &&
          response['data'].containsKey('name')) {
        print("Return successful: ${response['data']['name']}");
        return true;
      } else {
        print("Unexpected response format: ${response.toString()}");
        return false;
      }
    } catch (e) {
      print("Error in return service layer: $e");
      rethrow;
    }
  }

  static Future<dynamic> postSalesInvoice({
    required String customerCode,
    required String customerName,
    required List<Map<String, dynamic>> dataItems,
    required double totalPrice,
    required double billedAmount,
    required String channel,
  }) async {
    final Map<String, dynamic> payload = {
      "customer": customerCode,
      "items": dataItems,
      "docstatus": 0,
      "is_pos": 1,
      "custom_channel": channel,
    };

    try {
      final response = await sales_data.postSalesInvoice(payload);
      return response;
    } catch (e) {
      throw Exception('Error in Sales Invoice Service: $e');
    }
  }

  static Future<dynamic> postBayarPaidSalesInvoice({
    required String customerCode,
    required List<Map<String, dynamic>> dataItems,
    required String modeOfPayment,
    required double totalAmount,
    required String defaultAccount,
    required String channel,
    String? remarks,
  }) async {
    final Map<String, dynamic> payload = {
      "customer": customerCode,
      "items": dataItems,
      "docstatus": 1,
      "is_pos": 1,
      "paid_amount": totalAmount,
      "base_paid_amount": totalAmount,
      "custom_channel": channel,
      "payments": [
        {
          "mode_of_payment": modeOfPayment,
          "amount": totalAmount,
          "account": defaultAccount,
          "base_amount": totalAmount,
        }
      ],
      if (modeOfPayment != 'TUNAI') "remarks": remarks,
    };

    try {
      print(jsonEncode(payload));
      final response = await sales_data.postSalesInvoice(payload);

      return response;
    } catch (e) {
      throw Exception('Error in Sales Invoice Service: $e');
    }
  }

  static Future<dynamic> updateSalesInvoiceToPaid(
      {required String invoiceId,
      required double totalAmount,
      required String modeOfPayment,
      String? remarks}) async {
    try {
      final Map<String, dynamic> updatePayload = {
        "paid_amount": totalAmount,
        "payments": [
          {
            "mode_of_payment": modeOfPayment,
            "amount": totalAmount,
          }
        ],
        if (modeOfPayment != 'TUNAI') "remarks": remarks,
      };

      await sales_data.updateSalesInvoice(invoiceId, updatePayload);
      await sales_data.submitSalesInvoice(invoiceId);

      return {"status": "success", "message": "Sales Invoice updated to Paid"};
    } catch (e) {
      throw Exception('Error updating Sales Invoice to Paid: $e');
    }
  }

  static Future<dynamic> printResi(
      {required String customerName,
      required String customerAddress,
      required String customerPhone,
      required String senderName,
      required String senderAddress,
      required String senderPhone,
      required String invoiceId,
      required String ipAddress,
      required String printerName}) async {
    try {
      final String base64Image =
          await ReceiptGenerator.generateReceiptPdfBase64(
        recipientName: customerName,
        recipientPhone: customerPhone,
        recipientAddress: customerAddress,
        senderName: senderName,
        senderPhone: senderPhone,
        senderAddress: senderAddress,
      );

      final printPayload = {
        "data": [base64Image],
        "printer": printerName
      };

      final responses = await http.post(
        Uri.parse('http://${ipAddress}:5577/printGeneric'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(printPayload),
      );

      print('response: ${responses.body}');
      if (responses.statusCode == 200) {
        log('Print success');
      } else {
        log('Print failed: ${responses.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in Print Resi Service: $e');
    }
  }

  static Future<dynamic> printReceipt(
      {required String invoiceId,
      required String ipAddress,
      required String printerName,
      String status = ''}) async {
    try {
      Future<List<Map<String, dynamic>>> processItemsWithReturnData(
          String invoiceName, List<dynamic> originalItems) async {
        try {
          // Mendapatkan data retur berdasarkan nama invoice
          final List<SalesInvoice> returInvoices =
              await getReturDatas(invoiceName);

          // Jika tidak ada retur, kembalikan items original tanpa perubahan
          if (returInvoices.isEmpty) {
            return List<Map<String, dynamic>>.from(originalItems);
          }

          // Proses item dengan return data
          List<Map<String, dynamic>> editedItems = [];

          for (var originalItem in originalItems) {
            // Konversi item original ke Map untuk memudahkan editing
            Map<String, dynamic> itemMap =
                Map<String, dynamic>.from(originalItem);

            double totalReturnQty = 0;

            // Periksa setiap return invoice
            for (var returnInvoice in returInvoices) {
              // Cari item yang sesuai di return invoice
              for (var returnItem in returnInvoice.items) {
                if (returnItem.itemCode == itemMap['item_code']) {
                  // Akumulasi total return quantity (biasanya negatif)
                  totalReturnQty += returnItem.qty;
                }
              }
            }

            // Jika item ini memiliki retur
            if (totalReturnQty != 0) {
              // Hitung qty dan amount baru
              double originalQty = itemMap['qty'] is num
                  ? (itemMap['qty'] as num).toDouble()
                  : 0.0;
              double originalRate = itemMap['rate'] is num
                  ? (itemMap['rate'] as num).toDouble()
                  : 0.0;

              double newQty = originalQty + totalReturnQty;
              double newAmount = newQty * originalRate;

              // Jika newQty ≤ 0, tetapkan qty dan amount menjadi 0
              if (newQty <= 0) {
                newQty = 0;
                newAmount = 0;
                itemMap['status'] = 'Return';
              } else {
                itemMap['status'] = '';
              }

              // Update qty dan amount
              itemMap['qty'] = newQty;
              itemMap['amount'] = newAmount;
              itemMap['price_list_rate'] = newAmount;
              itemMap['rate'] = newAmount;
            }

            // Tambahkan item ke daftar yang sudah diedit
            editedItems.add(itemMap);
          }

          log(jsonEncode(editedItems));

          return editedItems;
        } catch (e) {
          log('Error processing items with return data: $e');
          rethrow;
        }
      }

      final response =
          await sales_data.getSalesInvoice(1, 0, invoiceId, '', '', '', '', '');

      if (response == null) {
        throw Exception('Response is null. Failed to fetch sales data.');
      }

      if (response.containsKey('data') && response['data'] is List<dynamic>) {
        final datasJson = response['data'];
        final invoice = datasJson.first;
        if (invoice['custom_ui_items'] == null ||
            invoice['custom_ui_items'].isEmpty) {
          return 'failed';
        }

        final name = datasJson.first['name'];

        final List<dynamic> rawItems = jsonDecode(invoice['custom_ui_items']);

        final List<Map<String, dynamic>> items =
            await processItemsWithReturnData(name, rawItems);

        final List<dynamic> payments =
            jsonDecode(invoice['custom_ui_mode_of_payment']);

        // Hitung subtotal dan total diskon
        double subtotal = 0;
        double totalDiscount = 0;
        for (var item in items) {
          subtotal += (item["price_list_rate"] * item["qty"]);
          totalDiscount += item["discount_amount"] * item["qty"];
        }

        // Format currency helper function
        String formatRupiah(dynamic value) {
          if (value is String) {
            value = double.tryParse(value) ?? 0;
          }
          NumberFormat currencyFormatter = NumberFormat.currency(
            locale: 'id',
            symbol: '',
            decimalDigits: 0,
          );
          return currencyFormatter.format(value);
        }

        List<Map<String, dynamic>> payload = [];

        bool _discountPerItem = false;
        final prefs = await SharedPreferences.getInstance();
        _discountPerItem = prefs.getBool('discount_per_item') ?? false;

        // Tambahkan label dan informasi umum
        payload.addAll([
          {
            "key": "label",
            "text":
                "Jl. Terusan Dieng No.52, Pisang Candi, Kec. Sukun, Kota Malang, Jawa Timur 65146",
            "style": "small",
            "type": "center"
          },
          {
            "key": "label",
            "text": "082335236569",
            "style": "small",
            "type": "center"
          },
          {"key": "line", "type": "blank"},
          if (status.isNotEmpty)
            {
              "key": "label",
              "text": "** $status **",
              "style": "small",
              "type": "center"
            },
          {"key": "line", "type": "blank"},
          {
            "key": "table",
            "text": ["No", invoice["name"]],
            "style": "normal"
          },
          {
            "key": "table",
            "text": [
              "Tgl. Transaksi",
              "${invoice["posting_date"]}, ${invoice["posting_time"].toString().substring(0, 5)}"
            ],
            "style": "normal"
          },
          {
            "key": "table",
            "text": ["Customer", invoice["customer_name"]],
            "style": "normal"
          },
          // {
          //   "key": "table",
          //   "text": ["Kasir", invoice["owner"]],
          //   "style": "normal"
          // },
          {"key": "line", "type": "line"},
        ]);

        // Tambahkan item dengan format baru
        for (var item in items) {
          // Periksa status item dan tambahkan "[Retur]" jika status adalah "Return"
          String itemText = item["item_code"];
          if (item["status"] == "Return") {
            itemText += " [Retur]";
          }

          payload.add({
            "key": "label",
            "text": itemText,
            "style": "small",
            "type": "left"
          });

          if (_discountPerItem) {
            if (item["status"] == "Return") {
              payload.add({
                "key": "table",
                "text": [
                  "${item["qty"]} x Rp ${formatRupiah(item["price_list_rate"])}(- Rp ${formatRupiah(0)})",
                  "Rp ${0}"
                ],
                "style": "normal"
              });
            } else {
              payload.add({
                "key": "table",
                "text": [
                  "${item["qty"]} x Rp ${formatRupiah(item["price_list_rate"])}(- Rp ${formatRupiah(item["discount_amount"])})",
                  "Rp ${formatRupiah((item["price_list_rate"] * item["qty"]) - item["discount_amount"])}"
                ],
                "style": "normal"
              });
            }
          } else {
            payload.add({
              "key": "table",
              "text": [
                "${item["qty"]} x Rp ${formatRupiah(item["price_list_rate"])}",
                "Rp ${formatRupiah(item["price_list_rate"] * item["qty"])}"
              ],
              "style": "normal"
            });
          }
        }

        payload.add({"key": "line", "type": "line"});

        // Tambahkan subtotal dan diskon
        if (!_discountPerItem) {
          payload.add({
            "key": "table",
            "text": ["Subtotal", "Rp ${formatRupiah(subtotal)}"],
            "style": "normal"
          });

          payload.add({
            "key": "table",
            "text": ["Discount", "Rp ${formatRupiah(totalDiscount)}"],
            "style": "normal"
          });

          payload.add({"key": "line", "type": "line"});
        }

        // Tambahkan total akhir
        payload.add({
          "key": "table",
          "text": ["TOTAL", "Rp ${formatRupiah(subtotal - totalDiscount)}"],
          "style": "normal"
        });

        payload.add({"key": "line", "type": "line"});

        // Tambahkan pembayaran
        double totalPayment = 0;
        for (var pay in payments) {
          double paymentAmount =
              pay["amount"] is num ? (pay["amount"] as num).toDouble() : 0.0;

          payload.add({
            "key": "table",
            "text": [
              pay["mode_of_payment"],
              "Rp ${formatRupiah(paymentAmount)}"
            ],
            "style": "normal"
          });

          totalPayment += paymentAmount;
        }

        double grandTotal = subtotal - totalDiscount;
        double change = totalPayment - grandTotal;

        payload.add({
          "key": "table",
          "text": ["Kembalian", "Rp ${formatRupiah(change)}"],
          "style": "normal"
        });

        // Footer
        payload.addAll([
          {"key": "line", "type": "blank"},
          {"key": "line", "type": "blank"},
          {
            "key": "label",
            "text": "Terima Kasih",
            "style": "small",
            "type": "center"
          },
          {"key": "cut"}
        ]);

        log(payload.toString());

        // print logo
        await printLogo(ipAddress: ipAddress, printerName: printerName);

        // Kirim ke printer
        final printPayload = {"data": payload, "printer": "$printerName"};

        final responses = await http.post(
          Uri.parse('http://${ipAddress}:5577/printPos'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(printPayload),
        );
        if (responses.statusCode == 200) {
          log('Print success');
        } else {
          log('Print failed: ${responses.statusCode}');
        }

        log(printPayload.toString());
        return printPayload;
        // return payload;
      } else {
        throw Exception('Invalid response format: ${response.toString()}');
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<dynamic> printLogo(
      {required String ipAddress, required String printerName}) async {
    try {
      final byteData = await rootBundle.load(ConfigService.logo);
      final logoBytes = byteData.buffer.asUint8List();
      final logoBase64 = base64Encode(logoBytes);

      final printPayloadLogo = {
        "data": logoBase64,
        "printer": printerName,
        "usecache": false
      };

      final responseLogo = await http.post(
        Uri.parse('http://${ipAddress}:5577/printPosLogo'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(printPayloadLogo),
      );

      if (responseLogo.statusCode == 200) {
        log('Print success');
      } else {
        log('Print failed: ${responseLogo.statusCode}');
      }

      return printPayloadLogo;
    } catch (e) {
      print(e);
    }
  }
}
