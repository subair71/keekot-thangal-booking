/// Accepts international numbers with familiar spacing, parentheses or hyphens.
/// A manually entered number is contact information, not a verified identity.
String? normalizeVisitorPhone(String value) {
  if (value.length > 40) return null;
  final phone = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone) ? phone : null;
}
