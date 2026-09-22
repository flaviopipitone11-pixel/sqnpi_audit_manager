import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/audit_standard.dart';
import '../domain/standard_controller.dart';
import '../../features/auth/presentation/auth_controller.dart';

class StandardSwitcherBadge extends ConsumerWidget {
  final bool isDarkBackground;
  final bool compact;

  const StandardSwitcherBadge({
    super.key,
    this.isDarkBackground = false,
    this.compact = false,
  });

  void _showSwitchDialog(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authControllerProvider);
    final current = ref.read(currentStandardProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Modulo di Controllo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleziona lo standard operativo per la sessione corrente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                // Opzione SQNPI
                _StandardSelectionTile(
                  standard: AuditStandard.sqnpi,
                  isEnabled: auth.canAccessSqnpi,
                  isSelected: current == AuditStandard.sqnpi,
                  onSelect: () async {
                    await ref
                        .read(currentStandardProvider.notifier)
                        .setStandard(AuditStandard.sqnpi);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
                // Opzione BIO
                _StandardSelectionTile(
                  standard: AuditStandard.bio,
                  isEnabled: auth.canAccessBio,
                  isSelected: current == AuditStandard.bio,
                  onSelect: () async {
                    await ref
                        .read(currentStandardProvider.notifier)
                        .setStandard(AuditStandard.bio);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/select-standard');
                    },
                    icon: const Icon(Icons.view_carousel_outlined, size: 16),
                    label: const Text(
                      'Apri schermata di selezione standard',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentStandardProvider);
    final auth = ref.watch(authControllerProvider);
    final isMulti = auth.isMultiStandard;

    final bgColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.18)
        : current.primaryColor.withValues(alpha: 0.1);

    final textColor = isDarkBackground ? Colors.white : current.primaryColor;

    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.28)
        : current.primaryColor.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isMulti ? () => _showSwitchDialog(context, ref) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(current.icon, size: compact ? 14 : 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                current.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              if (isMulti) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: compact ? 16 : 18,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StandardSelectionTile extends StatelessWidget {
  final AuditStandard standard;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onSelect;

  const _StandardSelectionTile({
    required this.standard,
    required this.isEnabled,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = standard.primaryColor;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isEnabled ? onSelect : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(standard.icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        standard.fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? primaryColor
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        standard.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: primaryColor, size: 22)
                else if (isEnabled)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
