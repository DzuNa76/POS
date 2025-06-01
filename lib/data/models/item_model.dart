class Item {
  final String name;
  final String? owner;
  final DateTime? creation;
  final DateTime? modified;
  final String? modifiedBy;
  final int? docstatus;
  final int? idx;
  final String? namingSeries;
  final String? itemCode;
  final String? itemName;
  final String? itemGroup;
  final String? stockUom;
  final int? disabled;
  final int? allowAlternativeItem;
  final int? isStockItem;
  final int? hasVariants;
  final double? openingStock;
  final double? valuationRate;
  final double? standardRate;
  final int? isFixedAsset;
  final int? autoCreateAssets;
  final int? isGroupedAsset;
  final String? assetCategory;
  final String? assetNamingSeries;
  final double? overDeliveryReceiptAllowance;
  final double? overBillingAllowance;
  final String? image;
  final String? description;
  final String? brand;
  final int? shelfLifeInDays;
  final DateTime? endOfLife;
  final String? defaultMaterialRequestType;
  final String? valuationMethod;
  final int? warrantyPeriod;
  final double? weightPerUnit;
  final String? weightUom;
  final int? allowNegativeStock;
  final int? hasBatchNo;
  final int? createNewBatch;
  final String? batchNumberSeries;
  final int? hasExpiryDate;
  final int? retainSample;
  final double? sampleQuantity;
  final int? hasSerialNo;
  final String? serialNoSeries;
  final String? variantOf;
  final String? variantBasedOn;
  final int? enableDeferredExpense;
  final int? noOfMonthsExp;
  final int? enableDeferredRevenue;
  final int? noOfMonths;
  final String? purchaseUom;
  final double? minOrderQty;
  final double? safetyStock;
  final int? isPurchaseItem;
  final int? leadTimeDays;
  final double? lastPurchaseRate;
  final int? isCustomerProvidedItem;
  final String? customer;
  final int? deliveredBySupplier;
  final String? countryOfOrigin;
  final String? customsTariffNumber;
  final String? salesUom;
  final int? grantCommission;
  final int? isSalesItem;
  final double? maxDiscount;
  final int? inspectionRequiredBeforePurchase;
  final String? qualityInspectionTemplate;
  final int? inspectionRequiredBeforeDelivery;
  final int? includeItemInManufacturing;
  final int? isSubContractedItem;
  final String? defaultBom;
  final String? customerCode;
  final String? defaultItemManufacturer;
  final String? defaultManufacturerPartNo;
  final double? totalProjectedQty;
  final double? stockQty;

  Item(
      {required this.name,
      this.owner,
      this.creation,
      this.modified,
      this.modifiedBy,
      this.docstatus,
      this.idx,
      this.namingSeries,
      this.itemCode,
      this.itemName,
      this.itemGroup,
      this.stockUom,
      this.disabled,
      this.allowAlternativeItem,
      this.isStockItem,
      this.hasVariants,
      this.openingStock,
      this.valuationRate,
      this.standardRate,
      this.isFixedAsset,
      this.autoCreateAssets,
      this.isGroupedAsset,
      this.assetCategory,
      this.assetNamingSeries,
      this.overDeliveryReceiptAllowance,
      this.overBillingAllowance,
      this.image,
      this.description,
      this.brand,
      this.shelfLifeInDays,
      this.endOfLife,
      this.defaultMaterialRequestType,
      this.valuationMethod,
      this.warrantyPeriod,
      this.weightPerUnit,
      this.weightUom,
      this.allowNegativeStock,
      this.hasBatchNo,
      this.createNewBatch,
      this.batchNumberSeries,
      this.hasExpiryDate,
      this.retainSample,
      this.sampleQuantity,
      this.hasSerialNo,
      this.serialNoSeries,
      this.variantOf,
      this.variantBasedOn,
      this.enableDeferredExpense,
      this.noOfMonthsExp,
      this.enableDeferredRevenue,
      this.noOfMonths,
      this.purchaseUom,
      this.minOrderQty,
      this.safetyStock,
      this.isPurchaseItem,
      this.leadTimeDays,
      this.lastPurchaseRate,
      this.isCustomerProvidedItem,
      this.customer,
      this.deliveredBySupplier,
      this.countryOfOrigin,
      this.customsTariffNumber,
      this.salesUom,
      this.grantCommission,
      this.isSalesItem,
      this.maxDiscount,
      this.inspectionRequiredBeforePurchase,
      this.qualityInspectionTemplate,
      this.inspectionRequiredBeforeDelivery,
      this.includeItemInManufacturing,
      this.isSubContractedItem,
      this.defaultBom,
      this.customerCode,
      this.defaultItemManufacturer,
      this.defaultManufacturerPartNo,
      this.totalProjectedQty,
      this.stockQty});

  // Factory untuk membuat Item dari JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] ?? '',
      idx: json['idx'],
      itemCode: json['item_code'],
      itemName: json['item_name'],
      itemGroup: json['item_group'],
      stockUom: json['stock_uom'],
      disabled: json['disabled'],
      isStockItem: json['is_stock_item'],
      standardRate: (json['standard_rate'] as num?)?.toDouble(),
      image: json['image'],
      description: json['description'],
      stockQty: json['stock_qty'] != null
          ? (json['stock_qty'] as num).toDouble()
          : null,
    );
  }

  // Konversi Item ke Map<String, dynamic> untuk disimpan di database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'docstatus': docstatus,
      'idx': idx,
      'item_code': itemCode,
      'item_name': itemName,
      'item_group': itemGroup,
      'stock_uom': stockUom,
      'disabled': disabled,
      'is_stock_item': isStockItem,
      'standard_rate': standardRate,
      'image': image,
      'description': description,
      'stock_qty': stockQty
    };
  }

  // Factory untuk membuat Item dari Map<String, dynamic> dari database
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
        name: map['name'] ?? '',
        idx: map['idx'],
        itemCode: map['item_code'],
        itemName: map['item_name'],
        itemGroup: map['item_group'],
        stockUom: map['stock_uom'],
        disabled: map['disabled'],
        isStockItem: map['is_stock_item'],
        standardRate: (map['standard_rate'] as num?)?.toDouble(),
        image: map['image'],
        description: map['description'],
        stockQty: map['stock_qty'] != null
            ? (map['stock_qty'] as num).toDouble()
            : null);
  }
}
