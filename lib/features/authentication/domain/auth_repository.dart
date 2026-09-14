class AppUser {
  const AppUser(this.id, this.phone, {this.admin = false, this.gate = false});
  final String id, phone;
  final bool admin, gate;
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
