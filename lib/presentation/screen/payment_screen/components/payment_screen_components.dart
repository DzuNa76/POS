// widgets/payment_summary_card.dart
import 'package:flutter/material.dart';
import 'package:pos/data/models/cart_item.dart';

class PaymentSummaryCard extends StatelessWidget {
  final int totalTagihan;
  final int? cashAmount;
  final int kembalian;

  const PaymentSummaryCard({
    required this.totalTagihan,
    this.cashAmount,
    required this.kembalian,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Tagihan:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Rp. $totalTagihan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Total Dibayar:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Rp. ${cashAmount ?? totalTagihan}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Kembalian:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        'Rp. $kembalian',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widgets/order_details_card.dart


class OrderDetailsCard extends StatelessWidget {
  final List<CartItem> orders;

  const OrderDetailsCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pesanan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ...orders.map((order) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${order.itemName}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${order.qty} x Rp. ${order.rate}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Rp. ${order.amount}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${order.itemCode}'),
                              Text('Description: ${order.description}'),
                              if (order.notes != null)
                                Text('Catatan: ${order.notes}'),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widgets/payment_form.dart

class PaymentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? modeOfPayment;
  final int totalTagihan;
  final Function(String?) onPaymentMethodChanged;
  final Function(String) onCashAmountChanged;
  final Function(String) onReferenceNumberChanged;
  final Function(String) onAccountChanged;
  final VoidCallback onProcessPayment;

  const PaymentForm({
    required this.formKey,
    required this.modeOfPayment,
    required this.totalTagihan,
    required this.onPaymentMethodChanged,
    required this.onCashAmountChanged,
    required this.onReferenceNumberChanged,
    required this.onAccountChanged,
    required this.onProcessPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Pembayaran:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Metode Pembayaran'),
                items: ['Cash', 'Credit Card', 'Bank Transfer']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: onPaymentMethodChanged,
                validator: (value) =>
                    value == null ? 'Pilih metode pembayaran' : null,
              ),
              const SizedBox(height: 8),
              if (modeOfPayment == "Cash")
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nominal Cash'),
                  keyboardType: TextInputType.number,
                  onChanged: onCashAmountChanged,
                  validator: (value) {
                    if (modeOfPayment == "Cash" &&
                        (value == null || value.isEmpty)) {
                      return 'Masukkan nominal cash';
                    }
                    if (modeOfPayment == "Cash" &&
                        int.tryParse(value!)! < totalTagihan) {
                      return 'Nominal kurang dari total tagihan';
                    }
                    return null;
                  },
                )
              else if (modeOfPayment != null)
                Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Nomor Referensi'),
                      onChanged: onReferenceNumberChanged,
                      validator: (value) {
                        if (modeOfPayment != "Cash" &&
                            (value == null || value.isEmpty)) {
                          return 'Masukkan nomor referensi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Akun Pembayaran'),
                      onChanged: onAccountChanged,
                      validator: (value) {
                        if (modeOfPayment != "Cash" &&
                            (value == null || value.isEmpty)) {
                          return 'Masukkan akun pembayaran';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          // Validation successful
                        }
                      },
                      child: Text('Perbarui Data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onProcessPayment,
                      child: Text('Proses Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// widgets/receipt_preview.dart


class ReceiptPreview extends StatelessWidget {
  final List<CartItem> orders;
  final int totalTagihan;
  final String customerName;
  final String orderType;
  final String? modeOfPayment;
  final int? cashAmount;
  final String? referenceNumber;
  final int kembalian;

  const ReceiptPreview({
    required this.orders,
    required this.totalTagihan,
    required this.customerName,
    required this.orderType,
    this.modeOfPayment,
    this.cashAmount,
    this.referenceNumber,
    required this.kembalian,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Title at top
              Text(
                'STRUK PEMBAYARAN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              // 2. Cost center
              Text(
                'Main - M',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              // 3. Address
              Text(
                'Jl. Contoh No. 123, Kota',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              Text(
                'Telp: 021-123456',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              // 4. Print status
              Text(
                'PRINTED',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              // 5. Horizontal separator
              Divider(thickness: 1),
              // 6-8. Two columns with 4 rows
              Container(
                child: Column(
                  children: [
                    // Row 1
                    Row(
                      children: [
                        // Column 1
                        Expanded(
                          flex: 1,
                          child: Text('No:'),
                        ),
                        // Column 2
                        Expanded(
                          flex: 2,
                          child: Text(
                              'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)} - ${DateTime.now().toString().split(' ')[0]} - ${TimeOfDay.now().format(context)}'),
                        ),
                      ],
                    ),
                    // Row 2
                    Row(
                      children: [
                        // Column 1
                        Expanded(
                          flex: 1,
                          child: Text('Status:'),
                        ),
                        // Column 2
                        Expanded(
                          flex: 2,
                          child: Text(orderType),
                        ),
                      ],
                    ),
                    // Row 3
                    Row(
                      children: [
                        // Column 1
                        Expanded(
                          flex: 1,
                          child: Text('Customer:'),
                        ),
                        // Column 2
                        Expanded(
                          flex: 2,
                          child: Text(customerName),
                        ),
                      ],
                    ),
                    // Row 4
                    Row(
                      children: [
                        // Column 1
                        Expanded(
                          flex: 1,
                          child: Text('Kasir:'),
                        ),
                        // Column 2
                        Expanded(
                          flex: 2,
                          child: Text('Administrator'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 9. Horizontal separator after the columns
              Divider(thickness: 1),
              // 10-11. Per-item display in receipt
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name - size
                        Text(
                          '${order.itemName} - ${order.uom ?? "Regular"}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Qty x Price and Total in one row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${order.qty} x Rp.${order.rate}'),
                            Text('Rp.${order.amount}'),
                          ],
                        ),
                        // Add-ons if any
                        if (order.notes != null)
                          Text(
                            '${order.notes}',
                            style: TextStyle(
                                fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  )),
              // 12. Horizontal separator after items
              Divider(thickness: 1),
              // 13. Bold total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Rp.$totalTagihan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              // 14. Horizontal separator
              Divider(thickness: 1),
              // 15. Payment method and amount/reference
              if (modeOfPayment != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$modeOfPayment:'),
                    Text(modeOfPayment == "Cash"
                        ? 'Rp.$cashAmount'
                        : '${referenceNumber ?? ""}'),
                  ],
                ),
              // 16. Change amount
              if (modeOfPayment == "Cash" && cashAmount != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Change:'),
                    Text('Rp.$kembalian'),
                  ],
                ),
              const SizedBox(height: 16),
              Text(
                'Terima Kasih',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'Silahkan datang kembali',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}