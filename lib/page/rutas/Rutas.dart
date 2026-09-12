import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/page/rutas/componentes/TopBar.dart'
    show TopBar;
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;

class Rutas extends StatefulWidget {
  const Rutas({super.key});

  @override
  State<Rutas> createState() => _RutasState();
}

class _RutasState extends State<Rutas> {
  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();

  List<Ruta> _rutas = [];
  List<Ruta> _rutasFiltradas = [];
  Map<int, String> _empresasPorId = {};
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _palette = const [
    Color(0xFF2E7D5B), // verde oscuro
    Color(0xFF8FD3B6), // verde claro
    Color(0xFF6B5B7B), // morado
    Color(0xFFA9DFC4), // verde menta
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      // Se cargan en paralelo
      final results = await Future.wait([
        _rutaService.getAll(),
        _empresaService.getAll(),
      ]);

      final rutas = results[0] as List<Ruta>;
      final empresas = results[1] as List<Empresa>;

      setState(() {
        _rutas = rutas;
        _rutasFiltradas = rutas;
        _empresasPorId = {
          for (final e in empresas)
            if (e.id != null) e.id!: e.nombre,
        };
      });
    } catch (_) {
      // Los servicios ya muestran el popup de error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _rutasFiltradas = _rutas;
      } else {
        _rutasFiltradas = _rutas.where((r) {
          final nombreEmpresa = (_empresasPorId[r.idEmpresa] ?? '')
              .toLowerCase();
          return r.nombre.toLowerCase().contains(query) ||
              nombreEmpresa.contains(query);
        }).toList();
      }
    });
  }

  String _codigoRuta(Ruta ruta) {
    return (ruta.id ?? 0).toString().padLeft(3, '0');
  }

  String _precioFormateado(double precio) {
    final entero = precio.round();
    final str = entero.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posDesdeFinal = str.length - i;
      buffer.write(str[i]);
      if (posDesdeFinal > 1 && posDesdeFinal % 3 == 1) {
        buffer.write('.');
      }
    }
    return '\$$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Container(
            color: const Color.fromARGB(255, 245, 245, 247),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rutasFiltradas.isEmpty
                      ? const Center(child: Text('No se encontraron rutas'))
                      : RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _rutasFiltradas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ruta = _rutasFiltradas[index];
                              final color = _palette[index % _palette.length];
                              final nombreEmpresa = ruta.idEmpresa != null
                                  ? _empresasPorId[ruta.idEmpresa]
                                  : null;
                              return _RutaCard(
                                ruta: ruta,
                                color: color,
                                codigo: _codigoRuta(ruta),
                                nombreEmpresa: nombreEmpresa,
                                precioTexto: _precioFormateado(
                                  ruta.precioPasaje,
                                ),
                                onTap: () {
                                  // TODO: navegar a detalle / mapa de la ruta
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar ruta, barrio o empresa',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _RutaCard extends StatelessWidget {
  final Ruta ruta;
  final Color color;
  final String codigo;
  final String? nombreEmpresa;
  final String precioTexto;
  final VoidCallback onTap;

  const _RutaCard({
    required this.ruta,
    required this.color,
    required this.codigo,
    required this.nombreEmpresa,
    required this.precioTexto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color,
                child: Text(
                  codigo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitulo(),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitulo() {
    if (nombreEmpresa != null && nombreEmpresa!.isNotEmpty) {
      return '$nombreEmpresa · $precioTexto';
    }
    return precioTexto;
  }
}
