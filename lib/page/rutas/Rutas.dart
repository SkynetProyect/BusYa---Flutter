import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:flutter_application_1/core/supabase_client.dart';
import 'package:flutter_application_1/model/Empresa.dart' show Empresa;
import 'package:flutter_application_1/model/Ruta.dart' show Ruta;
import 'package:flutter_application_1/model/RutaFavorita.dart'
    show RutaFavorita;
import 'package:flutter_application_1/widget/app_top_bar.dart';
import 'package:flutter_application_1/service/rest/empresa/EmpresaService.dart'
    show EmpresaService;
import 'package:flutter_application_1/service/rest/ruta/RutaService.dart'
    show RutaService;
import 'package:flutter_application_1/service/rest/ruta_favorita/RutaFavoritaService.dart'
    show RutaFavoritaService;

/// Pantalla de rutas dividida en dos listas:
/// - Arriba: las rutas favoritas del usuario (tabla rutas_favoritas).
/// - Abajo: todas las rutas, cada una con una estrella para marcarla
///   o quitarla de favoritas.
class Rutas extends StatefulWidget {
  const Rutas({super.key});

  @override
  State<Rutas> createState() => _RutasState();
}

class _RutasState extends State<Rutas> {
  static const List<Color> _paletaClara = [
    AppColors.routeGreen, // verde oscuro
    AppColors.routeGreenLight, // verde claro
    AppColors.routePurple, // morado
    AppColors.routeMint, // verde menta
  ];

  static const List<Color> _paletaOscura = [
    AppColors.darkRouteGreen,
    AppColors.darkRouteGreenLight,
    AppColors.darkRoutePurple,
    AppColors.darkRouteMint,
  ];

  final RutaService _rutaService = RutaService();
  final EmpresaService _empresaService = EmpresaService();
  final RutaFavoritaService _rutaFavoritaService = RutaFavoritaService();

  final TextEditingController _searchController = TextEditingController();

  List<Ruta> _rutas = [];
  Map<int, String> _empresasPorId = {};

  // {idRuta: filas de rutas_favoritas de esa ruta}
  // Es una lista por si en la tabla hubiera filas repetidas de la misma ruta.
  Map<int, List<RutaFavorita>> _favoritasPorRuta = {};

  // Rutas con una operación en curso (evita doble toque en la estrella).
  final Set<int> _rutasEnProceso = {};

  bool _loading = true;

  String? get _userId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- CARGA DE DATOS ----------

  Future<void> _cargarDatos({bool mostrarSpinner = true}) async {
    if (mostrarSpinner) setState(() => _loading = true);

    // Se cargan en paralelo. Cada método maneja sus propios errores.
    await Future.wait([_cargarRutasYEmpresas(), _recargarFavoritas()]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarRutasYEmpresas() async {
    try {
      final resultados = await Future.wait([
        _rutaService.getAll(),
        _empresaService.getAll(),
      ]);

      final rutas = resultados[0] as List<Ruta>;
      final empresas = resultados[1] as List<Empresa>;

      if (!mounted) return;
      setState(() {
        _rutas = [...rutas]..sort((a, b) => a.nombre.compareTo(b.nombre));
        _empresasPorId = {
          for (final e in empresas)
            if (e.id != null) e.id!: e.nombre,
        };
      });
    } catch (_) {
      // Los servicios ya muestran el popup de error
    }
  }

  /// Vuelve a pedir las favoritas a la tabla rutas_favoritas.
  /// Se usa al abrir la pantalla y después de agregar o quitar una favorita.
  Future<void> _recargarFavoritas() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final favoritas = await _rutaFavoritaService.getByUsuarioId(userId);

      if (!mounted) return;
      setState(() => _favoritasPorRuta = _agruparPorRuta(favoritas));
    } catch (_) {
      // El servicio ya muestra el popup; se conserva la lista actual.
    }
  }

  Map<int, List<RutaFavorita>> _agruparPorRuta(List<RutaFavorita> favoritas) {
    final mapa = <int, List<RutaFavorita>>{};
    for (final favorita in favoritas) {
      final idRuta = favorita.idRuta;
      if (idRuta == null) continue;
      mapa.putIfAbsent(idRuta, () => []).add(favorita);
    }
    return mapa;
  }

  // ---------- FAVORITAS: AGREGAR Y QUITAR ----------

  bool _esFavorita(Ruta ruta) {
    final id = ruta.id;
    return id != null && _favoritasPorRuta.containsKey(id);
  }

  Future<void> _alternarFavorita(Ruta ruta) {
    return _esFavorita(ruta) ? _quitarFavorita(ruta) : _agregarFavorita(ruta);
  }

  Future<void> _agregarFavorita(Ruta ruta) async {
    final idRuta = ruta.id;
    final userId = _userId;
    if (idRuta == null || userId == null) return;

    await _ejecutarSobreRuta(idRuta, () async {
      await _rutaFavoritaService.create(
        RutaFavorita(idUsuario: userId, idRuta: idRuta),
      );
    });
  }

  Future<void> _quitarFavorita(Ruta ruta) async {
    final idRuta = ruta.id;
    if (idRuta == null) return;

    final filas = _favoritasPorRuta[idRuta] ?? [];

    await _ejecutarSobreRuta(idRuta, () async {
      for (final fila in filas) {
        final id = fila.id;
        if (id != null) await _rutaFavoritaService.delete(id);
      }
    });
  }

  /// Ejecuta [accion] y luego recarga las favoritas desde el servicio.
  /// Mientras tanto la estrella de esa ruta muestra un indicador de carga.
  Future<void> _ejecutarSobreRuta(
    int idRuta,
    Future<void> Function() accion,
  ) async {
    if (_rutasEnProceso.contains(idRuta)) return;

    setState(() => _rutasEnProceso.add(idRuta));
    try {
      await accion();
      await _recargarFavoritas();
    } catch (_) {
      // El servicio ya muestra el popup de error
    } finally {
      if (mounted) setState(() => _rutasEnProceso.remove(idRuta));
    }
  }

  // ---------- LISTAS DERIVADAS DEL ESTADO ----------

  List<Ruta> get _rutasFavoritas {
    return _rutas.where(_esFavorita).toList();
  }

  List<Ruta> get _rutasVisibles {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _rutas;

    return _rutas.where((r) {
      final nombreEmpresa = (_empresasPorId[r.idEmpresa] ?? '').toLowerCase();
      return r.nombre.toLowerCase().contains(query) ||
          nombreEmpresa.contains(query);
    }).toList();
  }

  // ---------- FORMATO ----------

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

  // El color depende del id de la ruta, así no cambia al filtrar o reordenar.
  Color _colorDeRuta(Ruta ruta) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final paleta = oscuro ? _paletaOscura : _paletaClara;
    return paleta[(ruta.id ?? 0) % paleta.length];
  }

  // ---------- INTERFAZ ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const AppTopBar(
          title: 'Rutas',
          subtitle: 'Explora las rutas disponibles',
        ),
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [_buildSeccionFavoritas(), _buildSeccionTodas()],
            ),
          ),
        ),
      ],
    );
  }

  // ----- Sección de arriba: favoritas -----

  Widget _buildSeccionFavoritas() {
    final favoritas = _rutasFavoritas;
    final encabezado = _buildEncabezado(
      titulo: 'Mis favoritas',
      icono: Icons.star_rounded,
      cantidad: _loading ? null : favoritas.length,
    );

    // Sin favoritas: un mensaje corto para no quitarle espacio a la otra lista.
    if (!_loading && favoritas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          encabezado,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Aún no tienes rutas favoritas. '
              'Toca la estrella de una ruta para agregarla.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ],
      );
    }

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          encabezado,
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildListaRutas(
                    favoritas,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  ),
          ),
        ],
      ),
    );
  }

  // ----- Sección de abajo: todas las rutas -----

  Widget _buildSeccionTodas() {
    final visibles = _rutasVisibles;

    return Expanded(
      flex: 3,
      child: Column(
        children: [
          _buildEncabezado(
            titulo: 'Todas las rutas',
            icono: Icons.directions_bus_rounded,
            cantidad: _loading ? null : _rutas.length,
          ),
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visibles.isEmpty
                ? const Center(child: Text('No se encontraron rutas'))
                : RefreshIndicator(
                    onRefresh: () => _cargarDatos(mostrarSpinner: false),
                    child: _buildListaRutas(
                      visibles,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ----- Piezas compartidas -----

  Widget _buildEncabezado({
    required String titulo,
    required IconData icono,
    int? cantidad,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icono, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (cantidad != null)
            Text(
              '$cantidad',
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildListaRutas(List<Ruta> rutas, {required EdgeInsets padding}) {
    return ListView.separated(
      padding: padding,
      itemCount: rutas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTarjeta(rutas[index]),
    );
  }

  Widget _buildTarjeta(Ruta ruta) {
    final idEmpresa = ruta.idEmpresa;

    return _RutaCard(
      ruta: ruta,
      color: _colorDeRuta(ruta),
      codigo: _codigoRuta(ruta),
      nombreEmpresa: idEmpresa != null ? _empresasPorId[idEmpresa] : null,
      precioTexto: _precioFormateado(ruta.precioPasaje),
      trailing: _buildBotonFavorita(ruta),
      onTap: () {
        // TODO: navegar a detalle / mapa de la ruta
      },
    );
  }

  /// Estrella vacía = agregar a favoritas. Estrella llena = quitar de favoritas.
  /// Se usa igual en las dos listas.
  Widget _buildBotonFavorita(Ruta ruta) {
    final theme = Theme.of(context);
    final id = ruta.id;
    final esFavorita = _esFavorita(ruta);

    if (id != null && _rutasEnProceso.contains(id)) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: esFavorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
      icon: Icon(
        esFavorita ? Icons.star_rounded : Icons.star_border_rounded,
        color: esFavorita ? Colors.amber : theme.hintColor,
      ),
      onPressed: _userId == null ? null : () => _alternarFavorita(ruta),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
  final Widget? trailing;
  final VoidCallback onTap;

  const _RutaCard({
    required this.ruta,
    required this.color,
    required this.codigo,
    required this.nombreEmpresa,
    required this.precioTexto,
    required this.onTap,
    this.trailing,
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
              if (trailing != null) trailing!,
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
