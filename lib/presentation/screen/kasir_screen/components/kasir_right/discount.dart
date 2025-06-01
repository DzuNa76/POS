import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/voucher_provider.dart';

class DiscountWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, voucherProvider, child) {
        final selectedVoucher = voucherProvider.selectedVoucher;

        if (selectedVoucher == null) {
          return SizedBox(); // Tidak tampil jika tidak ada voucher
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.black, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Voucher',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        voucherProvider
                            .clearVoucher(); // Hapus voucher yang dipilih
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.discount, color: Colors.green, size: 32.0),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedVoucher.name, // Nama voucher
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            selectedVoucher.isGlobal
                                ? 'Diskon ${selectedVoucher.discount}%' // Deskripsi global
                                : 'Diskon Rp ${selectedVoucher.discount} untuk item tertentu', // Deskripsi item
                            style: TextStyle(fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
