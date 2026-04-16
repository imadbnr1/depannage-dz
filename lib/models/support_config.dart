class SupportConfig {
  const SupportConfig({
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.hours,
  });

  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String hours;

  factory SupportConfig.fromMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return SupportConfig(
      phone: (data['phone'] ?? '').toString(),
      whatsapp: (data['whatsapp'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      hours: (data['hours'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'hours': hours,
    };
  }

  SupportConfig copyWith({
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? hours,
  }) {
    return SupportConfig(
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      hours: hours ?? this.hours,
    );
  }
}