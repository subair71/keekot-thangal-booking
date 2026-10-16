class AppUser {
  const AppUser(
    this.id,
    this.phone, {
    this.admin = false,
    this.gate = false,
    this.permissions = const [],
  });
  final String id, phone;
  final bool admin, gate;
  final List<String> permissions;
  bool can(String section) =>
      admin || permissions.contains(section) || (section == 'gate' && gate);
  bool get staff => admin || gate || permissions.isNotEmpty;
  String get staffHome => can('dashboard')
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
