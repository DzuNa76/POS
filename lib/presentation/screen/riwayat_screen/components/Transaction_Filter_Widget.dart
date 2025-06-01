import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterWidget extends StatelessWidget {
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodChanged;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final Function(DateTime?, DateTime?) onDateRangeSelected;

  const TransactionFilterWidget({
    Key? key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  final List<String> _paymentMethods = const [
    'Semua',
    'Tunai',
    'Debit',
    'QRIS'
  ];

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
    );

    if (picked != null) {
      onDateRangeSelected(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter tanggal sebagai TextButton di bagian kiri
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => _selectDateRange(context),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  selectedStartDate != null && selectedEndDate != null
                      ? "${DateFormat('dd MMM yyyy').format(selectedStartDate!)} - ${DateFormat('dd MMM yyyy').format(selectedEndDate!)}"
                      : "Pilih Rentang Tanggal",
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (selectedStartDate != null && selectedEndDate != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onDateRangeSelected(null, null),
                  tooltip: 'Hapus filter tanggal',
                ),
            ],
          ),
        ),

        // Filter pembayaran
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _paymentMethods.map((method) {
                final isSelected = selectedPaymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onPaymentMethodChanged(method);
                      }
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}