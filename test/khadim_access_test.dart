import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';

void main() {
  test(
    'Khadim access only includes granted sections and never implies admin',
    () {
      const user = AppUser('staff', '+919876543210', permissions: ['slots']);
      expect(user.staff, isTrue);
      expect(user.admin, isFalse);
      expect(user.can('slots'), isTrue);
      expect(user.can('settings'), isFalse);
      expect(user.can('bookings'), isFalse);
      expect(user.can('gate'), isFalse);
      expect(user.can('khadims'), isFalse);
      expect(user.staffHome, '/admin/slots');
    },
  );
  test('Revoked access leaves no staff landing page', () {
    const user = AppUser('staff', '+919876543210');
    expect(user.staff, isFalse);
    expect(user.can('dashboard'), isFalse);
  });
  test('Existing gate and admin permissions remain supported', () {
    const gate = AppUser('gate', '', gate: true);
    const admin = AppUser('admin', '', admin: true);
    expect(gate.staffHome, '/admin/gate');
    expect(gate.can('settings'), isFalse);
    expect(admin.can('khadims'), isTrue);
    expect(admin.staffHome, '/admin');
  });
}
