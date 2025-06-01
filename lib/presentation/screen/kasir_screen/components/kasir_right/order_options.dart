import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/providers/app_state.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/notification.dart';

// Widget untuk menampilkan opsi pesanan dan tombol reset cart
class OrderOptionsWidget extends StatelessWidget {
  final bool useDropdown;
  final List<String> item;
  final String dropDownTitle;
  final ValueChanged<String>? onChanged;

  const OrderOptionsWidget({
    Key? key,
    this.useDropdown = true,
    this.item = const ['OFFLINE', 'ONLINE'],
    this.dropDownTitle = 'Pilih Jenis Pesanan',
    this.onChanged,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTablet = MediaQuery.of(context).size.width <= 1400;

    return isTablet
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              useDropdown
                  ? Text(
                      dropDownTitle,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    )
                  : Container(),
              SizedBox(height: 8),
              useDropdown
                  // ? DropdownButtonFormField<String>(
                  //     value: item[0],
                  //     items: item
                  //         .map((item) => DropdownMenuItem(
                  //               value: item,
                  //               child: Text(item),
                  //             ))
                  //         .toList(),
                  //     onChanged: (value) {
                  //       if (value != null) {
                  //         print(value);
                  //         onChanged?.call(value); // Kirim ke parent
                  //       }
                  //     },
                  //     decoration: const InputDecoration(
                  //       border: OutlineInputBorder(),
                  //     ),
                  //   )
                  ? CustomDropdown<String>(
                      closedHeaderPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      hintText: "Pilih Jalur Penjualan",
                      items: item,
                      initialItem: item[0],
                      decoration: CustomDropdownDecoration(
                          closedBorder: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                            top: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                            left: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                            right: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          closedFillColor: Colors.grey.shade100),
                      onChanged: (value) {
                        if (value != null) {
                          print(value);
                          onChanged?.call(value); // Kirim ke parent
                        }
                      },
                    )
                  : Container(),
              useDropdown ? SizedBox(width: 8) : Container(),
              SizedBox(height: 16),
              // ElevatedButton(
              //   onPressed: () {
              //     showCustomPopup(
              //       context: context,
              //       title: "Konfirmasi",
              //       message: "Apakah anda yakin ingin menghapus?",
              //       confirmText: "OK",
              //       cancelText: "Batal",
              //       icon: Icons.help_outline,
              //       iconColor: Colors.red,
              //       onConfirm: () {
              //         final cartProvider =
              //             Provider.of<CartProvider>(context, listen: false);
              //         final customerProvider =
              //             Provider.of<CustomerProvider>(context, listen: false);

              //         customerProvider.deleteCustomer();
              //         cartProvider.loadPesanan().then((test) {
              //           for (var a in test) {
              //             cartProvider.deletePesananById(a['invoiceNumber']);
              //           }
              //         });

              //         context.read<CartProvider>().clearCart();
              //         Navigator.of(context).pushReplacement(
              //           PageRouteBuilder(
              //             pageBuilder:
              //                 (context, animation, secondaryAnimation) =>
              //                     KasirScreenDesktop(),
              //             transitionDuration: Duration.zero,
              //             reverseTransitionDuration: Duration.zero,
              //           ),
              //         );
              //       },
              //     );
              //   },
              //   style: ElevatedButton.styleFrom(
              //     padding: EdgeInsets.symmetric(vertical: 20),
              //     backgroundColor: Color(0xFF533F77),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text('Reset Cart', style: TextStyle(fontSize: 14)),
              //       SizedBox(width: 8),
              //       Icon(Icons.delete, color: Colors.white),
              //     ],
              //   ),
              // ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              useDropdown
                  ? Text(
                      dropDownTitle,
                      style: TextStyle(fontSize: 14, color: Color(0xFF533F77)),
                    )
                  : Container(),
              SizedBox(height: 16),
              useDropdown ? SizedBox(width: 8) : Container(),
              useDropdown
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: item[0],
                        items: item
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            appState.setOrderType(value);
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                  : Container(),
              useDropdown ? SizedBox(width: 8) : Container(),
              // Divider(color: const Color.fromARGB(255, 192, 191, 191)),
              SizedBox(height: 5),
            ],
          );
  }
}
