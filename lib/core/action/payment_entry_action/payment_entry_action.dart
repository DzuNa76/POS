import 'package:pos/core/utils/config.dart';
import 'package:pos/data/api/payment_entry.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';

class PaymentEntryAction {
  Future<Map<String, dynamic>> processMultiplePayments({
    required List<SalesInvoice> salesInvoices,
    required String modeOfPayment,
  }) async {
    try {
      // Early validation
      if (salesInvoices.isEmpty) {
        throw Exception('No sales invoices provided for payment');
      }

      final String customer = salesInvoices[0].customer;
      double totalAmount = 0;
      final List<PaymentReference> references = [];

      for (final invoice in salesInvoices) {
        // Verify customer and calculate amount in the same loop
        if (invoice.customer != customer) {
          throw Exception('All invoices must be from the same customer');
        }

        final double outstandingAmount = invoice.outstandingAmount ?? 0;
        if (outstandingAmount > 0) {
          totalAmount += outstandingAmount;
          references.add(PaymentReference(
            salesInvoice: invoice.name,
            amount: outstandingAmount,
          ));
        }
      }

      if (totalAmount <= 0) {
        throw Exception('Total payment amount must be greater than 0');
      }

      // Create payment entry
      final result = await createPaymentEntry(
        paymentType: "Receive",
        modeOfPayment: modeOfPayment,
        party: customer,
        partyType: "Customer",
        paidAmount: totalAmount,
        references: references,
        kasbonAccount: ConfigService.kasbonAccount,
      );

      return {
        'success': true,
        'message': 'Payment processed successfully',
        'data': result,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }
}
