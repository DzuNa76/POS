// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';
// import 'package:pos/data/database/database_helper.dart';
// import 'package:pos/data/models/transaction_model.dart';
//
// class PaymentScreenMobile extends StatefulWidget {
//   final List<Map<String, dynamic>> orders;
//   final int totalTagihan;
//
//   const PaymentScreenMobile({
//     Key? key,
//     required this.orders,
//     required this.totalTagihan,
//   }) : super(key: key);
//
//   @override
//   State<PaymentScreenMobile> createState() => _PaymentScreenMobileState();
// }
//
// class _PaymentScreenMobileState extends State<PaymentScreenMobile> {
//   bool showReceipt = false;
//   int totalDibayar = 0;
//   String paymentMethod = 'Tunai';
//   String referralCode = '';
//   final String transactionId = const Uuid().v4().substring(0, 8).toUpperCase();
//
//   @override
//   Widget build(BuildContext context) {
//     return showReceipt
//         ? ReceiptView(
//       totalTagihan: widget.totalTagihan,
//       orders: widget.orders,
//       totalDibayar: totalDibayar,
//       paymentMethod: paymentMethod,
//       referralCode: referralCode,
//       transactionId: transactionId,
//       onDone: () async {
//         // Save transaction to database
//         await _saveTransactionToDatabase();
//
//         // Navigate back to cashier screen
//         if (mounted) {
//           Navigator.pushReplacementNamed(context, '/kasir');
//         }
//       },
//     )
//         : PaymentView(
//       totalTagihan: widget.totalTagihan,
//       orders: widget.orders,
//       onCheckout: (totalPaid, method, code) {
//         setState(() {
//           totalDibayar = totalPaid;
//           paymentMethod = method;
//           referralCode = code;
//           showReceipt = true;
//         });
//       },
//     );
//   }
//
//   Future<void> _saveTransactionToDatabase() async {
//     try {
//       // Format current date
//       final now = DateTime.now();
//       final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);
//
//       // Create transaction model
//       final transaction = TransactionModel(
//         transactionId: transactionId,
//         customerName: "Testing", // Get actual customer name if available
//         paymentMethod: paymentMethod,
//         referralCode: referralCode,
//         cashierName: "Kasir 1", // Get actual cashier name if available
//         transactionDate: formattedDate,
//         subtotal: widget.totalTagihan,
//         tax: widget.totalTagihan ~/ 10,
//         total: widget.totalTagihan + (widget.totalTagihan ~/ 10),
//         paid: totalDibayar,
//         change: paymentMethod == 'Tunai' ? totalDibayar - widget.totalTagihan : 0,
//         timestamp: now.millisecondsSinceEpoch,
//         orderItems: [], // Will be added separately
//       );
//
//       // Save transaction to database
//       await DatabaseHelper.instance.insertTransaction(transaction.toMap());
//
//       // Save order items
//       for (var item in widget.orders) {
//         final orderItem = OrderItemModel(
//           transactionId: transactionId,
//           name: item['name'],
//           quantity: item['quantity'],
//           price: item['price'],
//         );
//
//         await DatabaseHelper.instance.insertOrderItem(orderItem.toMap());
//       }
//
//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Transaksi berhasil disimpan')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error menyimpan transaksi: $e')),
//         );
//       }
//     }
//   }
// }
//
// class PaymentView extends StatefulWidget {
//   final int totalTagihan;
//   final List<Map<String, dynamic>> orders;
//   final void Function(int totalPaid, String method, String code) onCheckout;
//
//   const PaymentView({
//     Key? key,
//     required this.totalTagihan,
//     required this.orders,
//     required this.onCheckout,
//   }) : super(key: key);
//
//   @override
//   State<PaymentView> createState() => _PaymentViewState();
// }
//
// class _PaymentViewState extends State<PaymentView> {
//   final TextEditingController inputController = TextEditingController();
//   int totalDibayar = 0;
//   String paymentMethod = 'Tunai';
//   String referralCode = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pembayaran'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Tagihan Card
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Ringkasan Tagihan',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         _buildRow('Total Tagihan', 'Rp ${widget.totalTagihan}'),
//                         _buildRow('Total Dibayar', 'Rp $totalDibayar'),
//                         const Divider(),
//                         _buildRow('Sisa', 'Rp ${widget.totalTagihan - totalDibayar}'),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Rincian Pesanan
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Rincian Pesanan',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ...widget.orders.map((item) => Padding(
//                           padding: const EdgeInsets.only(bottom: 8.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text('${item['quantity']}x ${item['name']}'),
//                               Text('Rp ${item['price'] * item['quantity']}'),
//                             ],
//                           ),
//                         )).toList(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Metode Pembayaran
//                 const Text(
//                   'Metode Pembayaran',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8.0),
//                     ),
//                   ),
//                   value: paymentMethod,
//                   items: const [
//                     DropdownMenuItem(
//                       value: 'Tunai',
//                       child: Text('Tunai'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'Debit',
//                       child: Text('Debit'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'QRIS',
//                       child: Text('QRIS'),
//                     ),
//                   ],
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         paymentMethod = value;
//                         // Reset values when changing payment method
//                         inputController.clear();
//                         totalDibayar = 0;
//                         referralCode = '';
//                       });
//                     }
//                   },
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Conditional input field based on payment method
//                 if (paymentMethod == 'Tunai') ...[
//                   // Jumlah Pembayaran for Tunai
//                   const Text(
//                     'Jumlah Pembayaran',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: inputController,
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                       prefixText: 'Rp ',
//                     ),
//                     keyboardType: TextInputType.number,
//                     onChanged: (value) {
//                       setState(() {
//                         totalDibayar = int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
//                       });
//                     },
//                   ),
//                 ] else ...[
//                   // Kode Referensi for Debit/QRIS
//                   const Text(
//                     'Kode Referensi',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: inputController,
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                       hintText: 'Masukkan kode referensi ${paymentMethod == 'Debit' ? 'kartu' : 'QRIS'}',
//                     ),
//                     onChanged: (value) {
//                       setState(() {
//                         referralCode = value;
//                         // For non-cash payments, set totalDibayar to the full amount
//                         totalDibayar = widget.totalTagihan;
//                       });
//                     },
//                   ),
//                 ],
//                 const SizedBox(height: 24),
//
//                 // Tombol Bayar
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       // Validate input before proceeding
//                       bool isValid = true;
//                       String errorMessage = '';
//
//                       if (paymentMethod == 'Tunai') {
//                         if (totalDibayar < widget.totalTagihan) {
//                           isValid = false;
//                           errorMessage = 'Jumlah pembayaran kurang dari total tagihan';
//                         }
//                       } else {
//                         if (referralCode.isEmpty) {
//                           isValid = false;
//                           errorMessage = 'Kode referensi tidak boleh kosong';
//                         }
//                       }
//
//                       if (isValid) {
//                         widget.onCheckout(totalDibayar, paymentMethod, referralCode);
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text(errorMessage)),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: const Text('Bayar'),
//                   ),
//                 ),
//                 // Add padding at the bottom to accommodate keyboard
//                 const SizedBox(height: 100),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ReceiptView extends StatelessWidget {
//   final int totalTagihan;
//   final List<Map<String, dynamic>> orders;
//   final int totalDibayar;
//   final String paymentMethod;
//   final String referralCode;
//   final String transactionId;
//   final VoidCallback onDone;
//
//   const ReceiptView({
//     Key? key,
//     required this.totalTagihan,
//     required this.orders,
//     required this.totalDibayar,
//     required this.paymentMethod,
//     required this.referralCode,
//     required this.transactionId,
//     required this.onDone,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Struk Pembayaran'),
//         automaticallyImplyLeading: false,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               Expanded(
//                 child: Card(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Center(
//                           child: Text(
//                             'STRUK PEMBAYARAN',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         const Center(
//                           child: Text(
//                             'Nama Toko',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const Center(
//                           child: Text('Alamat Toko'),
//                         ),
//                         const Center(
//                           child: Text('No. Telp Toko'),
//                         ),
//                         const Divider(),
//                         _buildRow('No. Transaksi', transactionId),
//                         _buildRow('Pelanggan', 'Testing'),
//                         _buildRow('Metode Pembayaran', paymentMethod),
//                         if (paymentMethod != 'Tunai' && referralCode.isNotEmpty)
//                           _buildRow('Kode Referensi', referralCode),
//                         _buildRow('Kasir', 'Kasir 1'),
//                         _buildRow('Tanggal', DateFormat('dd MMM yyyy').format(DateTime.now())),
//                         const Divider(),
//                         const Text(
//                           'DETAIL PESANAN',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         ...orders.map((item) => _buildOrderItem(
//                           '${item['name']}',
//                           item['quantity'],
//                           item['price'],
//                         )),
//                         const Divider(),
//                         _buildRow('Subtotal', 'Rp $totalTagihan'),
//                         _buildRow('PPN (10%)', 'Rp ${totalTagihan ~/ 10}'),
//                         _buildRow('Total', 'Rp ${totalTagihan + totalTagihan ~/ 10}', bold: true),
//                         _buildRow('Dibayar', 'Rp $totalDibayar'),
//                         if (paymentMethod == 'Tunai')
//                           _buildRow('Kembalian', 'Rp ${totalDibayar - totalTagihan}'),
//                         const Divider(),
//                         const Center(
//                           child: Text(
//                             'Terima Kasih',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Re-print berhasil!')),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//                   child: const Text('Re-print'),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: onDone,
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
//                   child: const Text('Selesai'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRow(String label, String value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderItem(String name, int quantity, int price) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(name),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('$quantity x Rp $price'),
//               Text('Rp ${quantity * price}'),
//             ],
//           ),
//           const SizedBox(height: 4),
//         ],
//       ),
//     );
//   }
// }