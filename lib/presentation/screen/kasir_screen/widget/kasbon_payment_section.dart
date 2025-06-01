import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:pos/core/theme/app_colors.dart';

class PaymentSection extends StatelessWidget {
  final double totalAmount;
  final double kembalian;
  final String selectedPaymentMode;
  final List<String> paymentModes;
  final TextEditingController paymentController;
  final TextEditingController referenceController;
  final Function(String?) onPaymentModeChanged;
  final VoidCallback onProcessPayment;
  final bool canProcessPayment;
  final NumberFormat formatter;

  const PaymentSection({
    Key? key,
    required this.totalAmount,
    required this.kembalian,
    required this.selectedPaymentMode,
    required this.paymentModes,
    required this.paymentController,
    required this.referenceController,
    required this.onPaymentModeChanged,
    required this.onProcessPayment,
    required this.canProcessPayment,
    required this.formatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountSection(),
          const SizedBox(height: 24),
          _buildPaymentControls(),
          const SizedBox(height: 24),
          _buildProcessButton(),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Row(
      children: [
        Expanded(
          child: _buildAmountDisplay('Total Amount', totalAmount),
        ),
        Container(
          height: 40,
          width: 1,
          color: AppColors.border,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildAmountDisplay('Change', kembalian, isChange: true),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay(String label, double amount,
      {bool isChange = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isChange
                ? kembalian >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600
                : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentControls() {
    return Column(
      children: [
        CustomDropdown<String>.search(
          searchHintText: "Cari Metode Pembayaran",
          closedHeaderPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          hintText: "Pilih Metode Pembayaran",
          items: paymentModes,
          initialItem: selectedPaymentMode,
          onChanged: onPaymentModeChanged,
        ),
        const SizedBox(height: 16),
        if (selectedPaymentMode != 'TUNAI') ...[
          _buildTextField(
            controller: referenceController,
            hintText: 'Reference Number',
          ),
          const SizedBox(height: 16),
        ],
        if (selectedPaymentMode == 'TUNAI')
          _buildTextField(
            controller: paymentController,
            hintText: 'Masukan Nominal Pembayaran',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            onChanged: (value) {
              if (value.isNotEmpty) {
                String formattedValue = formatter
                    .format(int.parse(value.replaceAll(RegExp(r'\D'), '')));
                paymentController.value = TextEditingValue(
                  text: formattedValue,
                  selection:
                      TextSelection.collapsed(offset: formattedValue.length),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canProcessPayment ? onProcessPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Process Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
