class AppUser {
  const AppUser(
    this.id,
    this.phone, {
    this.admin = false,
    this.khadim = false,
    this.gate = false,
    this.permissions = const [],
  });
  final String id, phone;
  final bool admin, gate, khadim;
  final List<String> permissions;
  bool can(String section) =>
      admin || permissions.contains(section) || (section == 'gate' && gate);
  bool get staff => admin || khadim || gate || permissions.isNotEmpty;
  bool get canBookForVisitor => admin || (khadim && can('bookings'));
  String get staffHome => khadim
      ? '/khadim'
      : can('dashboard')
      ? '/admin'
      : '/admin/${['bookings', 'slots', 'settings', 'gate'].firstWhere(can, orElse: () => 'none')}';
  String get maskedPhone => phone.length < 7
      ? 'Verified mobile'
      : '${phone.substring(0, 3)} ••••• ${phone.substring(phone.length - 4)}';
}

abstract interface class AuthRepository {
  Stream<AppUser?> get userChanges;
  Future<void> sendCode(String phone);
  Future<void> verifyCode(String code);
  Future<void> signOut();
}
