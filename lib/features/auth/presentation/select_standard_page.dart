import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/audit_standard.dart';
import '../../../core/domain/standard_controller.dart';
import 'auth_controller.dart';

class SelectStandardPage extends ConsumerWidget {
  const SelectStandardPage({super.key});

  void _chooseStandard(
    BuildContext context,
    WidgetRef ref,
    AuditStandard standard,
  ) async {
    await ref.read(currentStandardProvider.notifier).setStandard(standard);
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final currentStandard = ref.watch(currentStandardProvider);

    final displayName =
        (auth.fullName != null && auth.fullName!.trim().isNotEmpty)
        ? auth.fullName!.trim()
        : (auth.username ?? 'Ispettore');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      body: Stack(
        children: [
          // Background ambient light gradients
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD97706).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pill Header Superiore
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFD8E2DC)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D6A4F),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AUDIT MANAGER SUITE • BIOS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar e Saluto
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF2D6A4F,
                            ).withValues(alpha: 0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1B4332,
                              ).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName.substring(0, 1).toUpperCase()
                                : 'I',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Bentornato, $displayName',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F241D),
                          letterSpacing: -0.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seleziona il modulo operativo su cui desideri lavorare oggi.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 38),

                      // Layout Cards Responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 640;

                          final sqnpiCard = _StandardCard(
                            standard: AuditStandard.sqnpi,
                            logoPath: 'assets/images/logo_sqnpi.webp',
                            title: 'SQNPI',
                            subtitle: 'Produzione Integrata',
                            normative:
                                'D.M. 4890/2014 • Disciplinari Regionali',
                            features: const [
                              'Checklist UEC & Marchio',
                              'Bilancio di Massa & Tracciabilità',
                              'Verifica Difesa Integrata',
                            ],
                            themeGradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
                            ),
                            isEnabled: auth.canAccessSqnpi,
                            isSelected: currentStandard == AuditStandard.sqnpi,
                            onTap: () => _chooseStandard(
                              context,
                              ref,
                              AuditStandard.sqnpi,
                            ),
                          );

                          final bioCard = _StandardCard(
                            standard: AuditStandard.bio,
                            logoPath: 'assets/images/logo_bios.webp',
                            title: 'BIO',
                            subtitle: 'Agricoltura Biologica',
                            normative: 'Reg. UE 2018/848 • D.Lgs. 148/2021',
                            features: const [
                              'Notifica & Periodo Conversione',
                              'Conformità Sementi & Suolo',
                              'Registro Trattamenti Consentiti',
                            ],
                            themeGradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E5631), Color(0xFF0F3D1F)],
                            ),
                            accentColor: const Color(0xFFD97706),
                            isEnabled: auth.canAccessBio,
                            isSelected: currentStandard == AuditStandard.bio,
                            onTap: () => _chooseStandard(
                              context,
                              ref,
                              AuditStandard.bio,
                            ),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: sqnpiCard),
                                const SizedBox(width: 24),
                                Expanded(child: bioCard),
                              ],
                            );
                          } else {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                sqnpiCard,
                                const SizedBox(height: 20),
                                bioCard,
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 40),

                      // Footer con info sessione e logout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (auth.inspectorCode != null &&
                              auth.inspectorCode!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Matr: ${auth.inspectorCode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          TextButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            label: const Text(
                              'Disconnetti account',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardCard extends StatefulWidget {
  final AuditStandard standard;
  final String logoPath;
  final String title;
  final String subtitle;
  final String normative;
  final List<String> features;
  final LinearGradient themeGradient;
  final Color? accentColor;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  const _StandardCard({
    required this.standard,
    required this.logoPath,
    required this.title,
    required this.subtitle,
    required this.normative,
    required this.features,
    required this.themeGradient,
    this.accentColor,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StandardCard> createState() => _StandardCardState();
}

class _StandardCardState extends State<_StandardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.themeGradient.colors.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          (_isHovered && widget.isEnabled) ? -4 : 0,
          0,
        ),
        child: Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.45,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            elevation: widget.isSelected ? 10 : (_isHovered ? 8 : 2),
            shadowColor: primaryColor.withValues(
              alpha: widget.isSelected ? 0.25 : 0.12,
            ),
            child: InkWell(
              onTap: widget.isEnabled ? widget.onTap : null,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.isSelected
                        ? primaryColor
                        : (_isHovered
                              ? primaryColor.withValues(alpha: 0.4)
                              : const Color(0xFFE2E8F0)),
                    width: widget.isSelected ? 2.5 : 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Logo & Badge di Stato
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contenitore del logo con sfondo morbido
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              widget.logoPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    widget.standard.icon,
                                    size: 34,
                                    color: primaryColor,
                                  ),
                            ),
                          ),
                        ),

                        // Badge Attivo / Disponibile
                        if (widget.isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Ultimo Attivo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (widget.isEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Disponibile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Titolo Standard & Subtitle
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.normative,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 18),

                    // Lista feature / punti chiave
                    ...widget.features.map(
                      (feat) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 12,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feat,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pulsante CTA
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: widget.isEnabled
                            ? widget.themeGradient
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade500,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: widget.isEnabled
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isEnabled ? widget.onTap : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isEnabled
                                      ? 'Accedi al Modulo ${widget.title}'
                                      : 'Modulo non abilitato',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (widget.isEnabled) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
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
  }
}
