/// Client-side mirror of backend UDSM student identity rules.
///
/// Email: name.surname_YY@student.udsm.ac.tz
/// Portal: https://studentmail.udsm.ac.tz/
class StudentIdentity {
  static const studentEmailDomain = 'student.udsm.ac.tz';
  static final regNumberPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{5,})$');
  static final studentEmailPattern = RegExp(
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

    if (!mail.endsWith('@$studentEmailDomain')) {
      return 'Use your official UDSM student mail ending with @student.udsm.ac.tz '
          '(login at studentmail.udsm.ac.tz).';
    }

    final emailMatch = studentEmailPattern.firstMatch(mail);
    if (emailMatch == null) {
      return 'Student email must look like firstname.lastname_YY@student.udsm.ac.tz '
          '(e.g. samuel.hebron_22@student.udsm.ac.tz).';
    }

    final admissionYear = regMatch.group(1)!;
    final expectedYy = admissionYear.substring(admissionYear.length - 2);
    final emailYy = emailMatch.group(1)!;

    if (emailYy != expectedYy) {
      return 'Your email year (_$emailYy) must match your registration year '
          '($admissionYear → _$expectedYy). Use the address from studentmail.udsm.ac.tz.';
    }

    return null;
  }
}
