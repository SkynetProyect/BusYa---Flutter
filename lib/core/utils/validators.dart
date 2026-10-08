class Validators {
  static const Map<int, String> _documentTypeCodes = {
    1: 'CC',
    2: 'CE',
    3: 'TI',
    4: 'PP',
    5: 'NIT',
    6: 'DNI',
  };

  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidName(String? name) {
    if (!isNotEmpty(name)) return false;
    final value = name!.trim();
    if (value.length < 2 || value.length > 50) return false;
    return RegExp(
      r"^[\p{L}]+(?:[ '-][\p{L}]+)*$",
      unicode: true,
    ).hasMatch(value);
  }

  static bool isValidDocumentType(int? id) {
    return id != null && _documentTypeCodes.containsKey(id);
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

  static bool isValidDocument(String? doc, {int? documentTypeId}) {
    if (!isNotEmpty(doc) || !isValidDocumentType(documentTypeId)) return false;

    final value = doc!.trim();
    switch (_documentTypeCodes[documentTypeId]) {
      case 'CC':
      case 'TI':
      case 'DNI':
        return RegExp(r'^\d{6,10}$').hasMatch(value);
      case 'CE':
        return RegExp(r'^\d{6,12}$').hasMatch(value);
      case 'PP':
        return RegExp(r'^[A-Za-z0-9]{6,12}$').hasMatch(value);
      case 'NIT':
        return RegExp(r'^\d{9,10}$').hasMatch(value);
      default:
        return false;
    }
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
