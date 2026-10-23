import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcStatusBanner extends StatefulWidget {
  const NfcStatusBanner({super.key});

  @override
  State<NfcStatusBanner> createState() => _NfcStatusBannerState();
}

class _NfcStatusBannerState extends State<NfcStatusBanner>
    with WidgetsBindingObserver {
  NfcAvailability _estado = NfcAvailability.enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarNfc();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes del sistema, se revisa de nuevo el NFC
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarNfc();
    }
  }

  Future<void> _verificarNfc() async {
    final estado = await NfcManager.instance.checkAvailability();
    if (mounted) {
      setState(() => _estado = estado);
    }
  }

  Future<void> _abrirAjustesNfc() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(action: 'android.settings.NFC_SETTINGS');
      await intent.launch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estado == NfcAvailability.enabled) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final noSoportado = _estado == NfcAvailability.unsupported;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceGreen : AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  noSoportado
                      ? 'Este dispositivo no es compatible con NFC'
                      : 'Activa el NFC para pagar tus pasajes',
                  style: TextStyle(color: colors.onSurface, fontSize: 14),
                ),
              ),
            ],
          ),
          if (!noSoportado && Platform.isAndroid) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _abrirAjustesNfc,
              child: Text(
                'Activar NFC',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
