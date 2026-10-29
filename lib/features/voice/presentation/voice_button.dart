import 'dart:async';

import 'package:flutter/material.dart';

import '../application/voice_controller.dart';
import '../domain/voice_intent.dart';
import 'voice_layout.dart';

class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    required this.controller,
    required this.onIntent,
  });

  final VoiceController controller;
  final void Function(VoiceIntent intent) onIntent;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);
  StreamSubscription<VoiceIntent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.intents.listen(widget.onIntent);
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.onIntent != widget.onIntent) {
      _subscription?.cancel();
      _subscription = widget.controller.intents.listen(widget.onIntent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onPressed() {
    final controller = widget.controller;
    controller.buttonTapped();
    switch (controller.status) {
      case VoiceStatus.idle:
        unawaited(controller.startListening());
      case VoiceStatus.listening:
        unawaited(controller.stopListening());
      case VoiceStatus.speaking:
        unawaited(controller.interruptSpeechAndListen());
      case VoiceStatus.thinking:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final listening = widget.controller.isListening;
        final visible = !widget.controller.isPanelVisible;

        return Semantics(
          button: true,
          label: 'Hablar con el asistente',
          enabled: visible,
          child: ExcludeSemantics(
            excluding: !visible,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedScale(
                scale: visible ? 1 : 0.75,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: SizedBox(
                    width: kVoiceButtonSize,
                    height: kVoiceButtonSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (listening)
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) => Transform.scale(
                              scale: 1 + _pulse.value * 0.18,
                              child: child,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: const SizedBox(
                                width: kVoiceButtonSize - 4,
                                height: kVoiceButtonSize - 4,
                              ),
                            ),
                          ),
                        Material(
                          color: listening
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          elevation: 3,
                          shadowColor: theme.colorScheme.shadow.withValues(
                            alpha: 0.2,
                          ),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _onPressed,
                            child: SizedBox.square(
                              dimension: kVoiceButtonSize,
                              child: Icon(
                                Icons.mic,
                                color: listening
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
