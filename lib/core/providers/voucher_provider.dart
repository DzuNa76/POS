import 'package:flutter/material.dart';
import 'package:pos/data/models/voucher.dart';

class VoucherProvider with ChangeNotifier {
  List<Voucher> availableVouchers = [
    Voucher(id: '1', name: 'Diskon 10%', discount: 10, isGlobal: true),
    Voucher(id: '2', name: 'Diskon 5000 (Item A)', discount: 5000, isGlobal: false, applicableItemId: 'itemA'),
  ];

  Voucher? _selectedVoucher;

  Voucher? get selectedVoucher => _selectedVoucher;

  void selectVoucher(Voucher voucher) {
    _selectedVoucher = voucher;
    notifyListeners();
  }

  void clearVoucher() {
    _selectedVoucher = null;
    notifyListeners();
  }
}
