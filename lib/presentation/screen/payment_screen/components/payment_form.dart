import 'package:flutter/material.dart';

class PaymentForm extends StatelessWidget {
  final String paymentMethod;
  final ValueChanged<String?> onPaymentMethodChanged;
  final TextEditingController inputController;
  final ValueChanged<String> onInputChanged;
  final int totalTagihan;
  final GlobalKey<FormState> formKey;

  const PaymentForm({
    Key? key,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.inputController,
    required this.onInputChanged,
    required this.totalTagihan,
    required this.formKey,
  }) : super(key: key);

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
              // Payment method dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                value: paymentMethod,
                items: const [
                  DropdownMenuItem(
                    value: 'Tunai',
                    child: Text('Tunai'),
                  ),
                  DropdownMenuItem(
                    value: 'Debit',
                    child: Text('Debit'),
                  ),
                  DropdownMenuItem(
                    value: 'QRIS',
                    child: Text('QRIS'),
                  ),
                ],
                onChanged: onPaymentMethodChanged,
                validator: (value) => value == null ? 'Pilih metode pembayaran' : null,
              ),
              const SizedBox(height: 16),

              // Conditional input based on payment method
              if (paymentMethod == 'Tunai') ...[
                TextFormField(
                  controller: inputController,
                  decoration: InputDecoration(
                    labelText: 'Nominal Pembayaran',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: onInputChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nominal pembayaran';
                    }
                    final amount = int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
                    if (amount < totalTagihan) {
                      return 'Nominal kurang dari total tagihan';
                    }
                    return null;
                  },
                ),
              ] else if (paymentMethod != null) ...[
                TextFormField(
                  controller: inputController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Referensi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: 'Masukkan kode referensi ${paymentMethod == 'Debit' ? 'kartu' : 'QRIS'}',
                  ),
                  onChanged: onInputChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nomor referensi';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}