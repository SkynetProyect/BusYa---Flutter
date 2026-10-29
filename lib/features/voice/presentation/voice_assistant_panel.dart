import 'dart:async';

import 'package:flutter/material.dart';

import '../application/voice_controller.dart';

class VoiceAssistantPanel extends StatelessWidget {
  const VoiceAssistantPanel({super.key, required this.controller});

  final VoiceController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visible = controller.isPanelVisible;
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: visible
                ? _PanelContents(
                    key: const ValueKey('voice-panel-visible'),
                    controller: controller,
                  )
                : const SizedBox(
                    key: ValueKey('voice-panel-hidden'),
                    width: double.infinity,
                  ),
          ),
        );
      },
    );
  }
}

class _PanelContents extends StatefulWidget {
  const _PanelContents({super.key, required this.controller});

  final VoiceController controller;

  @override
  State<_PanelContents> createState() => _PanelContentsState();
}

class _PanelContentsState extends State<_PanelContents>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  VoiceController get controller => widget.controller;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onDone() {
    if (controller.isListening) {
      unawaited(controller.stopListening());
    } else {
      unawaited(controller.dismissPanel());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transcript = controller.transcript;
    final actionMessage = controller.actionMessage;
    final hasText = transcript.isNotEmpty || actionMessage != null;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _statusLabel(controller.status),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: controller.isMuted ? 'Activar voz' : 'Silenciar voz',
                  child: IconButton(
                    tooltip: controller.isMuted
                        ? 'Activar voz'
                        : 'Silenciar voz',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: controller.toggleMuted,
                    icon: Icon(
                      controller.isMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                  ),
                ),
              ],
            ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  transcript.isNotEmpty ? transcript : actionMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              SizedBox(
                height: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SuggestionChip(
                        label: 'Pagar pasaje',
                        onPressed: () =>
                            controller.submitText('Quiero pagar el pasaje'),
                      ),
                      _SuggestionChip(
                        label: 'Ver historial',
                        onPressed: () => controller.submitText('Ver historial'),
                      ),
                      _SuggestionChip(
                        label: '¿Cuánto gasté esta semana?',
                        onPressed: () =>
                            controller.submitText('¿Cuánto gasté esta semana?'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox.square(
                  dimension: 32,
                  child: _StatusIndicator(
                    status: controller.status,
                    animation: _pulse,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.errorMessage ??
                        (controller.isListening
                            ? 'Di un comando o elige una sugerencia.'
                            : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(controller.cancel()),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _onDone, child: const Text('Listo')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(VoiceStatus status) => switch (status) {
    VoiceStatus.idle => 'Listo',
    VoiceStatus.listening => 'Te escucho…',
    VoiceStatus.thinking => 'Procesando…',
    VoiceStatus.speaking => 'Hablando…',
  };
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      label: Text(label),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status, required this.animation});

  final VoiceStatus status;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: switch (status) {
        VoiceStatus.idle => Icon(
          Icons.mic_none,
          color: colorScheme.onSurfaceVariant,
        ),
        VoiceStatus.listening => AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Transform.scale(scale: 0.8 + animation.value * 0.2, child: child),
          child: Icon(Icons.mic, color: colorScheme.primary),
        ),
        VoiceStatus.thinking => SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
        VoiceStatus.speaking => Icon(
          Icons.graphic_eq,
          color: colorScheme.primary,
        ),
      },
    );
  }
}
