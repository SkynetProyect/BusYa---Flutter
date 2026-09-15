import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MisTarjetasScreen extends StatefulWidget {
  const MisTarjetasScreen({super.key});

  @override
  State<MisTarjetasScreen> createState() => _MisTarjetasScreenState();
}

// Formateador para separar los números de tarjeta de 4 en 4
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) {
      text = text.substring(0, 16);
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _MisTarjetasScreenState extends State<MisTarjetasScreen> {
  // Lista de tarjetas con diseño Wallet profesional
  final List<Map<String, dynamic>> _tarjetas = [
    {
      'numero': '4242 •••• •••• 4242',
      'tipo': 'Visa',
      'titular': 'Sara Velasquez',
      'expiracion': '12/28',
      'cvv': '123',
      'esCredito': true,
      'predeterminada': true,
    },
    {
      'numero': '5555 •••• •••• 8888',
      'tipo': 'Mastercard',
      'titular': 'Sara Velasquez',
      'expiracion': '09/27',
      'cvv': '456',
      'esCredito': false,
      'predeterminada': false,
    },
  ];

  // Controladores del formulario
  final _numeroController = TextEditingController();
  final _titularController = TextEditingController();
  final _expiracionController = TextEditingController();
  final _cvvController = TextEditingController();
  String _tipoDetectado = 'Desconocida';
  bool _esCredito = true;

  @override
  void initState() {
    super.initState();
    _numeroController.addListener(_detectarTipoTarjeta);
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _titularController.dispose();
    _expiracionController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _detectarTipoTarjeta() {
    String texto = _numeroController.text.replaceAll(' ', '');
    setState(() {
      if (texto.startsWith('4')) {
        _tipoDetectado = 'Visa';
      } else if (texto.startsWith(RegExp(r'^5[1-5]')) || texto.startsWith(RegExp(r'^2[2-7]'))) {
        _tipoDetectado = 'Mastercard';
      } else {
        _tipoDetectado = 'Tarjeta';
      }
    });
  }

  void _eliminarTarjeta(int index) {
    setState(() {
      bool eraPredeterminada = _tarjetas[index]['predeterminada'];
      _tarjetas.removeAt(index);
      if (eraPredeterminada && _tarjetas.isNotEmpty) {
        _tarjetas[0]['predeterminada'] = true;
      }
    });
  }

  void _seleccionarPredeterminada(int index) {
    setState(() {
      for (int i = 0; i < _tarjetas.length; i++) {
        _tarjetas[i]['predeterminada'] = (i == index);
      }
    });
  }

  // Modal estilo Apple Wallet para elegir método (NFC o Manual)
  void _mostrarOpcionesAgregado() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Añadir Tarjeta a BusYa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.nfc, color: Colors.white),
                ),
                title: const Text('Escanear con NFC'),
                subtitle: const Text('Acerca la tarjeta al reverso del dispositivo'),
                onTap: () {
                  Navigator.pop(context);
                  _simularLecturaNFC();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                title: const Text('Agregar manualmente'),
                subtitle: const Text('Ingresa los datos de tu tarjeta'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioManual();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Simulación de lectura NFC estilo Apple Wallet
  void _simularLecturaNFC() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 10),
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Acerque su teléfono al reverso de la tarjeta',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'No quite la tarjeta sino hasta que la lea completamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );

    // Simulamos que lee la tarjeta a los 3 segundos y abre el formulario autocompletado
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Cierra el diálogo NFC
      _numeroController.text = '4242 5810 9920 3311';
      _titularController.text = 'Sara Velasquez';
      _expiracionController.text = '11/30';
      _cvvController.text = '888';
      _mostrarFormularioManual(esAutocompletadoNFC: true);
    });
  }

  void _mostrarFormularioManual({bool esAutocompletadoNFC = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(esAutocompletadoNFC ? '¡Tarjeta leída con NFC!' : 'Registrar Nueva Tarjeta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _numeroController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardNumberFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Número de Tarjeta',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            _tipoDetectado,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _tipoDetectado == 'Visa' ? Colors.blue : (_tipoDetectado == 'Mastercard' ? Colors.orange : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titularController,
                      decoration: const InputDecoration(labelText: 'Nombre del Titular'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expiracionController,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(labelText: 'MM/AA', hintText: '12/28'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tipo de Tarjeta:', style: TextStyle(color: Colors.grey)),
                        DropdownButton<bool>(
                          value: _esCredito,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Crédito')),
                            DropdownMenuItem(value: false, child: Text('Débito')),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              _esCredito = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limpiarCampos();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    if (_numeroController.text.isNotEmpty &&
                        _titularController.text.isNotEmpty &&
                        _expiracionController.text.isNotEmpty &&
                        _cvvController.text.isNotEmpty) {
                      setState(() {
                        bool esPrimera = _tarjetas.isEmpty;
                        _tarjetas.add({
                          'numero': _numeroController.text,
                          'tipo': _tipoDetectado,
                          'titular': _titularController.text,
                          'expiracion': _expiracionController.text,
                          'cvv': _cvvController.text,
                          'esCredito': _esCredito,
                          'predeterminada': esPrimera,
                        });
                      });
                      _limpiarCampos();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _limpiarCampos() {
    _numeroController.clear();
    _titularController.clear();
    _expiracionController.clear();
    _cvvController.clear();
    setState(() {
      _tipoDetectado = 'Desconocida';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tarjetas'),
        backgroundColor: Colors.green,
      ),
      body: _tarjetas.isEmpty
          ? const Center(
              child: Text('No tienes tarjetas registradas', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tarjetas.length,
              itemBuilder: (context, index) {
                final tarjeta = _tarjetas[index];
                bool esPredeterminada = tarjeta['predeterminada'];

                return Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: esPredeterminada
                          ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
                          : [const Color(0xFF37474F), const Color(0xFF546E7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Fila superior: Tipo, Contactless y Predeterminada
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tarjeta['tipo'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Icon(Icons.contactless, color: Colors.white70, size: 28),
                          ],
                        ),
                        // Número de la tarjeta
                        Text(
                          tarjeta['numero'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Fila inferior: Titular, Expiración y Acciones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TITULAR', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                Text(
                                  tarjeta['titular'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('EXP', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                Text(
                                  tarjeta['expiracion'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (!esPredeterminada)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.white70),
                                    tooltip: 'Hacer predeterminada',
                                    onPressed: () => _seleccionarPredeterminada(index),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Eliminar tarjeta',
                                  onPressed: () => _eliminarTarjeta(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarOpcionesAgregado,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}