class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidEmail(String? email) {
    if (!isNotEmpty(email)) return false;
    return _emailRegExp.hasMatch(email!.trim());
  }

  static bool isValidPassword(String? password, {int minLength = 8}) {
    if (!isNotEmpty(password)) return false;

    final value = password!.trim();

    return value.length >= minLength &&
        !value.contains(RegExp(r'\s')) &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(value);
  }

  static bool isValidDocument(String? doc) {
    if (!isNotEmpty(doc)) return false;
    return RegExp(r'^\d{6,10}$').hasMatch(doc!.trim());
  }

  static bool isValidPhone(String? phone) {
    if (!isNotEmpty(phone)) return false;
    return RegExp(r'^3\d{9}$').hasMatch(phone!.trim());
  }

  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;

    return strength;
  }
}
