import 'dart:convert';

class ModeOfPayment {
  final String name;
  final String owner;
  final DateTime creation;
  final DateTime modified;
  final String modifiedBy;
  final int docstatus;
  final int idx;
  final String modeOfPayment;
  final int enabled;
  final String type;

  ModeOfPayment({
    required this.name,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
    required this.docstatus,
    required this.idx,
    required this.modeOfPayment,
    required this.enabled,
    required this.type,
  });

  factory ModeOfPayment.fromJson(Map<String, dynamic> json) {
    return ModeOfPayment(
      name: json["mode_of_payment"] ?? "",
      owner: json["owner"] ?? "",
      creation: json["creation"] != null
          ? DateTime.parse(json["creation"])
          : DateTime.now(),
      modified: json["modified"] != null
          ? DateTime.parse(json["modified"])
          : DateTime.now(),
      modifiedBy: json["modified_by"] ?? "",
      docstatus: json["docstatus"] ?? 0,
      idx: json["idx"] ?? 0,
      modeOfPayment: json["mode_of_payment"] ?? "",
      enabled: json["enabled"] ?? 1,
      type: json["type"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "owner": owner,
      "creation": creation.toIso8601String(),
      "modified": modified.toIso8601String(),
      "modified_by": modifiedBy,
      "docstatus": docstatus,
      "idx": idx,
      "mode_of_payment": modeOfPayment,
      "enabled": enabled,
      "type": type,
    };
  }

  static List<ModeOfPayment> fromJsonList(String jsonString) {
    final data = json.decode(jsonString);
    return (data["data"] as List)
        .map((e) => ModeOfPayment.fromJson(e))
        .toList();
  }
}
