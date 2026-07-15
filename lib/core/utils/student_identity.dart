/// Client-side registration validation.
///
/// Email: any valid address (campus student webmail SMTP is unreliable).
/// Reg: YYYY-XX-NNNNN (e.g. 2022-04-13802).
class StudentIdentity {
  static final regNumberPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{5,})$');
  static final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String normalizeRegNumber(String reg) =>
      reg.trim().replaceAll(RegExp(r'\s+'), '');

  /// Returns null if valid; otherwise a user-facing message.
  static String? validateRegistration({
    required String email,
    required String registrationNumber,
  }) {
    final reg = normalizeRegNumber(registrationNumber);
    final mail = normalizeEmail(email);

    final regMatch = regNumberPattern.firstMatch(reg);
    if (regMatch == null) {
      return 'Registration number must look like 2022-04-13802 (YYYY-XX-NNNNN).';
    }

    if (!emailPattern.hasMatch(mail)) {
      return 'Enter a valid email address (e.g. you@gmail.com).';
    }

    return null;
  }
}
