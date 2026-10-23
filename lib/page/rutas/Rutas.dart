import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/widget/app_top_bar.dart';
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;
import 'package:flutter_application_1/service/rest/ruta_favorita/RutaFavoritaService.dart'
    show RutaFavoritaService;
import 'package:supabase_flutter/supabase_flutter.dart';

class Rutas extends StatefulWidget {
  const Rutas({super.key});

  @override
  State<Rutas> createState() => _RutasState();
}

class _RutasState extends State<Rutas> {
  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();
  final RutaFavoritaService _rutaFavoritaService = RutaFavoritaService();

  List<Ruta> _rutas = [];
  List<Ruta> _rutasFiltradas = [];
  Map<int, String> _empresasPorId = {};
  Map<int, int> _viajesPorRuta = {}; // {idRuta: veces tomada}

  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _palette = const [
    AppColors.routeGreen, // verde oscuro
    AppColors.routeGreenLight, // verde claro
    AppColors.routePurple, // morado
    AppColors.routeMint, // verde menta
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

  Future<Map<int, int>> _cargarViajes() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final favoritas = await _rutaFavoritaService.getByUsuarioId(userId);
      final conteo = <int, int>{};
      for (final f in favoritas) {
        final id = f.idRuta;
        if (id != null) conteo[id] = (conteo[id] ?? 0) + 1;
      }
      return conteo;
    } catch (_) {
      return {}; // si falla, la lista de rutas se muestra igual
    }
  }

  List<Ruta> _ordenarPorViajes(List<Ruta> rutas) {
    final copia = [...rutas];
    copia.sort((a, b) {
      final va = _viajesPorRuta[a.id] ?? 0;
      final vb = _viajesPorRuta[b.id] ?? 0;
      if (vb != va) return vb.compareTo(va);
      return a.nombre.compareTo(b.nombre);
    });
    return copia;
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      // Se cargan en paralelo
      final results = await Future.wait([
        _rutaService.getAll(),
        _empresaService.getAll(),
        _cargarViajes(),
      ]);

      final rutas = results[0] as List<Ruta>;
      final empresas = results[1] as List<Empresa>;
      final viajes = results[2] as Map<int, int>;

      if (!mounted) return;
      setState(() {
        _viajesPorRuta = viajes;
        _rutas = _ordenarPorViajes(rutas);
        _rutasFiltradas = _rutas;
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
        _rutasFiltradas = _rutas; // ya viene ordenada
      } else {
        _rutasFiltradas = _rutas.where((r) {
          final nombreEmpresa = (_empresasPorId[r.idEmpresa] ?? '')
              .toLowerCase();
          return r.nombre.toLowerCase().contains(query) ||
              nombreEmpresa.contains(query);
        }).toList(); // filtrar conserva el orden de _rutas
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
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? const [
            AppColors.darkRouteGreen,
            AppColors.darkRouteGreenLight,
            AppColors.darkRoutePurple,
            AppColors.darkRouteMint,
          ]
        : _palette;
    return Column(
      children: [
        AppTopBar(title: 'Rutas', subtitle: 'Explora las rutas disponibles'),
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            itemCount: _rutasFiltradas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ruta = _rutasFiltradas[index];
                              final color = palette[index % palette.length];
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
                                viajes: _viajesPorRuta[ruta.id] ?? 0,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar ruta, barrio o empresa',
            prefixIcon: Icon(Icons.search, color: theme.hintColor),
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
  final int viajes;

  const _RutaCard({
    required this.ruta,
    required this.color,
    required this.codigo,
    required this.nombreEmpresa,
    required this.precioTexto,
    required this.viajes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
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
                color: theme.shadowColor.withValues(alpha: 0.05),
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
                  style: TextStyle(
                    color: color.computeLuminance() > 0.45
                        ? AppColors.text
                        : AppColors.textOnPrimary,
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
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                        fontSize: 13,
                      ),
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
    final base = (nombreEmpresa != null && nombreEmpresa!.isNotEmpty)
        ? '$nombreEmpresa · $precioTexto'
        : precioTexto;
    if (viajes == 0) return base;
    return '$base · $viajes ${viajes == 1 ? 'viaje' : 'viajes'}';
  }
}
