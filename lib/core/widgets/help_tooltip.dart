import 'package:flutter/material.dart';

class HelpTooltip extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const HelpTooltip({
    super.key,
    required this.text,
    this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      showDuration: const Duration(seconds: 5),
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          Icons.help_outline_rounded,
          size: size,
          color: color ?? Colors.blueGrey.shade300,
        ),
      ),
    );
  }
}
