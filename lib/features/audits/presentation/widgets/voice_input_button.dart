import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Pulsante compatto per la dettatura vocale integrabile come suffixIcon o azione.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;
  final String? tooltip;
  final double size;

  const VoiceInputButton({
    super.key,
    required this.controller,
    this.onChanged,
    this.tooltip = 'Dettatura vocale',
    this.size = 20,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _speechInitialized = false;

  bool _isListening = false;
  String _preListenText = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
          lowerBound: 0.85,
          upperBound: 1.15,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pulseController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            _pulseController.forward();
          }
        });
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    // Inizializza speech_to_text se non ancora inizializzato
    if (!_speechInitialized) {
      try {
        final available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted && _isListening) {
                setState(() => _isListening = false);
                _pulseController.stop();
              }
            }
          },
          onError: (errorNotification) {
            if (mounted) {
              setState(() => _isListening = false);
              _pulseController.stop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Dettatura vocale: ${errorNotification.errorMsg}',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
        _speechInitialized = available;
      } catch (e) {
        _speechInitialized = false;
      }
    }

    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Riconoscimento vocale non disponibile o autorizzazione microfono non concessa.',
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _preListenText = widget.controller.text.trim();

    setState(() => _isListening = true);
    _pulseController.forward();

    try {
      // Cerca la lingua italiana tra le disponibili, altrimenti usa default di sistema
      final locales = await _speech.locales();
      String? itLocaleId;
      for (final loc in locales) {
        if (loc.localeId.toLowerCase().startsWith('it')) {
          itLocaleId = loc.localeId;
          break;
        }
      }

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: itLocaleId ?? 'it_IT',
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          final recognized = result.recognizedWords.trim();
          if (recognized.isNotEmpty && mounted) {
            String updated;
            if (_preListenText.isEmpty) {
              // Capitalizza la prima lettera
              updated = recognized[0].toUpperCase() + recognized.substring(1);
            } else {
              // Aggiungi a quanto già presente
              final needsSpace =
                  !_preListenText.endsWith(' ') &&
                  !_preListenText.endsWith('\n') &&
                  !_preListenText.endsWith(';');
              updated = '$_preListenText${needsSpace ? " " : ""}$recognized';
            }

            widget.controller.text = updated;
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
            widget.onChanged?.call();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isListening) {
      return ScaleTransition(
        scale: _pulseController,
        child: IconButton(
          icon: Icon(
            Icons.mic_rounded,
            color: Colors.red.shade600,
            size: widget.size + 2,
          ),
          tooltip: 'In ascolto... tocca per terminare',
          onPressed: _toggleListening,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.mic_none_rounded,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        size: widget.size,
      ),
      tooltip: widget.tooltip,
      onPressed: _toggleListening,
    );
  }
}
