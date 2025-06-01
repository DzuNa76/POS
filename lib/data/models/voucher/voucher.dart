class VoucherModel {
  final String? name;
  final String? owner;
  final String? creation;
  final String? modified;
  final String? modifiedBy;
  final int? docstatus;
  final int? idx;
  final String? voucherName;
  final String? voucherImage;
  final String? description;
  final int? welcomeVoucher;
  final int? thirdPartyVoucher;
  final int? giftCardVoucher;
  final int? redeemableVoucher;
  final String? namingSeries;
  final String? validFrom;
  final String? validUpto;
  final String? validHourFrom;
  final String? validHourTo;
  final int? validForAllPos;
  final String? discountType;
  final String? discountAmountType;
  final String? applyDiscountOn;
  final int? isSingle;
  final int? discountPercentage;
  final double? maxDiscountAmount;
  final double? discountAmount;
  final int? qtyDiscounted;
  final int? discountAllItems;
  final double? minimumSpending;
  final int? qtyRequired;
  final int? requireAllItems;
  final String? requiredItemType;
  final int? haveQuota;
  final int? quota;
  final int? usedQuota;
  final String? amendedFrom;
  final String? customUiValidPos;
  final String? customUiDiscountedItems;
  final String? customUiRequiredItems;

  VoucherModel({
    this.name,
    this.owner,
    this.creation,
    this.modified,
    this.modifiedBy,
    this.docstatus,
    this.idx,
    this.voucherName,
    this.voucherImage,
    this.description,
    this.welcomeVoucher,
    this.thirdPartyVoucher,
    this.giftCardVoucher,
    this.redeemableVoucher,
    this.namingSeries,
    this.validFrom,
    this.validUpto,
    this.validHourFrom,
    this.validHourTo,
    this.validForAllPos,
    this.discountType,
    this.discountAmountType,
    this.applyDiscountOn,
    this.isSingle,
    this.discountPercentage,
    this.maxDiscountAmount,
    this.discountAmount,
    this.qtyDiscounted,
    this.discountAllItems,
    this.minimumSpending,
    this.qtyRequired,
    this.requireAllItems,
    this.requiredItemType,
    this.haveQuota,
    this.quota,
    this.usedQuota,
    this.amendedFrom,
    this.customUiValidPos,
    this.customUiDiscountedItems,
    this.customUiRequiredItems,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      creation: json['creation'] ?? '',
      modified: json['modified'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      idx: json['idx'] ?? 0,
      voucherName: json['voucher_name'] ?? '',
      voucherImage: json['voucher_image'] ?? '',
      description: json['description'] ?? '',
      welcomeVoucher: json['welcome_voucher'] ?? 0,
      thirdPartyVoucher: json['third_party_voucher'] ?? 0,
      giftCardVoucher: json['gift_card_voucher'] ?? 0,
      redeemableVoucher: json['redeemable_voucher'] ?? 0,
      namingSeries: json['naming_series'] ?? '',
      validFrom: json['valid_from'] ?? '',
      validUpto: json['valid_upto'],
      validHourFrom: json['valid_hour_from'] ?? '',
      validHourTo: json['valid_hour_to'] ?? '',
      validForAllPos: json['valid_for_all_pos'] ?? 0,
      discountType: json['discount_type'] ?? '',
      discountAmountType: json['discount_amount_type'] ?? '',
      applyDiscountOn: json['apply_discount_on'] ?? '',
      isSingle: json['is_single'] ?? 1,
      discountPercentage: json['discount_percentage'] ?? 0,
      maxDiscountAmount: json['max_discount_amount']?.toDouble() ?? 0.0,
      discountAmount: json['discount_amount']?.toDouble() ?? 0.0,
      qtyDiscounted: json['qty_discounted'] ?? 0,
      discountAllItems: json['discount_all_items'] ?? 0,
      minimumSpending: json['minimum_spending']?.toDouble() ?? 0.0,
      qtyRequired: json['qty_required'] ?? 0,
      requireAllItems: json['require_all_items'] ?? 0,
      requiredItemType: json['required_item_type'] ?? '',
      haveQuota: json['have_quota'] ?? 0,
      quota: json['quota'] ?? 0,
      usedQuota: json['used_quota'] ?? 0,
      amendedFrom: json['amended_from'] ?? '',
      customUiValidPos: json['custom_ui_valid_pos'] ?? '',
      customUiDiscountedItems: json['custom_ui_discounted_items'] ?? '',
      customUiRequiredItems: json['custom_ui_required_items'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'creation': creation,
      'modified': modified,
      'modified_by': modifiedBy,
      'docstatus': docstatus,
      'idx': idx,
      'voucher_name': voucherName,
      'voucher_image': voucherImage,
      'description': description,
      'welcome_voucher': welcomeVoucher,
      'third_party_voucher': thirdPartyVoucher,
      'gift_card_voucher': giftCardVoucher,
      'redeemable_voucher': redeemableVoucher,
      'naming_series': namingSeries,
      'valid_from': validFrom,
      'valid_upto': validUpto,
      'valid_hour_from': validHourFrom,
      'valid_hour_to': validHourTo,
      'valid_for_all_pos': validForAllPos,
      'discount_type': discountType,
      'discount_amount_type': discountAmountType,
      'apply_discount_on': applyDiscountOn,
      'is_single': isSingle,
      'discount_percentage': discountPercentage,
      'max_discount_amount': maxDiscountAmount,
      'discount_amount': discountAmount,
      'qty_discounted': qtyDiscounted,
      'discount_all_items': discountAllItems,
      'minimum_spending': minimumSpending,
      'qty_required': qtyRequired,
      'require_all_items': requireAllItems,
      'required_item_type': requiredItemType,
      'have_quota': haveQuota,
      'quota': quota,
      'used_quota': usedQuota,
      'amended_from': amendedFrom,
      'custom_ui_valid_pos': customUiValidPos,
      'custom_ui_discounted_items': customUiDiscountedItems,
      'custom_ui_required_items': customUiRequiredItems,
    };
  }
}

// Model untuk respons API yang berisi daftar voucher
class VoucherResponse {
  final List<VoucherModel> data;

  VoucherResponse({required this.data});

  factory VoucherResponse.fromJson(Map<String, dynamic> json) {
    return VoucherResponse(
      data: (json['data'] as List)
          .map((item) => VoucherModel.fromJson(item))
          .toList(),
    );
  }
}
