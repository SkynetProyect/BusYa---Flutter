class PerfilValidators {
  static String? validarNombre(String? value) {
    final nombre = value?.trim() ?? '';

    if (nombre.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }

    if (nombre.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (nombre.length > 50) {
      return 'El nombre no puede superar los 50 caracteres';
    }

    // Permite letras, espacios, tildes y ñ.
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$");

    if (!regex.hasMatch(nombre)) {
      return 'El nombre solo puede contener letras y espacios';
    }

    return null;
  }

  static String? validarApellido(String? value) {
    final apellido = value?.trim() ?? '';

    if (apellido.isEmpty) {
      return 'Por favor ingresa tu apellido';
    }

    if (apellido.length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }

    if (apellido.length > 50) {
      return 'El apellido no puede superar los 50 caracteres';
    }

    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$");

    if (!regex.hasMatch(apellido)) {
      return 'El apellido solo puede contener letras y espacios';
    }

    return null;
  }

  static String? validarCelular(String? value) {
    final celular = value?.trim() ?? '';

    if (celular.isEmpty) {
      return 'Por favor ingresa tu celular';
    }

    if (!RegExp(r'^\d+$').hasMatch(celular)) {
      return 'El celular solo puede contener números';
    }

    if (celular.length != 10) {
      return 'El celular debe tener exactamente 10 dígitos';
    }

    return null;
  }
}
