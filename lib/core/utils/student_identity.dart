/// Client-side registration validation.
///
/// Accepts:
/// - Personal email (Gmail, Yahoo, Outlook, …)
/// - Campus student mail: name_YY@student.udsm.ac.tz (year must match reg)
///
/// Reg: YYYY-XX-NNNNN (e.g. 2022-04-13802).
class StudentIdentity {
  static const studentDomain = 'student.udsm.ac.tz';
  static final regNumberPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{5,})$');
  static final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final campusStudentEmailPattern = RegExp(
    r'^[a-z0-9]+(?:[._][a-z0-9]+)*_(\d{2})@student\.udsm\.ac\.tz$',
    caseSensitive: false,
  );

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
      return 'Enter a valid email (Gmail or name_YY@student.udsm.ac.tz).';
    }

    if (mail.endsWith('@$studentDomain')) {
      final campus = campusStudentEmailPattern.firstMatch(mail);
      if (campus == null) {
        return 'Student mail must look like firstname.lastname_YY@student.udsm.ac.tz '
            '(e.g. samuel.hebron_22@student.udsm.ac.tz).';
      }
      final admissionYear = regMatch.group(1)!;
      final expectedYy = admissionYear.substring(admissionYear.length - 2);
      final emailYy = campus.group(1)!;
      if (emailYy != expectedYy) {
        return 'Your student email year (_$emailYy) must match your registration year '
            '($admissionYear → _$expectedYy).';
      }
    }

    return null;
  }
}
