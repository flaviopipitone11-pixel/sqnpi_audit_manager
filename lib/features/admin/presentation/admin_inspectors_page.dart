import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/widgets/sync_log_dialog.dart';

class InspectorInfo {
  final String name;
  final String email;
  final String code;
  final List<VisitWithCompany> visits;

  InspectorInfo({
    required this.name,
    required this.email,
    required this.code,
    required this.visits,
  });

  int get totalVisits => visits.length;
  int get completedVisits => visits.where((v) => v.visit.status >= 2).length;
  int get inProgressVisits => visits.where((v) => v.visit.status == 1).length;
  int get plannedVisits => visits.where((v) => v.visit.status == 0).length;
}

class AdminInspectorsPage extends ConsumerStatefulWidget {
  const AdminInspectorsPage({super.key});

  @override
  ConsumerState<AdminInspectorsPage> createState() =>
      _AdminInspectorsPageState();
}

class _AdminInspectorsPageState extends ConsumerState<AdminInspectorsPage> {
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

  void _showInspectorDetails(InspectorInfo inspector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InspectorDetailsSheet(inspector: inspector),
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
                      Icons.badge_rounded,
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
                          'ANAGRAFICA ISPETTORI',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'Collaboratori Biosfera',
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
          return StreamBuilder<List<Inspector>>(
            stream: db.select(db.inspectors).watch(),
            builder: (context, snapshot) {
              final dbInspectors = snapshot.data ?? [];
              final Map<String, InspectorInfo> inspectorMap = {};

              // 1. Popola dagli ispettori salvati in DB locale
              for (final isp in dbInspectors) {
                final name = isp.fullName.isNotEmpty
                    ? isp.fullName
                    : '${isp.firstName} ${isp.lastName}'.trim();
                final key = name.toLowerCase();

                final inspectorVisits = allVisits.where((v) {
                  final vName = v.visit.inspectorName.toLowerCase();
                  final vEmail = v.visit.inspectorEmail.toLowerCase();
                  return vName.contains(key) ||
                      vEmail.contains(isp.email.toLowerCase()) ||
                      key.contains(vName);
                }).toList();

                inspectorMap[key] = InspectorInfo(
                  name: name.isEmpty ? isp.email : name,
                  email: isp.email,
                  code: isp.inspectorCode.isNotEmpty
                      ? isp.inspectorCode
                      : 'ISP',
                  visits: inspectorVisits,
                );
              }

              // 2. Estrarre ispettori direttamente dalle visite sincronizzate da Biosfera
              for (final v in allVisits) {
                final rawName = v.visit.inspectorName.trim();
                final rawEmail = v.visit.inspectorEmail.trim();

                if (rawName.isEmpty && rawEmail.isEmpty) continue;

                final key = (rawName.isNotEmpty ? rawName : rawEmail)
                    .toLowerCase();

                if (!inspectorMap.containsKey(key)) {
                  final inspectorVisits = allVisits.where((vis) {
                    final vn = vis.visit.inspectorName.toLowerCase();
                    final ve = vis.visit.inspectorEmail.toLowerCase();
                    return vn == key ||
                        ve == key ||
                        (rawEmail.isNotEmpty && ve == rawEmail.toLowerCase());
                  }).toList();

                  // Estrarre codice tra parentesi se presente (es: "Cognome Nome (COD123)")
                  String code = 'BIOS';
                  String displayName = rawName.isNotEmpty ? rawName : rawEmail;

                  final match = RegExp(r'\((.*?)\)').firstMatch(rawName);
                  if (match != null) {
                    code = match.group(1) ?? 'BIOS';
                  }

                  inspectorMap[key] = InspectorInfo(
                    name: displayName,
                    email: rawEmail.isNotEmpty
                        ? rawEmail
                        : 'Censito su Biosfera',
                    code: code,
                    visits: inspectorVisits,
                  );
                }
              }

              final inspectorsList = inspectorMap.values.where((isp) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return isp.name.toLowerCase().contains(q) ||
                    isp.email.toLowerCase().contains(q) ||
                    isp.code.toLowerCase().contains(q);
              }).toList();

              final topPadding = MediaQuery.of(context).size.width < 600
                  ? 120.0
                  : 130.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra Ricerca e Statistiche Generali
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
                                  'Cerca ispettore per nome, email o codice...',
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
                                label: 'ISPETTORI ATTIVI',
                                count: inspectorsList.length.toString(),
                                color: const Color(0xFF1A237E),
                                icon: Icons.group_rounded,
                              ),
                              const SizedBox(width: 12),
                              _SummaryBadge(
                                label: 'TOTALE VISITE ASSEGNATE',
                                count: allVisits.length.toString(),
                                color: const Color(0xFF10B981),
                                icon: Icons.assignment_turned_in_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (inspectorsList.isEmpty)
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
                              Icons.person_search_rounded,
                              size: 56,
                              color: Colors.blueGrey.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Nessun ispettore trovato per "$_searchQuery"'
                                  : 'Nessun ispettore registrato o sincronizzato',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premi "Sincronizza da Biosfera" in alto per scaricare l\'elenco aggiornato degli ispettori e delle visite.',
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
                            itemCount: inspectorsList.length,
                            itemBuilder: (context, index) {
                              final isp = inspectorsList[index];
                              return _InspectorCard(
                                inspector: isp,
                                onTap: () => _showInspectorDetails(isp),
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

class _InspectorCard extends StatelessWidget {
  final InspectorInfo inspector;
  final VoidCallback onTap;

  const _InspectorCard({required this.inspector, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = inspector.name.isNotEmpty
        ? inspector.name.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    final completionRatio = inspector.totalVisits > 0
        ? inspector.completedVisits / inspector.totalVisits
        : 0.0;

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
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspector.name,
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
                          Text(
                            inspector.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        inspector.code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ],
                ),

                // Progresso Visite
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Avanzamento Visite',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                        Text(
                          '${(completionRatio * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: completionRatio,
                        minHeight: 6,
                        backgroundColor: Colors.blueGrey.shade50,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),

                // Mini Statistiche e Tasto Dettagli
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _StatChip(
                          label: 'Totali',
                          value: '${inspector.totalVisits}',
                          color: const Color(0xFF1A237E),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Concluse',
                          value: '${inspector.completedVisits}',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'In Corso',
                          value: '${inspector.inProgressVisits}',
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

class _InspectorDetailsSheet extends StatelessWidget {
  final InspectorInfo inspector;

  const _InspectorDetailsSheet({required this.inspector});

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                child: Text(
                  inspector.name.isNotEmpty
                      ? inspector.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspector.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      inspector.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Visite Assegnate (${inspector.visits.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: inspector.visits.isEmpty
                ? Center(
                    child: Text(
                      'Nessuna visita attualmente assegnata a questo ispettore.',
                      style: TextStyle(color: Colors.blueGrey.shade400),
                    ),
                  )
                : ListView.builder(
                    itemCount: inspector.visits.length,
                    itemBuilder: (context, index) {
                      final v = inspector.visits[index];
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
                            v.visit.companyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text('${v.visit.crop} • $date'),
                          trailing: Icon(
                            v.visit.status >= 2
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            color: statusColor,
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
