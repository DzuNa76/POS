// import 'package:flutter/material.dart';
// import 'package:pos/data/models/models.dart';
// import 'package:pos/presentation/screen/screen.dart';

// class CheckoutScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> orders; // Data pesanan yang diterima
//   const CheckoutScreen({super.key, required this.orders});

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   late List<Map<String, dynamic>> orders;

//   @override
//   void initState() {
//     super.initState();
//     orders = widget.orders; // Inisialisasi data pesanan
//   }

//   // Fungsi untuk menghitung total harga
//   int get totalPrice =>
//       orders.fold(0, (sum, order) => sum + order['totalPrice'] as int);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Checkout'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Input Nama Customer dengan Ikon Hapus
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: Container(
//                     color: Colors.blue
//                         .withOpacity(0.2), // Background untuk input section
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           color: Colors.green
//                               .withOpacity(0.2), // Background untuk label
//                           child: const Text(
//                             'Nama Customer',
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Container(
//                           color: Colors.orange
//                               .withOpacity(0.2), // Background untuk TextField
//                           child: TextField(
//                             decoration: InputDecoration(
//                               hintText: 'Masukkan nama customer',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8.0),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),

//                 // Kolom untuk ikon tambah customer dan hapus pesanan
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       color: Colors.yellow.withOpacity(
//                           0.2), // Background untuk ikon tambah customer
//                       child: IconButton(
//                         onPressed: () {
//                           // Logika untuk menambahkan customer
//                         },
//                         icon: const Icon(Icons.person_add,
//                             color: Colors.green, size: 28),
//                         tooltip: "Tambah customer",
//                       ),
//                     ),
//                     const SizedBox(height: 8), // Jarak antar ikon
//                     Container(
//                       color: Colors.purple.withOpacity(
//                           0.2), // Background untuk ikon hapus pesanan
//                       child: IconButton(
//                         onPressed: () {
//                           setState(() {
//                             orders.clear(); // Menghapus seluruh pesanan
//                           });
//                         },
//                         icon: const Icon(Icons.delete,
//                             color: Colors.red, size: 28),
//                         tooltip: "Hapus semua pesanan",
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // Detail Pesanan
//             Expanded(
//               child: orders.isEmpty
//                   ? const Center(
//                       child: Text(
//                         "Tidak ada pesanan",
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: orders.length,
//                       itemBuilder: (context, index) {
//                         final order = orders[index];
//                         return Card(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16.0),
//                           ),
//                           margin: const EdgeInsets.only(bottom: 16.0),
//                           child: Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // Nama Produk, Jumlah, dan Harga
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       '${order['name']} x${order['quantity']}',
//                                       style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     Text(
//                                       'Rp${order['totalPrice']}',
//                                       style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),

//                                 // Opsi
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 4.0),
//                                   child: Text(
//                                     'Opsi: ${order['options'] ?? '-'}',
//                                     style: const TextStyle(
//                                         fontSize: 14, color: Colors.black87),
//                                   ),
//                                 ),

//                                 // Preferensi
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 4.0),
//                                   child: Text(
//                                     'Preferensi: ${order['preferences'] ?? '-'}',
//                                     style: const TextStyle(
//                                         fontSize: 14, color: Colors.black87),
//                                   ),
//                                 ),

//                                 // Add-ons
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 4.0),
//                                   child: Text(
//                                     'Add-ons: ${(order['addons'] != null && order['addons'].isNotEmpty) ? order['addons'].join(", ") : 'Tidak ada add-ons'}',
//                                     style: const TextStyle(
//                                         fontSize: 14, color: Colors.black87),
//                                   ),
//                                 ),

//                                 const SizedBox(height: 8),

//                                 // Quantity Selector dan Tombol Edit
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     // Tombol Edit (Sebelah kiri)
//                                     ElevatedButton(
//                                       onPressed: () {
//                                         print(
//                                             "DEBUG: order['options'] = ${order['options']} (${order['options'].runtimeType})");
//                                         print(
//                                             "DEBUG: order['preferences'] = ${order['preferences']} (${order['preferences'].runtimeType})");
//                                         print(
//                                             "DEBUG: order['addons'] = ${order['addons']} (${order['addons'].runtimeType})");

//                                         final product = ProductDetailModel(
//                                           id: order['id'] ?? '', // Tambahkan ID
//                                           name: order['name'] ??
//                                               'Nama tidak tersedia',
//                                           description: 'Deskripsi produk',
//                                           price:
//                                               'Rp${order['unitPrice'] ?? '0'}',

//                                           // Konversi ke List<String> dengan validasi tambahan
//                                           options: (order['options'] is List)
//                                               ? List<String>.from(
//                                                   order['options'])
//                                               : (order['options'] is String)
//                                                   ? [order['options']]
//                                                   : [],

//                                           preferences: (order['preferences']
//                                                   is List)
//                                               ? List<String>.from(
//                                                   order['preferences'])
//                                               : (order['preferences'] is String)
//                                                   ? [order['preferences']]
//                                                   : [],

//                                           // Konversi addons dengan validasi tambahan
//                                           addons: (order['addons'] is List)
//                                               ? (order['addons'] as List<
//                                                       Map<String, dynamic>>)
//                                                   .map((addon) => Addon(
//                                                         id: addon['id'] ?? '',
//                                                         name:
//                                                             addon['name'] ?? '',
//                                                         price: addon['price']
//                                                                 is int
//                                                             ? addon['price']
//                                                             : int.tryParse(addon[
//                                                                         'price'] ??
//                                                                     '0') ??
//                                                                 0,
//                                                       ))
//                                                   .toList()
//                                               : [],
//                                         );

//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 ProductDetailScreen(
//                                                     product: product),
//                                           ),
//                                         );
//                                       },
//                                       child: const Text('Edit'),
//                                     ),

//                                     // Quantity Selector (Sebelah kanan)
//                                     Row(
//                                       children: [
//                                         IconButton(
//                                           onPressed: () {
//                                             setState(() {
//                                               if (order['quantity'] > 1) {
//                                                 order['quantity']--;
//                                                 order['totalPrice'] -=
//                                                     order['unitPrice'];
//                                               }
//                                             });
//                                           },
//                                           icon: const Icon(
//                                               Icons.remove_circle_outline),
//                                         ),
//                                         Text(
//                                           '${order['quantity']}',
//                                           style: const TextStyle(fontSize: 16),
//                                         ),
//                                         IconButton(
//                                           onPressed: () {
//                                             setState(() {
//                                               order['quantity']++;
//                                               order['totalPrice'] +=
//                                                   order['unitPrice'];
//                                             });
//                                           },
//                                           icon: const Icon(
//                                               Icons.add_circle_outline),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),

//             // Tombol Voucher dan Checkout
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       // Logika untuk voucher
//                     },
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16.0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                     ),
//                     child: const Text(
//                       'Voucher',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PaymentScreen(
//                             totalTagihan: totalPrice,
//                             orders:
//                                 orders, // Pastikan orders adalah List<Map<String, dynamic>>
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: const EdgeInsets.symmetric(vertical: 16.0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                     ),
//                     child: const Text(
//                       'Checkout',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
