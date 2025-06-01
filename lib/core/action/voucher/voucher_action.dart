import 'dart:developer';

import 'package:pos/data/api/voucher.dart' as voucher;
import 'package:pos/data/models/voucher/voucher.dart';

class VoucherAction {
  static Future<List<VoucherModel>> getVouchers(
      int limit, int start, String filter) async {
    try {
      final Map<String, dynamic>? response =
          await voucher.getVoucher(limit, start, filter);
      if (response != null) {
        final voucherResponse = VoucherResponse.fromJson(response);
        return voucherResponse.data;
      } else {
        return [];
      }
    } catch (e) {
      log('Error fetching vouchers: $e');
      return [];
    }
  }
}
