import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/widgets/sync_log_dialog.dart';

class CompanyDisplayInfo {
  final String cuaa;
  final String ragioneSociale;
  final String indirizzo;
  final String comune;
  final String provincia;
  final String cap;
  final String email;
  final String telefono;
  final double? latitude;
  final double? longitude;
  final List<VisitWithCompany> visits;

  CompanyDisplayInfo({
    required this.cuaa,
    required this.ragioneSociale,
    required this.indirizzo,
    required this.comune,
    required this.provincia,
    required this.cap,
    required this.email,
    required this.telefono,
    this.latitude,
    this.longitude,
    required this.visits,
  });

  int get totalVisits => visits.length;
  int get completedVisits => visits.where((v) => v.visit.status >= 2).length;
  int get inProgressVisits => visits.where((v) => v.visit.status == 1).length;
}

class AdminCompaniesPage extends ConsumerStatefulWidget {
  const AdminCompaniesPage({super.key});

  @override
  ConsumerState<AdminCompaniesPage> createState() => _AdminCompaniesPageState();
}

class _AdminCompaniesPageState extends ConsumerState<AdminCompaniesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSyncing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final logs = await ref
          .read(auditsRepositoryProvider)
          .syncWithCloud('admin', isAdmin: true);
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(visitsWithCompanyProvider);

      showDialog(
        context: context,
        builder: (ctx) => SyncLogDialog(logs: logs),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore sincronizzazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showCompanyDetails(CompanyDisplayInfo company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompanyDetailsSheet(company: company),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(visitsWithCompanyProvider);
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ANAGRAFICA AZIENDE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'Aziende Agricole Biosfera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _handleSync,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sincronizza da Biosfera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (allVisits) {
          return StreamBuilder<List<MasterCompany>>(
            stream: db.select(db.masterCompanies).watch(),
            builder: (context, snapshot) {
              final masterCompanies = snapshot.data ?? [];
              final Map<String, CompanyDisplayInfo> companyMap = {};

              // 1. Popola da MasterCompanies (se presenti in DB locale)
              for (final mc in masterCompanies) {
                final key = mc.cuaa.toLowerCase().trim();
                final companyVisits = allVisits.where((v) {
                  return v.company.cuaa.toLowerCase().trim() == key ||
                      v.visit.companyName.toLowerCase().contains(
                        mc.ragioneSociale.toLowerCase(),
                      );
                }).toList();

                companyMap[key] = CompanyDisplayInfo(
                  cuaa: mc.cuaa,
                  ragioneSociale: mc.ragioneSociale,
                  indirizzo: mc.indirizzo,
                  comune: mc.comune,
                  provincia: mc.provincia,
                  cap: mc.cap,
                  email: mc.email,
                  telefono: mc.telefono,
                  latitude: mc.latitude,
                  longitude: mc.longitude,
                  visits: companyVisits,
                );
              }

              // 2. Estrarre aziende direttamente dalle visite sincronizzate da Biosfera
              for (final v in allVisits) {
                final c = v.company;
                final rawCuaa = c.cuaa.trim();
                final rawName =
                    (c.ragioneSociale.isNotEmpty
                            ? c.ragioneSociale
                            : v.visit.companyName)
                        .trim();

                if (rawCuaa.isEmpty && rawName.isEmpty) continue;

                final key = (rawCuaa.isNotEmpty ? rawCuaa : rawName)
                    .toLowerCase();

                if (!companyMap.containsKey(key)) {
                  final companyVisits = allVisits.where((vis) {
                    final vc = vis.company;
                    return vc.cuaa.toLowerCase().trim() == key ||
                        vis.visit.companyName.toLowerCase().trim() ==
                            rawName.toLowerCase();
                  }).toList();

                  companyMap[key] = CompanyDisplayInfo(
                    cuaa: rawCuaa.isNotEmpty ? rawCuaa : 'N/D',
                    ragioneSociale: rawName.isNotEmpty
                        ? rawName
                        : 'Azienda senza nome',
                    indirizzo: c.indirizzo,
                    comune: c.comune,
                    provincia: c.provincia,
                    cap: c.cap,
                    email: c.email,
                    telefono: c.telefono,
                    latitude: c.latitude,
                    longitude: c.longitude,
                    visits: companyVisits,
                  );
                }
              }

              final companiesList = companyMap.values.where((comp) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return comp.ragioneSociale.toLowerCase().contains(q) ||
                    comp.cuaa.toLowerCase().contains(q) ||
                    comp.comune.toLowerCase().contains(q);
              }).toList();

              final topPadding = MediaQuery.of(context).size.width < 600
                  ? 120.0
                  : 130.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra Ricerca e Statistiche Aziendali
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText:
                                  'Cerca azienda per ragione sociale, CUAA o comune...',
                              hintStyle: TextStyle(
                                color: Colors.blueGrey.shade300,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF1A237E),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.shade100,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.shade100,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A237E),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _SummaryBadge(
                                label: 'AZIENDE CENSITE',
                                count: companiesList.length.toString(),
                                color: const Color(0xFF1A237E),
                                icon: Icons.business_rounded,
                              ),
                              const SizedBox(width: 12),
                              _SummaryBadge(
                                label: 'VISITE REGISTRATE',
                                count: allVisits.length.toString(),
                                color: const Color(0xFF10B981),
                                icon: Icons.domain_verification_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (companiesList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.domain_disabled_rounded,
                              size: 56,
                              color: Colors.blueGrey.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Nessuna azienda trovata per "$_searchQuery"'
                                  : 'Nessuna azienda registrata o sincronizzata',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premi "Sincronizza da Biosfera" in alto per scaricare le aziende e le visite aggiornate.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 2 : 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 180,
                                ),
                            itemCount: companiesList.length,
                            itemBuilder: (context, index) {
                              final comp = companiesList[index];
                              return _CompanyCard(
                                company: comp,
                                onTap: () => _showCompanyDetails(comp),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final CompanyDisplayInfo company;
  final VoidCallback onTap;

  const _CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locationText = [
      company.comune,
      company.provincia,
    ].where((s) => s.isNotEmpty).join(' (');
    final formattedLocation = locationText.contains('(')
        ? '$locationText)'
        : locationText;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.agriculture_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.ragioneSociale,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.blueGrey.shade300,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedLocation.isEmpty
                                      ? 'Ubicazione non specificata'
                                      : formattedLocation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        company.cuaa.isEmpty ? 'N/D' : company.cuaa,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _StatChip(
                          label: 'Visite',
                          value: '${company.totalVisits}',
                          color: const Color(0xFF1A237E),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Concluse',
                          value: '${company.completedVisits}',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'In Corso',
                          value: '${company.inProgressVisits}',
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyDetailsSheet extends ConsumerWidget {
  final CompanyDisplayInfo company;

  const _CompanyDetailsSheet({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.ragioneSociale,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'CUAA: ${company.cuaa.isEmpty ? 'N/D' : company.cuaa}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (company.indirizzo.isNotEmpty || company.comune.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade50),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF1A237E),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${company.indirizzo} ${company.comune} (${company.provincia}) ${company.cap}'
                          .trim(),
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
          const SizedBox(height: 24),
          Text(
            'Storico Ispezioni (${company.visits.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: company.visits.isEmpty
                ? Center(
                    child: Text(
                      'Nessuna ispezione registrata per questa azienda.',
                      style: TextStyle(color: Colors.blueGrey.shade400),
                    ),
                  )
                : ListView.builder(
                    itemCount: company.visits.length,
                    itemBuilder: (context, index) {
                      final v = company.visits[index];
                      final date = DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(v.visit.scheduledAt);
                      final statusColor = v.visit.status >= 2
                          ? const Color(0xFF10B981)
                          : (v.visit.status == 1
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFF59E0B));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blueGrey.shade50),
                        ),
                        child: ListTile(
                          title: Text(
                            v.visit.crop,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Ispettore: ${v.visit.inspectorName.isEmpty ? 'Non assegnato' : v.visit.inspectorName} • $date',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Elimina dati salvati su Supabase',
                                icon: const Icon(
                                  Icons.cloud_off_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _confirmDeleteVisitCloud(
                                    context,
                                    ref,
                                    visitId: v.visit.id,
                                    cropName: v.visit.crop,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                v.visit.status >= 2
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                color: statusColor,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitWorkspacePage(
                                  visitId: v.visit.id,
                                  forceReadOnly: false,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteVisitCloud(
  BuildContext context,
  WidgetRef ref, {
  required String visitId,
  required String cropName,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Elimina Dati Supabase',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sei sicuro di voler eliminare i dati salvati su Supabase per l\'ispezione "$cropName"?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Questa operazione rimuoverà la visita e i relativi dati salvati nel Cloud Supabase. Puoi scegliere se rimuoverla solo dal Cloud o anche dal dispositivo locale.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.cloud_off_rounded, size: 18),
          label: const Text('Elimina solo da Supabase'),
          onPressed: () => Navigator.pop(ctx, 'cloud_only'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: const Text('Elimina Cloud + Locale'),
          onPressed: () => Navigator.pop(ctx, 'cloud_and_local'),
        ),
      ],
    ),
  );

  if (result == null) return;

  try {
    final repo = ref.read(auditsRepositoryProvider);
    final db = ref.read(appDatabaseProvider);

    if (result == 'cloud_only' || result == 'cloud_and_local') {
      await repo.deleteVisitFromCloud(visitId);
    }

    if (result == 'cloud_and_local') {
      await db.deleteVisit(visitId);
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'cloud_only'
                ? 'Dati dell\'ispezione eliminati con successo da Supabase.'
                : 'Ispezione eliminata con successo da Supabase e dal dispositivo locale.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'eliminazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
