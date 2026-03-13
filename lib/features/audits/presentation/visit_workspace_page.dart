import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';

import 'checklist_page.dart';
import 'nc_page.dart';
import 'attachments_page.dart';
import 'report_page.dart';
import '../application/report_provider.dart';
import '../application/audit_stats_provider.dart';
import '../application/management_sync_service.dart';
import 'widgets/signature_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../admin/application/activity_logger.dart';

// Provider per il conteggio allegati (badge nella NavigationRail)
final _attachmentCountProvider = StreamProvider.family<int, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAttachmentsByVisitId(visitId).map((list) => list.length);
});

final visitByIdProvider = StreamProvider.family<Visit?, String>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisitById(id);
});

final companyByVisitIdProvider = StreamProvider.family<VisitCompany?, String>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCompanyByVisitId(id);
});

final uecsByVisitIdProvider = StreamProvider.family<List<VisitUec>, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUecsByVisitId(visitId);
});

final lotsByUecIdProvider = StreamProvider.family<List<VisitLot>, String>((
  ref,
  uecId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLotsByUecId(uecId);
});

final massBalanceByVisitIdProvider =
    StreamProvider.family<MassBalanceRecord?, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalanceByVisitId(id);
    });

final closingByVisitIdProvider = StreamProvider.family<VisitClosing?, String>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchClosingByVisitId(id);
});

final samplesByVisitIdProvider =
    StreamProvider.family<List<VisitSample>, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchSamplesByVisitId(id);
    });

final ncCountProvider = StreamProvider.family<int, String>((ref, visitId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchNcCountByVisitId(visitId);
});

class VisitWorkspacePage extends ConsumerStatefulWidget {
  const VisitWorkspacePage({
    super.key,
    required this.visitId,
    this.forceReadOnly = false,
  });

  final String visitId;
  final bool forceReadOnly;

  @override
  ConsumerState<VisitWorkspacePage> createState() => _VisitWorkspacePageState();
}

class _VisitWorkspacePageState extends ConsumerState<VisitWorkspacePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final visitAsync = ref.watch(visitByIdProvider(widget.visitId));

    return Scaffold(
      appBar: AppBar(
        title: visitAsync.when(
          data: (v) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v?.companyName ?? 'Visita'),
              if (v != null)
                Text(
                  'ID: ${v.id}  •  ${v.crop}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          loading: () => const Text('Caricamento...'),
          error: (error, stackTrace) => const Text('Errore'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer(
              builder: (context, ref, _) {
                final outcomeAsync = ref.watch(
                  visitOutcomeSummaryProvider(widget.visitId),
                );

                return outcomeAsync.when(
                  loading: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, st) => const Badge(label: Text('N/D')),
                  data: (s) {
                    final String label;
                    final Color color;

                    switch (s.outcome) {
                      case VisitOutcome.conforme:
                        label = 'Conforme';
                        color = const Color(0xFF2E7D32);
                        break;
                      case VisitOutcome.nonConformeUec:
                        label = 'NC (UEC)';
                        color = const Color(0xFFC62828);
                        break;
                      case VisitOutcome.nonConformeOperatore:
                        label = 'NC (Operatore)';
                        color = const Color(0xFFAD1457);
                        break;
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          tooltip: 'Azioni Visita',
                          onSelected: (value) async {
                            switch (value) {
                              case 'pdf':
                                await ref
                                    .read(reportServiceProvider)
                                    .generateAndShareReport(widget.visitId);
                                break;
                              case 'pdf_checklist':
                                await ref
                                    .read(reportServiceProvider)
                                    .generateAndShareChecklistReport(
                                      widget.visitId,
                                    );
                                break;
                              case 'reset':
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Aggiorna Checklist?'),
                                    content: const Text(
                                      'Vuoi forzare il ricaricamento dei dati dall\'Excel? Tutte le risposte attuali verranno mantenute.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Sì, aggiorna'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    final db = ref.read(appDatabaseProvider);
                                    await db.resetChecklistAndReimport();
                                    ref.invalidate(seedDatabaseProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Checklist ricaricata.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Errore: $e')),
                                      );
                                    }
                                  }
                                }
                                break;
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Esporta Verbale PDF'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'pdf_checklist',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.checklist_rtl_rounded,
                                    size: 20,
                                    color: Colors.indigo,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Esporta Checklist Completa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Sincronizza/Reset Checklist'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: visitAsync.when(
        data: (visit) {
          if (visit == null) {
            return const Center(child: Text('Visita non trovata.'));
          }

          final isReadOnly = widget.forceReadOnly || visit.status >= 2;

          final List<({NavigationRailDestination dest, Widget page})>
          navItems = [
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Riepilogo'),
              ),
              page: _RiepilogoSection(visit: visit, isReadOnly: isReadOnly),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Scopo Controllo'),
              ),
              page: _ScopoControlloSection(
                visit: visit,
                isReadOnly: isReadOnly,
              ),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Azienda'),
              ),
              page: _AziendaSection(
                visitId: visit.id,
                defaultCompanyName: visit.companyName,
                isReadOnly: isReadOnly,
              ),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.agriculture_outlined),
                selectedIcon: Icon(Icons.agriculture),
                label: Text('UEC/Lotti'),
              ),
              page: _UecLottiSection(
                visitId: visit.id,
                defaultColtura: visit.crop,
                isReadOnly: isReadOnly,
              ),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: Text('Checklist'),
              ),
              page: ChecklistPage(visitId: visit.id, isReadOnly: isReadOnly),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning),
                label: Text('NC'),
              ),
              page: NcPage(visitId: visit.id, isReadOnly: isReadOnly),
            ),
            if (visit.visitType.contains('CAMPIONAMENTO'))
              (
                dest: const NavigationRailDestination(
                  icon: Icon(Icons.science_outlined),
                  selectedIcon: Icon(Icons.science),
                  label: Text('Campionamento'),
                ),
                page: _CampionamentoSection(
                  visitId: visit.id,
                  isReadOnly: isReadOnly,
                ),
              ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.calculate_outlined),
                selectedIcon: Icon(Icons.calculate),
                label: Text('Bilancio'),
              ),
              page: _MassBalanceSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
            (
              dest: NavigationRailDestination(
                icon: _AttachmentBadge(
                  visitId: widget.visitId,
                  isSelected: false,
                ),
                selectedIcon: _AttachmentBadge(
                  visitId: widget.visitId,
                  isSelected: true,
                ),
                label: const Text('Allegati'),
              ),
              page: AttachmentsPage(visitId: visit.id, isReadOnly: isReadOnly),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.draw_outlined),
                selectedIcon: Icon(Icons.draw),
                label: Text('Firme'),
              ),
              page: _SignatureSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: Text('Durata'),
              ),
              page: _DurataSection(visit: visit, isReadOnly: isReadOnly),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.gavel_outlined),
                selectedIcon: Icon(Icons.gavel),
                label: Text('Chiusura'),
              ),
              page: _ChiusuraSection(visitId: visit.id, isReadOnly: isReadOnly),
            ),
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.picture_as_pdf_outlined),
                selectedIcon: Icon(Icons.picture_as_pdf),
                label: Text('Esporta PDF'),
              ),
              page: ReportPage(visitId: visit.id),
            ),
          ];

          // Ensure selected index is within bounds if tabs change
          if (_selectedIndex >= navItems.length) {
            _selectedIndex = 0;
          }

          return Row(
            children: [
              Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    // Dynamic Header for Visit
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VERBALE ISPEZIONE',
                              style: TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            visit.companyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visit.crop,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 20, endIndent: 20),
                    const SizedBox(height: 12),
                    // Navigation
                    Expanded(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (i) =>
                            setState(() => _selectedIndex = i),
                        labelType: NavigationRailLabelType.none,
                        extended: true,
                        minExtendedWidth: 260,
                        backgroundColor: Colors.transparent,
                        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                        selectedLabelTextStyle: const TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        destinations: navItems.map((e) => e.dest).toList(),
                      ),
                    ),
                    const Divider(indent: 20, endIndent: 20),
                    // Quick Action Exit
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                          ),
                          label: const Text('Chiudi Workspace'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8F9FA),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: navItems.map((e) => e.page).toList(),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}

class _AttachmentBadge extends ConsumerWidget {
  const _AttachmentBadge({required this.visitId, required this.isSelected});
  final String visitId;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_attachmentCountProvider(visitId)).valueOrNull ?? 0;
    final icon = isSelected ? Icons.attach_file : Icons.attach_file_outlined;
    return Badge(
      label: count > 0 ? Text('$count') : null,
      isLabelVisible: count > 0,
      child: Icon(icon),
    );
  }
}

class _ScopoControlloSection extends ConsumerStatefulWidget {
  const _ScopoControlloSection({
    required this.visit,
    required this.isReadOnly,
  });
  final Visit visit;
  final bool isReadOnly;

  @override
  ConsumerState<_ScopoControlloSection> createState() =>
      _ScopoControlloSectionState();
}

class _ScopoControlloSectionState extends ConsumerState<_ScopoControlloSection> {
  final _natureController = TextEditingController();
  final _processesController = TextEditingController();
  bool _labelDraft = false;
  bool _loaded = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _natureController.dispose();
    _processesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadData(VisitCompany? company) {
    if (_loaded || company == null) return;
    _natureController.text = company.marchioNature;
    _processesController.text = company.marchioProcesses;
    _labelDraft = company.marchioLabelDraft;
    _loaded = true;
  }

  void _onChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveMarchioDetails();
    });
  }

  Future<void> _saveMarchioDetails() async {
    final db = ref.read(appDatabaseProvider);
    await db.upsertCompany(
      visitId: widget.visit.id,
      marchioNature: _natureController.text,
      marchioProcesses: _processesController.text,
      marchioLabelDraft: _labelDraft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyByVisitIdProvider(widget.visit.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: companyAsync.when(
        data: (company) {
          _loadData(company);
          final isMarchioSelected = widget.visit.visitType.contains('MARCHIO');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                title: 'Scopo del Controllo',
                subtitle:
                    'Definisci la tipologia di verifica prevista (M904 Rev. 08)',
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildTypeCard(
                    context,
                    ref,
                    title: 'ACA',
                    description: 'Verifica conformità alle norme ACA (SQNPI)',
                    icon: Icons.gavel_outlined,
                    isSelected: widget.visit.visitType.contains('ACA'),
                    isReadOnly: widget.isReadOnly,
                  ),
                  _buildTypeCard(
                    context,
                    ref,
                    title: 'MARCHIO',
                    description: 'Verifica conformità all\'uso del Marchio',
                    icon: Icons.verified_outlined,
                    isSelected: isMarchioSelected,
                    isReadOnly: widget.isReadOnly,
                  ),
                  _buildTypeCard(
                    context,
                    ref,
                    title: 'CAMPIONAMENTO',
                    description: 'Ispezione finalizzata al prelievo di campioni',
                    icon: Icons.science_outlined,
                    isSelected: widget.visit.visitType.contains('CAMPIONAMENTO'),
                    isReadOnly: widget.isReadOnly,
                  ),
                  _buildTypeCard(
                    context,
                    ref,
                    title: 'ALTRO',
                    description: 'Tutti i punti della checklist',
                    icon: Icons.more_horiz_rounded,
                    isSelected: widget.visit.visitType.contains('ALTRO'),
                    isReadOnly: widget.isReadOnly,
                  ),
                ],
              ),
              if (isMarchioSelected) ...[
                const SizedBox(height: 40),
                _buildMarchioDetailsCard(),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'La selezione dello scopo influenza quali sezioni della checklist saranno abilitate per la compilazione.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore caricamento dati: $e')),
      ),
    );
  }

  Widget _buildMarchioDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nel caso di richiesta certificazione per uso del MARCHIO indicare:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _natureController,
              label: 'Natura prodotto (freschi, trasformati...)',
              hint: 'Es. Uva da tavola, Vino, Olio...',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _processesController,
              label:
                  'Processi di produzione effettuati (vinificazione, imbottigliamento, etichettatura o calibratura, cernita, confezionamento...)',
              hint: 'Descrivi i processi...',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Acquisita bozza etichetta',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 24),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Si'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('No'),
                      icon: Icon(Icons.cancel_outlined),
                    ),
                  ],
                  selected: {_labelDraft},
                  onSelectionChanged: widget.isReadOnly
                      ? null
                      : (val) {
                          setState(() => _labelDraft = val.first);
                          _saveMarchioDetails();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: widget.isReadOnly,
      maxLines: maxLines,
      onChanged: (_) => _onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required bool isReadOnly,
  }) {
    return InkWell(
      onTap: isReadOnly
          ? null
          : () async {
              final db = ref.read(appDatabaseProvider);
              final types = widget.visit.visitType
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList();

              if (types.contains(title)) {
                // Se stiamo cercando di deselezionare CAMPIONAMENTO ma c'è MARCHIO, impediamolo
                if (title == 'CAMPIONAMENTO' && types.contains('MARCHIO')) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Il Campionamento è obbligatorio quando lo scopo include il Marchio.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                types.remove(title);
              } else {
                types.add(title);
                // Se selezioniamo MARCHIO, forziamo CAMPIONAMENTO
                if (title == 'MARCHIO' && !types.contains('CAMPIONAMENTO')) {
                  types.add('CAMPIONAMENTO');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Il Campionamento è stato aggiunto automaticamente in quanto obbligatorio per il Marchio.',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              }

              types.sort();
              final newVisitType = types.isEmpty ? 'ACA' : types.join(',');

              await db.upsertVisit(
                id: widget.visit.id,
                scheduledAt: widget.visit.scheduledAt,
                companyName: widget.visit.companyName,
                crop: widget.visit.crop,
                status: VisitStatus.values[widget.visit.status],
                visitType: newVisitType,
                durationHours: widget.visit.durationHours,
                plannedDurationHours: widget.visit.plannedDurationHours,
                durationJustification: widget.visit.durationJustification,
                inspectorName: widget.visit.inspectorName,
                companionName: widget.visit.companionName,
                representativeName: widget.visit.representativeName,
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue.shade900 : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiepilogoSection extends ConsumerStatefulWidget {
  const _RiepilogoSection({required this.visit, required this.isReadOnly});
  final Visit visit;
  final bool isReadOnly;

  @override
  ConsumerState<_RiepilogoSection> createState() => _RiepilogoSectionState();
}

class _RiepilogoSectionState extends ConsumerState<_RiepilogoSection> {
  late final TextEditingController _inspectorController;
  late final TextEditingController _companionController;
  late final TextEditingController _representativeController;

  @override
  void initState() {
    super.initState();
    _inspectorController = TextEditingController(text: widget.visit.inspectorName);
    _companionController = TextEditingController(text: widget.visit.companionName);
    _representativeController = TextEditingController(text: widget.visit.representativeName);

    // Se l'ispettore è vuoto, proviamo a caricarlo dall'utente loggato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inspectorController.text.isEmpty) {
        final auth = ref.read(authControllerProvider);
        if (auth.username != null) {
          setState(() {
            _inspectorController.text = auth.username!;
          });
          _saveNames();
        }
      }
    });
  }

  @override
  void dispose() {
    _inspectorController.dispose();
    _companionController.dispose();
    _representativeController.dispose();
    super.dispose();
  }

  Future<void> _saveNames() async {
    final db = ref.read(appDatabaseProvider);
    await db.upsertVisit(
      id: widget.visit.id,
      scheduledAt: widget.visit.scheduledAt,
      companyName: widget.visit.companyName,
      crop: widget.visit.crop,
      status: VisitStatus.values[widget.visit.status],
      visitType: widget.visit.visitType,
      durationHours: widget.visit.durationHours,
      plannedDurationHours: widget.visit.plannedDurationHours,
      durationJustification: widget.visit.durationJustification,
      inspectorName: _inspectorController.text,
      companionName: _companionController.text,
      representativeName: _representativeController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.visit.scheduledAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final companyAsync = ref.watch(companyByVisitIdProvider(widget.visit.id));
    final company = companyAsync.valueOrNull;
    final submissionNumber =
        (company == null || company.submissionNumber.isEmpty)
        ? '-'
        : company.submissionNumber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riepilogo Visita',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _infoCard(
                context,
                title: 'Stato Visita',
                value: visitStatusLabel(widget.visit.status),
                icon: Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              _infoCard(
                context,
                title: 'Durata Verifica',
                value:
                    'Eff.: ${widget.visit.durationHours}h / Prog.: ${widget.visit.plannedDurationHours}h',
                subtitle:
                    '${(widget.visit.durationHours / 8).toStringAsFixed(1)} gg (Effettive)',
                icon: Icons.timer_outlined,
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 16),
              _infoCard(
                context,
                title: 'Scopo Controllo',
                value: widget.visit.visitType.replaceAll(',', ' + '),
                icon: Icons.assignment_outlined,
                color: Colors.orange.shade700,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoCard(
                context,
                title: 'Data',
                value: dateStr,
                icon: Icons.calendar_today,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 16),
              _infoCard(
                context,
                title: 'N. Domanda',
                value: submissionNumber,
                subtitle: 'Adesione SQNPI',
                icon: Icons.description_outlined,
                color: Colors.purple.shade700,
              ),
              // Spacer per mantenere l'allineamento se necessario o lasciare spazio vuoto
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          _DashboardProgress(visitId: widget.visit.id),
          const SizedBox(height: 24),
          _ValidationAlerts(uecId: widget.visit.id),
          const SizedBox(height: 24),

          // --- SOGGETTI PRESENTI ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, color: Colors.blueGrey.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Soggetti Presenti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _nameField(
                          'Ispettore',
                          _inspectorController,
                          Icons.badge_outlined,
                          'Nome dell\'ispettore',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _nameField(
                          'Affiancatore',
                          _companionController,
                          Icons.person_add_alt_1_outlined,
                          'Nome affiancatore (opzionale)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _nameField(
                    'Rappresentante Aziendale / Delegato',
                    _representativeController,
                    Icons.business_center_outlined,
                    'Nome del legale rappresentante o suo delegato',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dettagli Operazione',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Azienda', widget.visit.companyName, Icons.business),
                  const Divider(height: 32),
                  _detailRow('Coltura principale', widget.visit.crop, Icons.grass),
                  const Divider(height: 32),
                  _detailRow('ID Sistema', widget.visit.id, Icons.fingerprint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Usa il menu laterale per navigare tra le sezioni della visita e completare la checklist.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !widget.isReadOnly,
          onChanged: (_) => _saveNames(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: widget.isReadOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _durationSlider(
  BuildContext context,
  WidgetRef ref,
  Visit visit,
  bool isReadOnly,
) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Durata della verifica ispettiva',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Specifica la durata complessiva (1 giornata = 8 ore)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 14,
                        color: Colors.indigo.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Durata Stabilita dall\'Azienda: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${visit.plannedDurationHours} ore',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: visit.durationHours > visit.plannedDurationHours
                      ? Colors.orange.shade700
                      : Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${visit.durationHours} h / ${visit.plannedDurationHours} h (Prog.)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade600,
              inactiveTrackColor: Colors.teal.shade100,
              thumbColor: Colors.teal.shade600,
              overlayColor: Colors.teal.withValues(alpha: 0.1),
              valueIndicatorColor: Colors.teal.shade600,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: visit.durationHours.toDouble(),
              min: 0,
              max: 24,
              divisions: 24,
              label: '${visit.durationHours} ore',
              onChanged: isReadOnly
                  ? null
                  : (value) async {
                      final db = ref.read(appDatabaseProvider);
                      await db.upsertVisit(
                        id: visit.id,
                        scheduledAt: visit.scheduledAt,
                        companyName: visit.companyName,
                        crop: visit.crop,
                        status: VisitStatus.values[visit.status],
                        visitType: visit.visitType,
                        durationHours: value.toInt(),
                        plannedDurationHours: visit.plannedDurationHours,
                        representativeName: visit.representativeName,
                      );

                      final logger = ref.read(activityLoggerProvider);
                      await logger.log(
                        action: 'UPDATE_VISIT_DURATION',
                        description: 'Aggiornata durata visita ${visit.id} a ${value.toInt()} ore',
                        actor: visit.inspectorName.isNotEmpty ? visit.inspectorName : 'Ispettore',
                      );
                    },
            ),
          ),
          if (visit.durationHours > visit.plannedDurationHours) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Giustificativo Sforamento Ore',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 2,
                    readOnly: isReadOnly,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText:
                          'Inserisci il motivo per cui la visita ha richiesto più tempo del previsto...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller:
                        TextEditingController(text: visit.durationJustification)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: visit.durationJustification.length,
                            ),
                          ),
                    onSubmitted: (val) async {
                      final db = ref.read(appDatabaseProvider);
                      await db.upsertVisit(
                        id: visit.id,
                        scheduledAt: visit.scheduledAt,
                        companyName: visit.companyName,
                        crop: visit.crop,
                        status: VisitStatus.values[visit.status],
                        visitType: visit.visitType,
                        durationHours: visit.durationHours,
                        plannedDurationHours: visit.plannedDurationHours,
                        durationJustification: val.trim(),
                        inspectorName: visit.inspectorName,
                        companionName: visit.companionName,
                        representativeName: visit.representativeName,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0h',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Text(
                  '4h',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Text(
                  '8h (1gg)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12h',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Text(
                  '16h (2gg)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '24h',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

class _AziendaSection extends ConsumerStatefulWidget {
  const _AziendaSection({
    required this.visitId,
    required this.defaultCompanyName,
    required this.isReadOnly,
  });
  final String visitId;
  final String defaultCompanyName;
  final bool isReadOnly;

  @override
  ConsumerState<_AziendaSection> createState() => _AziendaSectionState();
}

class _DurataSection extends ConsumerWidget {
  const _DurataSection({required this.visit, required this.isReadOnly});

  final Visit visit;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durata Verifica',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In quest\'area è possibile indicare la durata effettiva della visita ispettiva.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _durationSlider(context, ref, visit, isReadOnly),
        ],
      ),
    );
  }
}

class _AziendaSectionState extends ConsumerState<_AziendaSection> {
  final _ragioneSociale = TextEditingController();
  final _cuaa = TextEditingController();
  final _piva = TextEditingController();
  final _indirizzo = TextEditingController();
  final _cap = TextEditingController();
  final _comune = TextEditingController();
  final _provincia = TextEditingController();
  final _referente = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _pec = TextEditingController();
  final _thirdPartyCert = TextEditingController(); // M904
  final _latitudeText = TextEditingController();
  final _longitudeText = TextEditingController();
  final _manipulationSiteAddress = TextEditingController();
  final _jointVisitDetails = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  double? _latitude;
  double? _longitude;

  bool _isNewOperator = false; // M904
  String _processingType = 'proprio'; // M904

  String? _peakPeriodFrom;
  bool _isJointVisit = false;

  @override
  void dispose() {
    _ragioneSociale.dispose();
    _cuaa.dispose();
    _piva.dispose();
    _indirizzo.dispose();
    _cap.dispose();
    _comune.dispose();
    _provincia.dispose();
    _referente.dispose();
    _telefono.dispose();
    _email.dispose();
    _pec.dispose();
    _thirdPartyCert.dispose();
    _latitudeText.dispose();
    _longitudeText.dispose();
    _manipulationSiteAddress.dispose();
    _jointVisitDetails.dispose();
    super.dispose();
  }

  void _fillIfNeeded(VisitCompany? c) {
    if (_loaded) return;
    _loaded = true;

    _ragioneSociale.text = (c?.ragioneSociale.isNotEmpty ?? false)
        ? c!.ragioneSociale
        : widget.defaultCompanyName;
    _cuaa.text = c?.cuaa ?? '';
    _piva.text = c?.partitaIva ?? '';
    _indirizzo.text = c?.indirizzo ?? '';
    _cap.text = c?.cap ?? '';
    _comune.text = c?.comune ?? '';
    _provincia.text = c?.provincia ?? '';
    _referente.text = c?.referente ?? '';
    _telefono.text = c?.telefono ?? '';
    _email.text = c?.email ?? '';
    _pec.text = c?.pec ?? '';
    _latitude = c?.latitude;
    _longitude = c?.longitude;
    _isNewOperator = c?.isNewOperator ?? false;
    _processingType = c?.processingType ?? 'proprio';
    _thirdPartyCert.text = c?.thirdPartyCertNumber ?? '';
    _latitudeText.text = c?.latitudeText ?? '';
    _longitudeText.text = c?.longitudeText ?? '';
    _manipulationSiteAddress.text = c?.manipulationSiteAddress ?? '';
    _peakPeriodFrom = (c?.peakPeriodFrom.isNotEmpty ?? false)
        ? c?.peakPeriodFrom
        : null;
    _isJointVisit = c?.isJointVisit ?? false;
    _jointVisitDetails.text = c?.jointVisitDetails ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertCompany(
        visitId: widget.visitId,
        ragioneSociale: _ragioneSociale.text.trim(),
        cuaa: _cuaa.text.trim(),
        partitaIva: _piva.text.trim(),
        indirizzo: _indirizzo.text.trim(),
        cap: _cap.text.trim(),
        comune: _comune.text.trim(),
        provincia: _provincia.text.trim(),
        referente: _referente.text.trim(),
        telefono: _telefono.text.trim(),
        email: _email.text.trim(),
        pec: _pec.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isNewOperator: _isNewOperator,
        processingType: _processingType,
        thirdPartyCertNumber: _thirdPartyCert.text.trim(),
        latitudeText: _latitudeText.text.trim(),
        longitudeText: _longitudeText.text.trim(),
        manipulationSiteAddress: _manipulationSiteAddress.text.trim(),
        peakPeriodFrom: _peakPeriodFrom ?? '',
        peakPeriodTo: '',
        isJointVisit: _isJointVisit,
        jointVisitDetails: _jointVisitDetails.text.trim(),
      );

      final logger = ref.read(activityLoggerProvider);
      final auth = ref.read(authControllerProvider);
      await logger.log(
        action: 'UPDATE_COMPANY_INFO',
        description: 'Aggiornati dati azienda per la visita ${widget.visitId}',
        actor: auth.username ?? 'Ispettore',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anagrafica azienda salvata (offline).')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyByVisitIdProvider(widget.visitId));

    return companyAsync.when(
      data: (company) {
        _fillIfNeeded(company);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anagrafica Azienda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifica e completa i dati anagrafici e di contatto dell\'azienda.',
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),

              _FormGroup(
                title: 'Dati Societari',
                icon: Icons.business_rounded,
                children: [
                  _field(
                    'Ragione sociale',
                    _ragioneSociale,
                    flex: 2,
                    icon: Icons.business,
                  ),
                  _field('CUAA', _cuaa),
                  _field('Partita IVA', _piva),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title: 'Sede Legale / Operativa',
                icon: Icons.location_on_rounded,
                children: [
                  _field(
                    'Indirizzo',
                    _indirizzo,
                    flex: 2,
                    icon: Icons.map_outlined,
                  ),
                  _field('Comune', _comune, flex: 1),
                  _field('CAP', _cap, width: 120),
                  _field('Provincia', _provincia, width: 80),
                  _field(
                    'Latitudine (Nord/Sud)',
                    _latitudeText,
                    flex: 1,
                    icon: Icons.gps_fixed,
                  ),
                  _field(
                    'Longitudine (Est/Ovest)',
                    _longitudeText,
                    flex: 1,
                    icon: Icons.gps_fixed,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title: 'Lavorazione e Manipolazione',
                icon: Icons.factory_outlined,
                children: [
                  _field(
                    'Indirizzo sito di manipolazione (se applicabile)',
                    _manipulationSiteAddress,
                    flex: 1,
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title: 'Periodo di Picco dell\'Attività',
                icon: Icons.event_available_rounded,
                children: [
                  _multiSelectMonthsField(
                    'Mesi di Picco dell\'Attività',
                    _peakPeriodFrom ?? '',
                    (v) => setState(() => _peakPeriodFrom = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FormGroup(
                title: 'Rappresentante Aziendale',
                icon: Icons.contact_mail_rounded,
                children: [
                  _field(
                    'Nome Referente',
                    _referente,
                    flex: 1,
                    icon: Icons.person_outline,
                  ),
                  _field('Telefono', _telefono, icon: Icons.phone_outlined),
                  _field(
                    'Email',
                    _email,
                    flex: 2,
                    icon: Icons.alternate_email_rounded,
                  ),
                  _field(
                    'PEC',
                    _pec,
                    flex: 2,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title: 'Specifiche Procedura M904 (Bios/SQNPI)',
                icon: Icons.verified_user_rounded,
                children: [
                  _switchField(
                    'Nuovo Operatore (Verifica storico 2 anni)',
                    _isNewOperator,
                    (v) => setState(() => _isNewOperator = v),
                    subtitle: 'Se attivo, sblocca la verifica OdC precedente',
                  ),
                  _dropdownField(
                    'Tipo Lavorazione',
                    _processingType,
                    {
                      'proprio': 'In Proprio',
                      'terzista': 'Terzista (Lavorazione Esterna)',
                    },
                    (v) => setState(() => _processingType = v!),
                  ),
                  if (_processingType == 'terzista')
                    _field(
                      'Num. Certificato SQNPI Terzista',
                      _thirdPartyCert,
                      icon: Icons.description_outlined,
                    ),
                  const SizedBox(height: 16),
                  _switchField(
                    'Visita Ispettiva Congiunta con altri schemi',
                    _isJointVisit,
                    (v) => setState(() => _isJointVisit = v),
                    subtitle: 'Esempio: GlobalGAP, Biologico, etc.',
                  ),
                  if (_isJointVisit)
                    _field(
                      'Dettaglio schema di certificazione congiunto',
                      _jointVisitDetails,
                      icon: Icons.account_tree_outlined,
                      flex: 1,
                    ),
                ],
              ),

              const SizedBox(height: 48),

              Row(
                children: [
                  FilledButton.icon(
                    onPressed: (widget.isReadOnly || _saving) ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Salva Informazioni',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {
                      _loaded = false;
                      setState(() {});
                    },
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Ripristina dati'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      foregroundColor: Colors.blueGrey.shade600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sincronizzazione automatica attiva',
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore caricamento azienda: $e')),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int flex = 1,
    double? width,
    IconData? icon,
    bool? isReadOnly,
  }) {
    final effectiveReadOnly = isReadOnly ?? widget.isReadOnly;
    // Calcoliamo una larghezza approssimativa basata sul flex se non fornita
    // In un Wrap, usiamo SizedBox per dare una base.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            width ??
            (constraints.maxWidth > 600
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth);
        return SizedBox(
          width: w,
          child: TextFormField(
            controller: c,
            readOnly: effectiveReadOnly,
            enabled: !effectiveReadOnly,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
              ),
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _switchField(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth > 600
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(subtitle, style: const TextStyle(fontSize: 11))
                  : null,
              value: value,
              onChanged: widget.isReadOnly ? null : onChanged,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _multiSelectMonthsField(
    String label,
    String selectedValue,
    Function(String) onChanged,
  ) {
    final List<String> allMonths = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    final List<String> currentSelected =
        selectedValue.isEmpty
            ? []
            : selectedValue.split(', ').where((s) => s.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Seleziona Mesi di Picco',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Indica i periodi di massima attività',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: allMonths.length,
                            itemBuilder: (context, index) {
                              final month = allMonths[index];
                              final isSelected = currentSelected.contains(
                                month,
                              );
                              return FilterChip(
                                label: Center(
                                  child: Text(
                                    month,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (bool value) {
                                  setDialogState(() {
                                    if (value) {
                                      currentSelected.add(month);
                                    } else {
                                      currentSelected.remove(month);
                                    }
                                    currentSelected.sort(
                                      (a, b) => allMonths.indexOf(a).compareTo(
                                        allMonths.indexOf(b),
                                      ),
                                    );
                                  });
                                  onChanged(currentSelected.join(', '));
                                },
                                selectedColor: const Color(0xFF2D6A4F),
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4332),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Chiudi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF2D6A4F),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      currentSelected.isEmpty
                          ? Text(
                            'Seleziona i mesi...',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          )
                          : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                currentSelected.map((month) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFD8F3DC,
                                      ), // Light green
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFB7E4C7),
                                      ),
                                    ),
                                    child: Text(
                                      month,
                                      style: const TextStyle(
                                        color: Color(0xFF1B4332),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(
    String label,
    String? value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth > 600
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth,
          child: DropdownButtonFormField<String>(
            // Usiamo initialValue per compatibilità con le nuove versioni se richiesto,
            // ma value è necessario per il controllo dello stato.
            // Se il linter rompe, proviamo a sopprimerlo o usare la proprietà corretta.
            initialValue: (value?.isEmpty ?? true) ? null : value,
            items: items.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: widget.isReadOnly ? null : onChanged,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormGroup extends StatelessWidget {
  const _FormGroup({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.blueGrey.shade100.withValues(alpha: 0.5),
            ),
          ),
          child: Wrap(spacing: 16, runSpacing: 16, children: children),
        ),
      ],
    );
  }
}

class _UecLottiSection extends ConsumerWidget {
  const _UecLottiSection({
    required this.visitId,
    required this.defaultColtura,
    required this.isReadOnly,
  });
  final String visitId;
  final String defaultColtura;
  final bool isReadOnly;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _showAddUecDialog(BuildContext context, WidgetRef ref) async {
    final coltura = TextEditingController(text: defaultColtura);
    final descrizione = TextEditingController();
    final note = TextEditingController();
    final lat = TextEditingController();
    final long = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Aggiungi UEC'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: coltura,
                  decoration: const InputDecoration(
                    labelText: 'Coltura',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descrizione,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lat,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Latitudine',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: long,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Longitudine',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final pos = await Geolocator.getCurrentPosition();
                          lat.text = pos.latitude.toStringAsFixed(6);
                          long.text = pos.longitude.toStringAsFixed(6);
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Errore GPS: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    if (res != true) {
      coltura.dispose();
      descrizione.dispose();
      note.dispose();
      lat.dispose();
      long.dispose();
      return;
    }

    final db = ref.read(appDatabaseProvider);
    await db.upsertUec(
      id: _newId('UEC'),
      visitId: visitId,
      coltura: coltura.text.trim(),
      descrizione: descrizione.text.trim(),
      note: note.text.trim(),
      latitude: double.tryParse(lat.text),
      longitude: double.tryParse(long.text),
    );

    coltura.dispose();
    descrizione.dispose();
    note.dispose();
    lat.dispose();
    long.dispose();
  }

  Future<void> _showAddLotDialog(
    BuildContext context,
    WidgetRef ref,
    String uecId,
  ) async {
    final codice = TextEditingController();
    final quantita = TextEditingController();
    final note = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Aggiungi Lotto'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codice,
                  decoration: const InputDecoration(
                    labelText: 'Codice lotto',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantita,
                  decoration: const InputDecoration(
                    labelText: 'Quantità (opzionale)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    if (res != true) {
      codice.dispose();
      quantita.dispose();
      note.dispose();
      return;
    }

    final db = ref.read(appDatabaseProvider);
    await db.upsertLot(
      id: _newId('LOT'),
      uecId: uecId,
      codice: codice.text.trim(),
      quantita: quantita.text.trim(),
      note: note.text.trim(),
    );

    codice.dispose();
    quantita.dispose();
    note.dispose();
  }

  Future<void> _pickUecPhoto(
    BuildContext context,
    WidgetRef ref,
    VisitUec u,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );

    if (image == null) return;

    final db = ref.read(appDatabaseProvider);
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Forse GPS disattivato o timeout, procediamo senza nuove coordinate se fallisce
    }

    await db.upsertUec(
      id: u.id,
      visitId: u.visitId,
      coltura: u.coltura,
      descrizione: u.descrizione,
      note: u.note,
      latitude: pos?.latitude ?? u.latitude,
      longitude: pos?.longitude ?? u.longitude,
      photoPath: image.path,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto UEC salvata con successo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(visitId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: uecsAsync.when(
            data: (uecs) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UEC / Lotti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _showAddUecDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Aggiungi UEC'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (uecs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'Nessuna UEC presente. Clicca “Aggiungi UEC” per iniziare.',
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: uecs.length,
                        itemBuilder: (ctx, i) {
                          final u = uecs[i];
                          final title = u.descrizione.isNotEmpty
                              ? u.descrizione
                              : u.id;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              shape: const Border(),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                u.coltura.isNotEmpty
                                    ? u.coltura
                                    : 'Coltura non indicata',
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                if (u.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.notes,
                                          size: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Note: ${u.note}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // GPS and Photo Preview
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  u.latitude != null &&
                                                          u.longitude != null
                                                      ? 'GPS: ${u.latitude!.toStringAsFixed(6)}, ${u.longitude!.toStringAsFixed(6)}'
                                                      : 'GPS: Non Rilevato',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: u.latitude != null
                                                        ? Colors.blue.shade900
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (u.photoPath != null)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(u.photoPath!),
                                                  height: 120,
                                                  width: 160,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            else
                                              Container(
                                                height: 80,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'Foto Obblig.',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton.filledTonal(
                                            onPressed: () =>
                                                _pickUecPhoto(context, ref, u),
                                            icon: const Icon(Icons.camera_alt),
                                            tooltip:
                                                'Scatta Foto Georeferenziata',
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Foto',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _showAddLotDialog(context, ref, u.id),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Aggiungi Lotto'),
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Elimina UEC'),
                                            content: const Text(
                                              'Vuoi eliminare questa UEC? Verranno eliminati anche i lotti associati.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(c).pop(false),
                                                child: const Text('Annulla'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(c).pop(true),
                                                child: const Text('Elimina'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          final db = ref.read(
                                            appDatabaseProvider,
                                          );
                                          await db.deleteUec(u.id);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Elimina UEC'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _LotsList(uecId: u.id),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore caricamento UEC: $e')),
          ),
        ),
      ),
    );
  }
}

class _LotsList extends ConsumerWidget {
  const _LotsList({required this.uecId});
  final String uecId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsync = ref.watch(lotsByUecIdProvider(uecId));

    return lotsAsync.when(
      data: (lots) {
        if (lots.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Nessun lotto associato.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lotti', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...lots.map((l) {
              final descr = l.codice.isNotEmpty ? l.codice : l.id;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(descr),
                subtitle: Text(
                  [
                    if (l.quantita.isNotEmpty) 'Quantità: ${l.quantita}',
                    if (l.note.isNotEmpty) 'Note: ${l.note}',
                  ].join(' • '),
                ),
                trailing: IconButton(
                  tooltip: 'Elimina lotto',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Elimina lotto'),
                        content: const Text('Vuoi eliminare questo lotto?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Annulla'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final db = ref.read(appDatabaseProvider);
                      await db.deleteLot(l.id);
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Errore caricamento lotti: $e'),
      ),
    );
  }
}

// Provider per le firme della visita
final _signaturesProvider = StreamProvider.family<List<VisitSignature>, String>(
  (ref, visitId) {
    final db = ref.watch(appDatabaseProvider);
    return db.watchSignaturesByVisitId(visitId);
  },
);

class _SignatureSection extends ConsumerWidget {
  const _SignatureSection({required this.visitId, required this.isReadOnly});
  final String visitId;
  final bool isReadOnly;

  Future<void> _pickIdentityDoc(BuildContext context, WidgetRef ref, String sigId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final db = ref.read(appDatabaseProvider);
      
      // Copia in cartella app
      final appDir = await getApplicationSupportDirectory();
      final destDir = Directory(
        '${appDir.path}/sqnpi_audit_manager/signatures/$visitId/id_docs',
      );
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      
      final ext = file.extension ?? 'dat';
      final destFile = File(
        '${destDir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await File(file.path!).copy(destFile.path);

      await db.updateSignatureIdentityDoc(sigId, destFile.path);
    }
  }

  Future<void> _addSignature(
    BuildContext context,
    WidgetRef ref,
    String type, {
    String? signerName,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SignatureDialog(
        title: type == 'inspector'
            ? 'Firma Ispettore'
            : type == 'delegate'
                ? 'Firma Delegato'
                : 'Firma Legale Rappresentante',
        showNameField: type != 'inspector',
        initialSignerName: signerName,
      ),
    );

    if (result != null) {
      final db = ref.read(appDatabaseProvider);
      await db.insertSignature(
        visitId: visitId,
        signatureType: type,
        filePath: result['filePath'] as String,
        signerName: result['signerName'] as String?,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signaturesAsync = ref.watch(_signaturesProvider(visitId));
    final db = ref.read(appDatabaseProvider);

    return signaturesAsync.when(
      data: (signatures) {
        final inspectorSig = signatures
            .where((s) => s.signatureType == 'inspector')
            .firstOrNull;
        final representativeSig = signatures
            .where((s) => s.signatureType == 'representative')
            .firstOrNull;
        final delegateSig = signatures
            .where((s) => s.signatureType == 'delegate')
            .firstOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firme Digitali',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apponi le firme necessarie per validare il verbale di visita.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _SignatureCard(
                    title: 'Ispettore SQNPI',
                    signerName: 'Ispettore incaricato',
                    signature: inspectorSig,
                    onTap: () => _addSignature(context, ref, 'inspector'),
                    onDelete: inspectorSig != null
                        ? () => db.deleteSignature(inspectorSig.id)
                        : null,
                  ),
                  _SignatureCard(
                    title: 'Legale Rappresentante',
                    signerName:
                        representativeSig?.signerName ?? 'Titolare',
                    signature: representativeSig,
                    onTap: () => _addSignature(
                      context,
                      ref,
                      'representative',
                      signerName: representativeSig?.signerName,
                    ),
                    onDelete: representativeSig != null
                        ? () => db.deleteSignature(representativeSig.id)
                        : null,
                    onPickIdentityDoc: representativeSig != null
                        ? () => _pickIdentityDoc(context, ref, representativeSig.id)
                        : null,
                  ),
                  _SignatureCard(
                    title: 'Delegato Aziendale',
                    signerName:
                        delegateSig?.signerName ?? 'Sostituto delegato',
                    signature: delegateSig,
                    onTap: () => _addSignature(
                      context,
                      ref,
                      'delegate',
                      signerName: delegateSig?.signerName,
                    ),
                    onDelete: delegateSig != null
                        ? () => db.deleteSignature(delegateSig.id)
                        : null,
                    onPickIdentityDoc: delegateSig != null
                        ? () => _pickIdentityDoc(context, ref, delegateSig.id)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore caricamento firme: $e')),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.title,
    required this.signerName,
    this.signature,
    required this.onTap,
    this.onDelete,
    this.onPickIdentityDoc,
  });

  final String title;
  final String signerName;
  final VisitSignature? signature;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPickIdentityDoc;

  @override
  Widget build(BuildContext context) {
    final hasSignature = signature != null;
    final hasIdentityDoc = signature?.identityDocPath != null;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSignature
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey.shade200,
          width: hasSignature ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signerName,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (hasSignature)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Rimuovi firma',
                )
              else
                Icon(Icons.edit_note, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: hasSignature
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(signature!.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.red,
                              ),
                            ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.draw,
                          size: 40,
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tocca per firmare',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (hasSignature) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Firma acquisita correttamente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onPickIdentityDoc != null) ...[
              const Divider(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: Colors.indigo.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Documento d\'identità',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasIdentityDoc)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              signature!.identityDocPath!.split('/').last,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: onPickIdentityDoc,
                            icon: const Icon(Icons.refresh, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Cambia documento',
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onPickIdentityDoc,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Carica Documento'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.indigo.shade200),
                          foregroundColor: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DashboardProgress extends ConsumerStatefulWidget {
  const _DashboardProgress({required this.visitId});
  final String visitId;

  @override
  ConsumerState<_DashboardProgress> createState() => _DashboardProgressState();
}

class _DashboardProgressState extends ConsumerState<_DashboardProgress> {
  String? _selectedUecId;

  @override
  Widget build(BuildContext context) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(widget.visitId));

    return uecsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (uecs) {
        if (uecs.isEmpty) return const SizedBox.shrink();

        final activeUecId =
            (_selectedUecId != null && uecs.any((u) => u.id == _selectedUecId))
            ? _selectedUecId!
            : uecs.first.id;

        if (activeUecId != _selectedUecId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedUecId = activeUecId);
          });
        }

        final selectedUec = uecs.firstWhere((u) => u.id == activeUecId);
        final progressAsync = ref.watch(auditProgressProvider(selectedUec.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Stato Avanzamento Checklist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                const Text(
                  'UEC selezionata:',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: activeUecId,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(12),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  items: uecs
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(
                            u.descrizione.isNotEmpty ? u.descrizione : u.id,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUecId = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            progressAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Errore dashboard: $e'),
              data: (stats) {
                return Row(
                  children: stats.map((s) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _StatCard(stat: s),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            _ValidationAlerts(uecId: selectedUec.id),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final PhaseProgress stat;

  @override
  Widget build(BuildContext context) {
    final color = stat.percent == 1.0 ? Colors.green : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.phaseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stat.completedCount}/${stat.totalCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(stat.percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.percent,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationAlerts extends ConsumerWidget {
  const _ValidationAlerts({required this.uecId});
  final String uecId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(validationAlertsProvider(uecId));

    return alertsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.report_problem,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attenzione: Punti mancanti o critici (${alerts.length})',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts
                  .take(5)
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Punto ${a.itemCode}: ${a.message}',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (alerts.length > 5) ...[
                const SizedBox(height: 4),
                Text(
                  '    ... e altri ${alerts.length - 5} problemi da risolvere',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Provider per i documenti giustificativi del bilancio di massa
final _mbDocsEntrataProvider =
    StreamProvider.family<List<MassBalanceDocument>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalanceDocsByType(visitId, 'entrata');
    });

final _mbDocsUscitaProvider =
    StreamProvider.family<List<MassBalanceDocument>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalanceDocsByType(visitId, 'uscita');
    });

class _MassBalanceSection extends ConsumerStatefulWidget {
  const _MassBalanceSection({required this.visitId, required this.isReadOnly});
  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<_MassBalanceSection> createState() =>
      _MassBalanceSectionState();
}

class _MassBalanceSectionState extends ConsumerState<_MassBalanceSection> {
  final _purchased = TextEditingController();
  final _used = TextEditingController();
  final _stock = TextEditingController();
  final _docs = TextEditingController();
  final _newSubstance = TextEditingController();

  List<String> _substances = [];
  bool _loaded = false;
  bool _saving = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void dispose() {
    _purchased.dispose();
    _used.dispose();
    _stock.dispose();
    _docs.dispose();
    _newSubstance.dispose();
    super.dispose();
  }

  void _fillIfNeeded(MassBalanceRecord? r) {
    if (_loaded) return;
    _loaded = true;
    if (r == null) return;

    _purchased.text = r.purchased.toString();
    _used.text = r.used.toString();
    _stock.text = r.stock.toString();
    _docs.text = r.referenceDocuments;
    if (r.substances.isNotEmpty) {
      try {
        _substances = List<String>.from(
          r.substances.split(',').where((s) => s.isNotEmpty),
        );
      } catch (_) {}
    }
  }

  double get _discrepancy {
    final p = double.tryParse(_purchased.text.replaceAll(',', '.')) ?? 0;
    final u = double.tryParse(_used.text.replaceAll(',', '.')) ?? 0;
    final s = double.tryParse(_stock.text.replaceAll(',', '.')) ?? 0;
    return p - (u + s);
  }

  Future<void> _save() async {
    final purchased = double.tryParse(_purchased.text.replaceAll(',', '.')) ?? 0;
    final used = double.tryParse(_used.text.replaceAll(',', '.')) ?? 0;

    // Validazione documenti giustificativi
    final entrataDocsAsync = ref.read(_mbDocsEntrataProvider(widget.visitId));
    final uscitaDocsAsync = ref.read(_mbDocsUscitaProvider(widget.visitId));

    final entrataDocs = entrataDocsAsync.valueOrNull ?? [];
    final uscitaDocs = uscitaDocsAsync.valueOrNull ?? [];

    final List<String> missing = [];

    if (purchased > 0 && entrataDocs.isEmpty) {
      missing.add('📥 Documenti di ENTRATA (fatture acquisto)');
    }
    if (used > 0 && uscitaDocs.isEmpty) {
      missing.add('📤 Documenti di USCITA (quaderno campagna, DDT)');
    }

    if (missing.isNotEmpty) {
      if (!mounted) return;

      final hasEntrata = missing.any((m) => m.contains('ENTRATA'));
      final hasUscita = missing.any((m) => m.contains('USCITA'));

      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con gradiente
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.deepOrange.shade500,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_off_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Documenti Mancanti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Allega i giustificativi richiesti',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Corpo del messaggio
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Per salvare il bilancio di massa, ogni quantità dichiarata deve essere supportata da almeno un documento:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card documento Entrata
                      if (hasEntrata)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.teal.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.teal.shade700,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Documenti di Entrata',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fatture acquisto, bolle consegna',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.cancel_rounded,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                            ],
                          ),
                        ),

                      // Card documento Uscita
                      if (hasUscita)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.deepOrange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.deepOrange.shade700,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Documenti di Uscita',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.deepOrange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Quaderno campagna, DDT, registri',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.deepOrange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.cancel_rounded,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Hint
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue.shade400, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Scorri nella pagina per trovare le sezioni dove allegare i file.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pulsante
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Ho capito, allego i documenti',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return; // Non salva
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertMassBalance(
        visitId: widget.visitId,
        substances: _substances.join(','),
        purchased: purchased,
        used: used,
        stock: double.tryParse(_stock.text.replaceAll(',', '.')) ?? 0,
        discrepancy: _discrepancy,
        referenceDocuments: _docs.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bilancio di massa salvato con successo.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDocument(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      dialogTitle: docType == 'entrata'
          ? 'Seleziona documenti di ENTRATA (fatture, bolle...)'
          : 'Seleziona documenti di USCITA (quaderno campagna, DDT...)',
    );

    if (result == null || result.files.isEmpty) return;

    final db = ref.read(appDatabaseProvider);

    for (final file in result.files) {
      if (file.path == null) continue;

      // Copia nella cartella app
      final appDir = await getApplicationSupportDirectory();
      final destDir = Directory(
        '${appDir.path}/sqnpi_audit_manager/mb_docs/${widget.visitId}',
      );
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final ext = file.extension ?? 'dat';
      final destFile = File(
        '${destDir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await File(file.path!).copy(destFile.path);

      await db.insertMassBalanceDoc(
        visitId: widget.visitId,
        docType: docType,
        filePath: destFile.path,
        fileName: file.name,
        caption: '',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.files.length} documento/i allegato/i come ${docType == "entrata" ? "ENTRATA" : "USCITA"}',
          ),
        ),
      );
    }
  }

  Future<void> _pickImageDocument(String docType) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;

    final appDir = await getApplicationSupportDirectory();
    final destDir = Directory(
      '${appDir.path}/sqnpi_audit_manager/mb_docs/${widget.visitId}',
    );
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destFile = File(
      '${destDir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await File(image.path).copy(destFile.path);

    final db = ref.read(appDatabaseProvider);
    await db.insertMassBalanceDoc(
      visitId: widget.visitId,
      docType: docType,
      filePath: destFile.path,
      fileName: 'Foto_${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      caption: '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto allegata come ${docType == "entrata" ? "ENTRATA" : "USCITA"}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
        .watch(massBalanceByVisitIdProvider(widget.visitId))
        .whenData(_fillIfNeeded);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Bilancio di Massa',
            subtitle: 'Calcolo input/output e verifica giacenze (M904 rev. 08)',
            icon: Icons.calculate_rounded,
          ),
          const SizedBox(height: 32),

          _CardGroup(
            title: 'Sostanze Attive Sotto Controllo',
            subtitle:
                'Seleziona almeno 2 sostanze su cui effettuare il calcolo',
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ..._substances.map(
                      (s) => Chip(
                        label: Text(
                          s,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onDeleted: () => setState(() => _substances.remove(s)),
                        deleteIconColor: Colors.red,
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                    if (_substances.length < 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Seleziona almeno 2',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSubstance,
                        decoration: InputDecoration(
                          hintText: 'Aggiungi sostanza attiva...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            setState(() {
                              _substances.add(v.trim());
                              _newSubstance.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {
                        if (_newSubstance.text.trim().isNotEmpty) {
                          setState(() {
                            _substances.add(_newSubstance.text.trim());
                            _newSubstance.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _CardGroup(
            title: 'Dati di Verifica',
            child: Column(
              children: [
                Row(
                  children: [
                    _numericField(
                      'Quantità Acquistata',
                      _purchased,
                      unit: 'kg/L',
                    ),
                    const SizedBox(width: 16),
                    _numericField('Quantità Utilizzata', _used, unit: 'kg/L'),
                    const SizedBox(width: 16),
                    _numericField('Giacenza Attuale', _stock, unit: 'kg/L'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _discrepancy.abs() < 0.01
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _discrepancy.abs() < 0.01
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _discrepancy.abs() < 0.01
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _discrepancy.abs() < 0.01
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Discrepanza Rilevata',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            '${_discrepancy.toStringAsFixed(2)} kg/L',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _discrepancy.abs() < 0.01
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_discrepancy.abs() > 0.01)
                        const Text(
                          'Bilancio NON congruo!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── DOCUMENTI GIUSTIFICATIVI DI ENTRATA ──
          _buildDocSection(
            title: 'Documenti di Entrata (Acquisto)',
            subtitle: 'Fatture di acquisto, bolle di consegna, registri di carico',
            docType: 'entrata',
            icon: Icons.arrow_downward_rounded,
            color: Colors.teal,
          ),

          const SizedBox(height: 24),

          // ── DOCUMENTI GIUSTIFICATIVI DI USCITA ──
          _buildDocSection(
            title: 'Documenti di Uscita (Utilizzo)',
            subtitle: 'Quaderno di campagna, DDT, registri di scarico',
            docType: 'uscita',
            icon: Icons.arrow_upward_rounded,
            color: Colors.deepOrange,
          ),

          const SizedBox(height: 24),

          _CardGroup(
            title: 'Note Documentazione',
            child: TextField(
              controller: _docs,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Note aggiuntive sulla documentazione verificata...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text(
                'Salva Bilancio di Massa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocSection({
    required String title,
    required String subtitle,
    required String docType,
    required IconData icon,
    required Color color,
  }) {
    final docsProvider = docType == 'entrata'
        ? _mbDocsEntrataProvider
        : _mbDocsUscitaProvider;
    final docsAsync = ref.watch(docsProvider(widget.visitId));

    return _CardGroup(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulsanti per aggiungere
          if (!widget.isReadOnly)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDocument(docType),
                  icon: Icon(Icons.upload_file, color: color),
                  label: Text(
                    'Allega File',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                if (!_isDesktop)
                  OutlinedButton.icon(
                    onPressed: () => _pickImageDocument(docType),
                    icon: Icon(Icons.camera_alt, color: color),
                    label: Text(
                      'Scatta Foto',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Lista documenti allegati
          docsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Errore: $e'),
            data: (docs) {
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nessun documento allegato',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final isImage = _isImageFile(doc.fileName);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isImage
                                ? Icons.image
                                : _fileIconForName(doc.fileName),
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.fileName.isNotEmpty
                                    ? doc.fileName
                                    : 'Documento',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Allegato il ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year} alle ${doc.createdAt.hour}:${doc.createdAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isReadOnly)
                          IconButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Elimina documento?'),
                                  content: Text(
                                    'Vuoi eliminare "${doc.fileName}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Annulla'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Elimina',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final db = ref.read(appDatabaseProvider);
                                await db.deleteMassBalanceDoc(doc.id);
                                // Prova a eliminare anche il file fisico
                                try {
                                  final f = File(doc.filePath);
                                  if (await f.exists()) await f.delete();
                                } catch (_) {}
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Elimina documento',
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'].contains(ext);
  }

  IconData _fileIconForName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _numericField(
    String label,
    TextEditingController c, {
    required String unit,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              suffixText: unit,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChiusuraSection extends ConsumerStatefulWidget {
  const _ChiusuraSection({required this.visitId, required this.isReadOnly});
  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<_ChiusuraSection> createState() => _ChiusuraSectionState();
}

class _ChiusuraSectionState extends ConsumerState<_ChiusuraSection> {
  final _actions = TextEditingController();
  DateTime? _deadline;
  bool _isClosed = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  void _fillIfNeeded(VisitClosing? c) {
    if (_loaded) return;
    _loaded = true;
    if (c == null) {
      // Default deadline: +7 days for M904
      _deadline = DateTime.now().add(const Duration(days: 7));
      return;
    }

    _actions.text = c.correctiveActions;
    _deadline = c.resolutionDeadline;
    _isClosed = c.isClosed;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertClosing(
        visitId: widget.visitId,
        correctiveActions: _actions.text.trim(),
        resolutionDeadline: _deadline,
        isClosed: _isClosed,
      );

      // Log activity
      final logger = ref.read(activityLoggerProvider);
      final auth = ref.read(authControllerProvider);
      final actorName = auth.username ?? 'Ispettore';
      final statusStr = _isClosed ? 'CHIUSA' : 'SALVATA (IN CORSO)';
      
      await logger.log(
        action: _isClosed ? 'CLOSE_VISIT' : 'UPDATE_VISIT_CLOSING',
        description: 'Visita ${widget.visitId}: stato impostato a $statusStr',
        actor: actorName,
      );

      // --- SYNC TO EXTERNAL MANAGEMENT SYSTEM ---
      if (_isClosed && mounted) {
        final syncService = ref.read(managementSyncServiceProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 16),
                Text('Sincronizzazione col gestionale aziendale...'),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );

        final success = await syncService.syncVisitToManagement(widget.visitId);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                ? 'Dati inviati correttamente al gestionale.' 
                : 'Errore durante la sincronizzazione col gestionale.'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiusura visita salvata.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(closingByVisitIdProvider(widget.visitId)).whenData(_fillIfNeeded);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Chiusura e Sanzioni',
            subtitle: 'Riepilogo NC, azioni correttive e scadenze risolutive',
            icon: Icons.gavel_rounded,
          ),
          const SizedBox(height: 32),

          _NcSummary(visitId: widget.visitId),

          const SizedBox(height: 24),

          _CardGroup(
            title: 'Azioni Correttive',
            subtitle:
                'Descrivi le azioni richieste per risolvere le NC rilevate',
            child: TextField(
              controller: _actions,
              maxLines: 5,
              readOnly: widget.isReadOnly,
              enabled: !widget.isReadOnly,
              decoration: InputDecoration(
                hintText:
                    'Es: Integrazione registro di campagna, smaltimento contenitori...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _CardGroup(
                  title: 'Scadenza Risolutiva',
                  subtitle:
                      'Termine massimo per la risoluzione (M904: max 7gg)',
                  child: InkWell(
                    onTap: widget.isReadOnly
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _deadline ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _deadline = picked);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _deadline == null
                                ? 'Seleziona data'
                                : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_deadline != null &&
                              _deadline!.difference(DateTime.now()).inDays > 7)
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardGroup(
                  title: 'Stato Finale',
                  child: SwitchListTile(
                    title: const Text(
                      'Visita Chiusa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Nessuna ulteriore modifica permessa'),
                    value: _isClosed,
                    onChanged: widget.isReadOnly
                        ? null
                        : (v) => setState(() => _isClosed = v),
                    activeThumbColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving
                  ? null
                  : _isClosed
                      ? _save
                      : () async {
                          // Dialog se il toggle non è attivo
                          await showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 28),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blueGrey.shade600,
                                            Colors.blueGrey.shade800,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.lock_outline_rounded,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Azione Richiesta',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.amber.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.toggle_on_outlined,
                                                    color: Colors.amber.shade800,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Attiva "Visita Chiusa"',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 14,
                                                          color: Colors.amber.shade900,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Devi abilitare il toggle prima di poter confermare la chiusura.',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.amber.shade800,
                                                          height: 1.4,
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.blueGrey.shade700,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: const Text(
                                            'Ho capito',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: _isClosed
                    ? Colors.green.shade700
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Icon(
                      _isClosed
                          ? Icons.verified_rounded
                          : Icons.lock_outline_rounded,
                    ),
              label: Text(
                _isClosed
                    ? 'Conferma Chiusura Visita'
                    : 'Attiva "Visita Chiusa" per confermare',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampionamentoSection extends ConsumerStatefulWidget {
  const _CampionamentoSection({
    required this.visitId,
    required this.isReadOnly,
  });
  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<_CampionamentoSection> createState() =>
      _CampionamentoSectionState();
}

class _CampionamentoSectionState extends ConsumerState<_CampionamentoSection> {
  final _picker = ImagePicker();

  Future<void> _pickSamplePhoto(VisitSample sample) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galleria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image != null) {
        final db = ref.read(appDatabaseProvider);
        await db.upsertSample(
          id: sample.id,
          visitId: sample.visitId,
          sampleCode: sample.sampleCode,
          matrixType: sample.matrixType,
          sealNumber: sample.sealNumber,
          photoPath: image.path,
        );
      }
    }
  }

  void _showAddSampleDialog([VisitSample? sample]) {
    final codeCtrl = TextEditingController(text: sample?.sampleCode);
    final matrixCtrl = TextEditingController(text: sample?.matrixType);
    final sealCtrl = TextEditingController(text: sample?.sealNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sample == null ? 'Aggiungi Campione' : 'Modifica Campione'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Codice Campione'),
            ),
            TextField(
              controller: matrixCtrl,
              decoration: const InputDecoration(
                labelText: 'Matrice (es. Uva, Foglie)',
              ),
            ),
            TextField(
              controller: sealCtrl,
              decoration: const InputDecoration(labelText: 'Numero Sigillo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(appDatabaseProvider);
              final navigator = Navigator.of(context);
              final id =
                  sample?.id ??
                  'SMP-${widget.visitId}-${DateTime.now().millisecondsSinceEpoch}';
              await db.upsertSample(
                id: id,
                visitId: widget.visitId,
                sampleCode: codeCtrl.text,
                matrixType: matrixCtrl.text,
                sealNumber: sealCtrl.text,
                photoPath: sample?.photoPath,
              );
              navigator.pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(samplesByVisitIdProvider(widget.visitId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const _SectionHeader(
                title: 'Campionamento',
                subtitle: 'Registrazione prelievi campioni (M904 Rev. 08)',
                icon: Icons.science_outlined,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddSampleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi Campione'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: samplesAsync.when(
            data: (samples) => samples.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun campione registrato',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: samples.length,
                    itemBuilder: (ctx, i) {
                      final s = samples[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: GestureDetector(
                            onTap: () => _pickSamplePhoto(s),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                image: s.photoPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(s.photoPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: s.photoPath == null
                                  ? const Icon(
                                      Icons.camera_alt,
                                      color: Colors.blue,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            s.sampleCode.isEmpty
                                ? 'Campione senza codice'
                                : s.sampleCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Matrice: ${s.matrixType} • Sigillo: ${s.sealNumber}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showAddSampleDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Elimina Campione?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Sì, elimina'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await ref
                                        .read(appDatabaseProvider)
                                        .deleteSample(s.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 28),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey,
                  letterSpacing: 1.0,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueGrey.shade100.withValues(alpha: 0.5),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _NcSummary extends ConsumerWidget {
  const _NcSummary({required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ncAsync = ref.watch(ncCountProvider(visitId));

    return _CardGroup(
      title: 'Riepilogo Non Conformità',
      child: ncAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Errore: $e'),
        data: (count) {
          if (count == 0) {
            return const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'Nessuna Non Conformità rilevata.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Text(
                'Rilevate $count Non Conformità che richiedono azioni correttive.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
