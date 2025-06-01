class Customer {
  final String? id;
  final String? code;
  final String? name;
  final String? phone;
  final String? address;
  final String? uuid;
  final String? created_at;
  final String? updated_at;
  final String? default_price_list;

  Customer({
    this.id,
    this.code,
    this.name,
    this.phone,
    this.address,
    this.uuid,
    this.created_at,
    this.updated_at,
    this.default_price_list,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['name'] ?? '',
      code: json['name'] ?? '',
      name: json['customer_name'] ?? '',
      phone: json['custom_phone'] ?? '',
      address: json['custom_address'] ?? '',
      uuid: json['name'] ?? '',
      created_at: json['creation'] ?? '',
      updated_at: json['modified'] ?? '',
      default_price_list: json['default_price_list'] ?? 'Standard Selling',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'uuid': uuid,
      'created_at': created_at,
      'updated_at': updated_at,
      'default_price_list': default_price_list,
    };
  }
}
