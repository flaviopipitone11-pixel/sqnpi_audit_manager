import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/standard_switcher_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../audits/presentation/navigation_providers.dart';

class BioHomePage extends ConsumerStatefulWidget {
  const BioHomePage({super.key});

  @override
  ConsumerState<BioHomePage> createState() => _BioHomePageState();
}

class _BioHomePageState extends ConsumerState<BioHomePage> {
  String _selectedCategoryFilter = 'Tutte';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final displayName =
        (auth.fullName != null && auth.fullName!.trim().isNotEmpty)
        ? auth.fullName!.trim()
        : (auth.username ?? 'Ispettore');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: CustomScrollView(
        slivers: [
          // AppBar con tema BIO
          _buildSliverAppBar(context, displayName),

          // Contenuto Dashboard
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avviso di integrazione Biosfera BIO in corso
                      _buildBiosferaIntegrationNotice(),
                      const SizedBox(height: 24),

                      // KPI Biologico
                      _buildBioKpiGrid(),
                      const SizedBox(height: 32),

                      // Filtri Tipologia Controllo
                      _buildCategoryFilters(),
                      const SizedBox(height: 20),

                      // Header sezione ispezioni
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ispezioni Biologico Assegnate',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F241D),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pianificazione controlli Reg. (UE) 2018/848',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(homeNavigationProvider.notifier).state =
                                  1;
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('Vedi tutte'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E5631),
                              side: const BorderSide(color: Color(0xFF1E5631)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista delle ispezioni BIO
                      _buildSampleBioVisitsList(context),

                      const SizedBox(height: 32),

                      // Box Campionamenti & Monitoraggio Residui
                      _buildSamplingSection(),

                      const SizedBox(height: 40),
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

  Widget _buildSliverAppBar(BuildContext context, String displayName) {
    const headerGreenStart = Color(0xFF1E5631);
    const headerGreenEnd = Color(0xFF0F3D1F);

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: headerGreenStart,
      surfaceTintColor: Colors.transparent,
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: StandardSwitcherBadge(isDarkBackground: true),
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: 'Impostazioni',
        ),
        IconButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'Logout',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerGreenStart, headerGreenEnd],
                ),
              ),
            ),
            // Pattern decorativo ambient
            Positioned(
              right: -40,
              top: -30,
              child: Icon(
                Icons.spa_rounded,
                size: 220,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, size: 14, color: Color(0xFFFDE68A)),
                        SizedBox(width: 6),
                        Text(
                          'MODULO AGRICOLTURA BIOLOGICA • REG. (UE) 2018/848',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bentornato, $displayName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pianificazione e monitoraggio ispezioni di conformità biologica',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiosferaIntegrationNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Giallo ambra pastello
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sync_outlined,
              size: 20,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integrazione Flusso Cloud BIO in Configurazione',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Il backend Biosfera sta predisponendo le API specifiche per il caricamento automatico delle visite BIO. '
                  'Attualmente la dashboard mostra i dati e le ispezioni predisposte in modalità locale/anteprima con tutte le funzioni operative.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: const Color(0xFF92400E).withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final count = isWide ? 4 : 2;

        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 1.4 : 1.3,
          children: [
            _buildKpiCard(
              title: 'Ispezioni BIO',
              value: '6',
              subtitle: '4 Ordinarie • 2 Sorpresa',
              icon: Icons.assignment_turned_in_outlined,
              color: const Color(0xFF1E5631),
            ),
            _buildKpiCard(
              title: 'Campionamenti',
              value: '2',
              subtitle: '1 Fogliare • 1 Terreno',
              icon: Icons.science_outlined,
              color: const Color(0xFF0284C7),
            ),
            _buildKpiCard(
              title: 'Superficie Controllata',
              value: '155 ha',
              subtitle: '120 ha BIO • 35 ha Conv.',
              icon: Icons.landscape_outlined,
              color: const Color(0xFF059669),
            ),
            _buildKpiCard(
              title: 'Rilievi & NC',
              value: '1',
              subtitle: '1 Inosservanza • 0 Irreg.',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFD97706),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'Tutte',
      'Ordinarie Annuali',
      'A Sorpresa (10%)',
      'Campionamento',
      'In Conversione',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoryFilter = cat);
                }
              },
              selectedColor: const Color(0xFF1E5631),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1E5631)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSampleBioVisitsList(BuildContext context) {
    final sampleBioVisits = [
      _BioVisitItem(
        companyName: 'Azienda Agricola Poggio Bio',
        notifica: 'BIO-2024-0042',
        cuaa: 'PGGBIO84M12H501Z',
        coltura: 'Vite da vino (Docg) • Olivo',
        tipoIspezione: 'Ordinaria Annuale',
        statoConversione: 'Biologico Certificato',
        date: DateTime.now().add(const Duration(days: 1)),
        statusText: 'Pianificata',
        statusColor: const Color(0xFF0284C7),
      ),
      _BioVisitItem(
        companyName: 'Tenuta Terra & Sole Bio',
        notifica: 'BIO-2023-1189',
        cuaa: 'TRRSLE79A01F205W',
        coltura: 'Grano Duro • Leguminose',
        tipoIspezione: 'A Sorpresa (10%)',
        statoConversione: 'In Conversione (2° Anno)',
        date: DateTime.now(),
        statusText: 'In Corso',
        statusColor: const Color(0xFFEAB308),
      ),
      _BioVisitItem(
        companyName: 'Cooperativa Agrumi Bio Sicilia',
        notifica: 'BIO-2022-0855',
        cuaa: 'CPAGRB90C15G273K',
        coltura: 'Arance Bionde • Limoni Bio',
        tipoIspezione: 'Campionamento Residui',
        statoConversione: 'Biologico Certificato',
        date: DateTime.now().subtract(const Duration(days: 2)),
        statusText: 'Completata',
        statusColor: const Color(0xFF10B981),
      ),
    ];

    return Column(
      children: sampleBioVisits.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icona standard BIO
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5631).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: Color(0xFF1E5631),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Dati Azienda e Ispezione
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: item.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notifica: ${item.notifica} • CUAA: ${item.cuaa}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Badge informativi BIO
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(
                            Icons.grass_rounded,
                            item.coltura,
                            const Color(0xFF1E5631),
                          ),
                          _buildInfoChip(
                            Icons.verified_outlined,
                            item.statoConversione,
                            const Color(0xFFD97706),
                          ),
                          _buildInfoChip(
                            Icons.calendar_today_outlined,
                            DateFormat('dd/MM/yyyy').format(item.date),
                            const Color(0xFF475569),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSamplingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.biotech_outlined, color: Color(0xFF1E5631), size: 22),
              SizedBox(width: 10),
              Text(
                'Registro Prelievi & Campioni Ufficiali BIO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tracciabilità dei campioni prelevati sul campo per l\'analisi di residui da laboratorio accreditato (Reg. 2018/848).',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Color(0xFF0284C7)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campione N. BIO-SMP-2026/01 - Foglie Vite (Az. Poggio Bio)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'In attesa di referto da Laboratorio Agrochimico • Spedito il 18/09/2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BioVisitItem {
  final String companyName;
  final String notifica;
  final String cuaa;
  final String coltura;
  final String tipoIspezione;
  final String statoConversione;
  final DateTime date;
  final String statusText;
  final Color statusColor;

  _BioVisitItem({
    required this.companyName,
    required this.notifica,
    required this.cuaa,
    required this.coltura,
    required this.tipoIspezione,
    required this.statoConversione,
    required this.date,
    required this.statusText,
    required this.statusColor,
  });
}
