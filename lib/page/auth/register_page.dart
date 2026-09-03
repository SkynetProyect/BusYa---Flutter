import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/rest/auth/auth_repository.dart';
import '../../service/rest/auth/auth_repository_impl.dart.dart';
import '../../widget/custombutton/custom_button.dart';
import '../../widget/customtextfield/custom_text_field.dart';

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
  late Future<List<Map<String, dynamic>>> _tiposDocumentoFuture;

  @override
  void initState() {
    super.initState();
    // Consumimos directamente del repositorio sin tocar supabase_client
    _tiposDocumentoFuture = _authRepository.getTiposDocumento();
  }

  Future<void> _handleRegister() async {
    if (_emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _nombreCtrl.text.isEmpty ||
        _apellidoCtrl.text.isEmpty ||
        _docCtrl.text.isEmpty ||
        _celularCtrl.text.isEmpty ||
        _idTipoDocumento == null) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        numeroDocumento: _docCtrl.text.trim(),
        primerNombre: _nombreCtrl.text.trim(),
        primerApellido: _apellidoCtrl.text.trim(),
        idTipoDocumento: _idTipoDocumento!,
        celular: _celularCtrl.text.trim(),
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
                obscureText: true,
              ),
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
