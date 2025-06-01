// payment_form_screen.dart
import 'package:flutter/material.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/presentation/screen/payment_screen/components/payment_screen_components.dart';

class PaymentFormScreen extends StatelessWidget {
  final int totalTagihan;
  final List<CartItem> orders;
  final GlobalKey<FormState> formKey;
  final String? modeOfPayment;
  final Function(String?) onPaymentMethodChanged;
  final Function(String) onCashAmountChanged;
  final Function(String) onReferenceNumberChanged;
  final Function(String) onAccountChanged;
  final VoidCallback onProcessPayment;
  final int? cashAmount;
  final int kembalian;

  const PaymentFormScreen({
    required this.totalTagihan,
    required this.orders,
    required this.formKey,
    required this.modeOfPayment,
    required this.onPaymentMethodChanged,
    required this.onCashAmountChanged,
    required this.onReferenceNumberChanged,
    required this.onAccountChanged,
    required this.onProcessPayment,
    required this.cashAmount,
    required this.kembalian,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row - Payment Summary and Order Details side by side
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Summary Card
                  Expanded(
                    flex: 1,
                    child: PaymentSummaryCard(
                      totalTagihan: totalTagihan,
                      cashAmount: cashAmount,
                      kembalian: kembalian,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Order Details Card
                  Expanded(
                    flex: 2,
                    child: OrderDetailsCard(orders: orders),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payment Form
            PaymentForm(
              formKey: formKey,
              modeOfPayment: modeOfPayment,
              totalTagihan: totalTagihan,
              onPaymentMethodChanged: onPaymentMethodChanged,
              onCashAmountChanged: onCashAmountChanged,
              onReferenceNumberChanged: onReferenceNumberChanged,
              onAccountChanged: onAccountChanged,
              onProcessPayment: onProcessPayment,
            ),
          ],
        ),
      ),
    );
  }
}
