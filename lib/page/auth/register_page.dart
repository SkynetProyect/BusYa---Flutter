import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/validators.dart';
import '../../service/rest/auth/auth_repository.dart';
import '../../service/rest/auth/auth_repository_impl.dart.dart';
import '../../widget/custombutton/custom_button.dart';
import '../../widget/customtextfield/custom_text_field.dart';
import '../../widget/passwordstrengthindicator/password_strength_indicator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthRepository _authRepository = AuthRepositoryImpl();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();

  int? _idTipoDocumento;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late Future<List<Map<String, dynamic>>> _tiposDocumentoFuture;

  @override
  void initState() {
    super.initState();
    _tiposDocumentoFuture = _authRepository.getTiposDocumento();
    _passCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPasswordChanged);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _docCtrl.dispose();
    _celularCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final documento = _docCtrl.text.trim();
    final celular = _celularCtrl.text.trim();

    if (!Validators.isNotEmpty(nombre) ||
        !Validators.isNotEmpty(apellido) ||
        !Validators.isNotEmpty(documento) ||
        !Validators.isNotEmpty(celular) ||
        !Validators.isNotEmpty(email) ||
        !Validators.isNotEmpty(password) ||
        _idTipoDocumento == null) {
      _showSnackBar('Por favor completa todos los campos obligatorios');
      return;
    }

    if (!Validators.isValidDocument(documento)) {
      _showSnackBar('El número de documento debe tener entre 6 y 10 dígitos');
      return;
    }

    if (!Validators.isValidPhone(celular)) {
      _showSnackBar(
        'El celular debe ser un número válido de 10 dígitos (ej. 3001234567)',
      );
      return;
    }

    if (!Validators.isValidEmail(email)) {
      _showSnackBar('Por favor ingresa un correo electrónico válido');
      return;
    }

    if (!Validators.isValidPassword(password)) {
      _showSnackBar(
        'La contraseña debe tener mínimo 8 caracteres, mayúscula, minúscula, número y carácter especial',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        numeroDocumento: documento,
        primerNombre: nombre,
        primerApellido: apellido,
        idTipoDocumento: _idTipoDocumento!,
        celular: celular,
      );

      if (mounted) {
        _showSnackBar('Cuenta creada exitosamente');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('Error al realizar el registro');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF33304E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkPurple = Color(0xFF33304E);
    const greenPrimary = Color(0xFF529471);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(color: darkPurple, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBECEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos Personales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nombreCtrl,
                label: 'Primer Nombre',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _apellidoCtrl,
                label: 'Primer Apellido',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),

              // Carga asíncrona mediante el Repositorio
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _tiposDocumentoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: CircularProgressIndicator(color: greenPrimary),
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text(
                      'Error al cargar tipos de documento',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final listaDocs = snapshot.data!;
                  _idTipoDocumento ??= listaDocs.first['id'] as int;

                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tipo de Documento',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: greenPrimary,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _idTipoDocumento,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: greenPrimary,
                        ),
                        items: listaDocs.map((doc) {
                          return DropdownMenuItem<int>(
                            value: doc['id'] as int,
                            child: Text('${doc['codigo']} - ${doc['nombre']}'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _idTipoDocumento = val),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              CustomTextField(
                controller: _docCtrl,
                label: 'Número de Documento',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _celularCtrl,
                label: 'Celular',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Text(
                'Seguridad de la Cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailCtrl,
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _passCtrl,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              // Checklist interactivo y barra de fortaleza
              PasswordStrengthIndicator(password: _passCtrl.text),

              const SizedBox(height: 24),
              CustomButton(
                text: 'Registrarse',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
