import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/NfcUiState.dart';

class WalletNfcIndicator extends StatefulWidget {
  const WalletNfcIndicator({super.key, required this.state, this.size = 170});
  final NfcUiState state;
  final double size;
  @override
  State<WalletNfcIndicator> createState() => _WalletNfcIndicatorState();
}

class _WalletNfcIndicatorState extends State<WalletNfcIndicator>
    with SingleTickerProviderStateMixin {
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  (Color bg, Color fg, IconData icon) _look(ColorScheme colors) =>
      switch (widget.state) {
        NfcUiState.idle || NfcUiState.processing => (
          colors.surface,
          colors.onSurface,
          Icons.nfc_rounded,
        ),
        NfcUiState.success || NfcUiState.successWithDebt => (
          colors.primary,
          colors.onPrimary,
          Icons.check_rounded,
        ),
        // Viaje gratis con pasaje Eco: mismo verde de éxito, pero con regalo.
        NfcUiState.ecoPass => (
          colors.primary,
          colors.onPrimary,
          Icons.card_giftcard_rounded,
        ),
        NfcUiState.emergency => (
          colors.secondary,
          colors.onSecondary,
          Icons.check_rounded,
        ),
        NfcUiState.rejected ||
        NfcUiState.error => (colors.error, colors.onError, Icons.close_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg, icon) = _look(colors);
    final s = widget.state;
    final ok =
        s == NfcUiState.success ||
        s == NfcUiState.ecoPass ||
        s == NfcUiState.emergency ||
        s == NfcUiState.successWithDebt;
    final dot = widget.size * (ok ? 0.62 : 0.5);

    Widget circle = AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      width: dot,
      height: dot,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => ScaleTransition(
          scale: a,
          child: FadeTransition(opacity: a, child: c),
        ),
        child: Icon(icon, key: ValueKey(icon), color: fg, size: dot * 0.45),
      ),
    );

    if (s == NfcUiState.rejected || s == NfcUiState.error) {
      circle = TweenAnimationBuilder<double>(
        key: ValueKey(s),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (_, t, child) => Transform.translate(
          offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
          child: child,
        ),
        child: circle,
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (s == NfcUiState.idle)
            AnimatedBuilder(
              animation: _ripple,
              builder: (_, __) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RipplePainter(_ripple.value, colors.primary),
              ),
            ),
          if (s == NfcUiState.processing)
            SizedBox(
              width: dot + 18,
              height: dot + 18,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.primary,
              ),
            ),
          circle,
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        maxR * 0.3 + maxR * 0.7 * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - p) * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter o) => o.t != t || o.color != color;
}
