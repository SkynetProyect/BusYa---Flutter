import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Selección persistida de Empresa y Ruta.
class SavedSelection {
  final int? empresaId;
  final int? rutaId;
  const SavedSelection({this.empresaId, this.rutaId});

  @override
  String toString() => 'SavedSelection(empresa=$empresaId, ruta=$rutaId)';
}

/// Persiste la Empresa y Ruta elegidas por el usuario.
/// - Singleton con caché en memoria: sobrevive a que la pantalla se destruya
///   al cambiar de página, aunque falle el disco.
/// - SharedPreferences: sobrevive al cierre de la app.
class SelectionStorageService {
  static final SelectionStorageService _instance = SelectionStorageService._();
  factory SelectionStorageService() => _instance;
  SelectionStorageService._();

  static const _kEmpresaId = 'inicio_empresa_id';
  static const _kRutaId = 'inicio_ruta_id';

  SavedSelection? _cache;

  /// Lee la selección guardada (memoria primero, luego disco).
  Future<SavedSelection> load() async {
    if (_cache != null) {
      debugPrint('[SELECTION] load (memoria): $_cache');
      return _cache!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _cache = SavedSelection(
        empresaId: prefs.getInt(_kEmpresaId),
        rutaId: prefs.getInt(_kRutaId),
      );
      debugPrint('[SELECTION] load (disco): $_cache');
      return _cache!;
    } catch (e) {
      debugPrint('[SELECTION] load error: $e');
      return const SavedSelection();
    }
  }

  /// Guarda la selección; un valor null elimina la clave correspondiente.
  Future<void> save({int? empresaId, int? rutaId}) async {
    // Memoria primero: garantiza la restauración aunque falle el disco.
    _cache = SavedSelection(empresaId: empresaId, rutaId: rutaId);
    debugPrint('[SELECTION] save: $_cache');
    try {
      final prefs = await SharedPreferences.getInstance();
      await _putOrRemove(prefs, _kEmpresaId, empresaId);
      await _putOrRemove(prefs, _kRutaId, rutaId);
    } catch (e) {
      debugPrint('[SELECTION] save error: $e');
    }
  }

  Future<void> _putOrRemove(SharedPreferences prefs, String key, int? value) {
    return value == null ? prefs.remove(key) : prefs.setInt(key, value);
  }
}
