class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAtIso,
    this.isApproved = true,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String createdAtIso;
  final bool isApproved;

  String get normalizedRole => role.trim().toLowerCase();

  bool get isCustomer => normalizedRole == 'customer';
  bool get isProvider => normalizedRole == 'provider';
  bool get isAdmin => normalizedRole == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': normalizedRole,
      'createdAtIso': createdAtIso,
      'isApproved': isApproved,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: (map['uid'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'customer').toString(),
      createdAtIso: (map['createdAtIso'] ?? '').toString(),
      isApproved: map['isApproved'] == true,
    );
  }
}
