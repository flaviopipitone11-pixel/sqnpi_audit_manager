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

import 'package:drift/drift.dart' show Value;
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
                label: Text('Coltura e UEC'),
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
              dest: const NavigationRailDestination(
                icon: Icon(Icons.rule_folder_outlined),
                selectedIcon: Icon(Icons.rule_folder),
                label: Text('Quadro di verifica\nCOLTIVAZIONE', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
              ),
              page: _QuadroVerificaSection(visitId: visit.id, isReadOnly: isReadOnly),
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
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
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
                        indicatorColor: const Color(
                          0xFF10B981,
                        ).withValues(alpha: 0.1),
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
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
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
  const _ScopoControlloSection({required this.visit, required this.isReadOnly});
  final Visit visit;
  final bool isReadOnly;

  @override
  ConsumerState<_ScopoControlloSection> createState() =>
      _ScopoControlloSectionState();
}

class _ScopoControlloSectionState
    extends ConsumerState<_ScopoControlloSection> {
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
                    description:
                        'Ispezione finalizzata al prelievo di campioni',
                    icon: Icons.science_outlined,
                    isSelected: widget.visit.visitType.contains(
                      'CAMPIONAMENTO',
                    ),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    int? maxLines,
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

              // Rimuoviamo eventuali stringhe segnaposto legacy se stiamo aggiungendo tipi specifici
              types.removeWhere((s) => s.contains('Controllo SQNPI'));
              
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
                otherOperators: widget.visit.otherOperators,
                contactedPersons: widget.visit.contactedPersons,
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
  late TextEditingController _companionController;
  late TextEditingController _representativeController;
  late TextEditingController _otherOperatorsController;
  late TextEditingController _contactedPersonsController;

  @override
  void initState() {
    super.initState();
    _inspectorController = TextEditingController(
      text: widget.visit.inspectorName,
    );
    _companionController = TextEditingController(
      text: widget.visit.companionName,
    );
    _representativeController = TextEditingController(
      text: widget.visit.representativeName,
    );
    _otherOperatorsController = TextEditingController(
      text: widget.visit.otherOperators,
    );
    _contactedPersonsController = TextEditingController(
      text: widget.visit.contactedPersons,
    );

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
    _otherOperatorsController.dispose();
    _contactedPersonsController.dispose();
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
      otherOperators: _otherOperatorsController.text,
      contactedPersons: _contactedPersonsController.text,
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
                value: widget.visit.visitType
                    .split(',')
                    .where((s) =>
                        s.isNotEmpty &&
                        !s.contains('Controllo SQNPI') &&
                        !s.contains('Auto-creato'))
                    .join(' + '),
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
                      Icon(
                        Icons.people_alt_outlined,
                        color: Colors.blueGrey.shade700,
                      ),
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
                          'Ispettore RGVI',
                          _inspectorController,
                          Icons.badge_outlined,
                          'Nome dell\'ispettore',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _nameField(
                          'Affiancatore GVI2',
                          _companionController,
                          Icons.person_add_alt_1_outlined,
                          'Nome affiancatore (opzionale)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _nameField(
                          'Rappresentante Aziendale / Delegato',
                          _representativeController,
                          Icons.business_center_outlined,
                          'Nome del legale rappresentante o suo delegato',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _nameField(
                          'Altri Operatori Presenti',
                          _otherOperatorsController,
                          Icons.people_outline,
                          'Nomi altri operatori (se presenti)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.contact_phone_outlined,
                        color: Colors.blueGrey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Elenco Persone Contattate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _nameField(
                    'Persone Contattate',
                    _contactedPersonsController,
                    Icons.contact_mail_outlined,
                    'Es: Tecnico (Mario Rossi), Consulente (Luca Bianchi), etc.',
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
                  SizedBox(height: 16),
                  _detailRow(
                    'Azienda',
                    widget.visit.companyName,
                    Icons.business,
                  ),
                  const Divider(height: 32),
                  _detailRow(
                    'Coltura principale',
                    widget.visit.crop,
                    Icons.grass,
                  ),
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

  Widget _nameField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
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
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: widget.isReadOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      otherOperators: visit.otherOperators,
                      contactedPersons: visit.contactedPersons,
                    );

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: 'UPDATE_VISIT_DURATION',
                      description:
                          'Aggiornata durata visita ${visit.id} a ${value.toInt()} ore',
                      actor: visit.inspectorName.isNotEmpty
                          ? visit.inspectorName
                          : 'Ispettore',
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
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
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
                      otherOperators: visit.otherOperators,
                      contactedPersons: visit.contactedPersons,
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
  final _previousOdcName = TextEditingController();
  final _previousOdcOutcomes = TextEditingController();

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
    _previousOdcName.dispose();
    _previousOdcOutcomes.dispose();
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
    _previousOdcName.text = c?.previousOdcName ?? '';
    _previousOdcOutcomes.text = c?.previousOdcOutcomes ?? '';
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
        previousOdcName: _previousOdcName.text.trim(),
        previousOdcOutcomes: _previousOdcOutcomes.text.trim(),
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
                    'Operatore certificato da un altro OdC negli anni precedenti',
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
                  if (_isNewOperator) ...[
                    _field(
                      'Nome precedente OdC',
                      _previousOdcName,
                      icon: Icons.account_balance_outlined,
                    ),
                    _field(
                      'Esiti verifica precedente',
                      _previousOdcOutcomes,
                      icon: Icons.history_edu_outlined,
                    ),
                  ],
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
            maxLines: null,
            keyboardType: TextInputType.multiline,
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

    final List<String> currentSelected = selectedValue.isEmpty
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
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
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
                                      (a, b) => allMonths
                                          .indexOf(a)
                                          .compareTo(allMonths.indexOf(b)),
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
                                    color: isSelected
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
                  child: currentSelected.isEmpty
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
                          children: currentSelected.map((month) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC), // Light green
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
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.grey.shade400,
                ),
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

  Future<void> _showAddUecDialog(BuildContext context, WidgetRef ref, {VisitUec? uec}) async {
    final isEdit = uec != null;
    final nAggregato = TextEditingController(text: uec?.nAggregato);
    final descrizione = TextEditingController(text: uec?.descrizione);
    final note = TextEditingController(text: uec?.note);
    final List<TextEditingController> cultureControllers;
    if (isEdit && uec.coltura.isNotEmpty) {
      cultureControllers = uec.coltura.split(', ').map((c) => TextEditingController(text: c)).toList();
    } else {
      cultureControllers = [TextEditingController(text: defaultColtura)];
    }

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 550,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.eco_outlined, color: Color(0xFF1B5E20), size: 28),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verifica Coltura e UEC (Rev. 08)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                Text('Compila i dati di verifica e campionamento', style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECTION 1: DATI GENERALI
                              const Text('DATI GENERALI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 1.2)),
                              const SizedBox(height: 16),
                              _buildDialogInputField(controller: nAggregato, label: 'N. Aggregato', hint: 'Inserisci numero aggregato...', icon: Icons.numbers),
                              const SizedBox(height: 16),
                              _buildDialogInputField(controller: descrizione, label: 'Descrizione', hint: 'es. Vigneto Nord, Lotto 1...', icon: Icons.description_outlined, maxLines: 2),
                              const SizedBox(height: 16),
                              ...cultureControllers.asMap().entries.map((entry) {
                                final index = entry.key;
                                final controller = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(child: _buildDialogInputField(controller: controller, label: 'Coltura ${cultureControllers.length > 1 ? index + 1 : ""}', hint: 'es. Vite, Olivo...', icon: Icons.agriculture)),
                                      if (cultureControllers.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => setState(() { controller.dispose(); cultureControllers.removeAt(index); }),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              if (!isReadOnly)
                                TextButton.icon(
                                  onPressed: () => setState(() => cultureControllers.add(TextEditingController())),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Aggiungi un\'altra coltura'),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
                                ),

                              _buildDialogInputField(controller: note, label: 'Note', hint: 'Aggiungi eventuali osservazioni...', icon: Icons.notes, maxLines: 3),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                              child: const Text('Salva Dati', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (res != true) {
      nAggregato.dispose(); descrizione.dispose(); note.dispose();
      for (var c in cultureControllers) {
        c.dispose();
      }
      return;
    }

    final jointCulture = cultureControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(', ');
    final db = ref.read(appDatabaseProvider);
    await db.upsertUec(
      id: isEdit ? uec.id : _newId('UEC'),
      visitId: visitId,
      coltura: jointCulture.isNotEmpty ? jointCulture : defaultColtura,
      descrizione: descrizione.text.trim(),
      nAggregato: nAggregato.text.trim(),
      note: note.text.trim(),
    );

    nAggregato.dispose(); descrizione.dispose(); note.dispose();
    for (var c in cultureControllers) {
      c.dispose();
    }
  }


  Widget _buildDialogInputField({required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, hintText: hint, filled: true, fillColor: Colors.grey.shade50, prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2)),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _pickUecPhoto(BuildContext context, WidgetRef ref, VisitUec u) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
    if (image == null) return;
    final db = ref.read(appDatabaseProvider);
    Position? pos;
    try { pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5))); } catch (_) {}
    await db.upsertUec(
      id: u.id, visitId: u.visitId, coltura: u.coltura, descrizione: u.descrizione, nAggregato: u.nAggregato, note: u.note,
      latitude: pos?.latitude ?? u.latitude, longitude: pos?.longitude ?? u.longitude, photoPath: image.path,
    );
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto UEC salvata con successo.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(visitId));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      Text('Coltura e UEC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                      if (!isReadOnly)
                        FilledButton.tonalIcon(
                          onPressed: () => _showAddUecDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Aggiungi UEC'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            foregroundColor: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (uecs.isEmpty)
                    const Padding(padding: EdgeInsets.only(top: 24), child: Text('Nessuna UEC presente. Clicca “Aggiungi UEC” per iniziare.'))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: uecs.length,
                        itemBuilder: (ctx, i) {
                          final u = uecs[i];
                          final title = u.nAggregato.isNotEmpty ? 'Agg. ${u.nAggregato} - ${u.descrizione}' : (u.descrizione.isNotEmpty ? u.descrizione : u.id);
                          return Card(
                            elevation: 4, margin: const EdgeInsets.only(bottom: 16), shadowColor: Colors.black.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ExpansionTile(
                                shape: const Border(), collapsedShape: const Border(), backgroundColor: Colors.white, collapsedBackgroundColor: Colors.white,
                                title: Row(
                                  children: [
                                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2))),
                                    if (!isReadOnly)
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1B5E20)),
                                        onPressed: () => _showAddUecDialog(context, ref, uec: u),
                                        tooltip: 'Modifica Dati UEC',
                                      ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    const Icon(Icons.eco_outlined, size: 14, color: Color(0xFF1B5E20)),
                                    const SizedBox(width: 4),
                                    Text(u.coltura, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                  ],
                                ),
                                childrenPadding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 8),
                                  if (u.note.isNotEmpty)
                                    Container(
                                      width: double.infinity, padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade100)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [Icon(Icons.notes, size: 16, color: Colors.amber.shade900), const SizedBox(width: 8), const Text('NOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))]),
                                          const SizedBox(height: 8),
                                          Text(u.note, style: TextStyle(fontSize: 14, color: Colors.amber.shade900, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [Icon(Icons.location_on_outlined, size: 16, color: Colors.blue.shade700), const SizedBox(width: 8), Text(u.latitude != null && u.longitude != null ? 'GPS: ${u.latitude!.toStringAsFixed(6)}, ${u.longitude!.toStringAsFixed(6)}' : 'GPS: Non Rilevato', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: u.latitude != null ? Colors.blue.shade900 : Colors.red))]),
                                            const SizedBox(height: 8),
                                            if (u.photoPath != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(u.photoPath!), height: 120, width: 160, fit: BoxFit.cover))
                                            else Container(height: 80, width: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: const Center(child: Text('Foto Obblig.', style: TextStyle(fontSize: 10, color: Colors.red)))),
                                          ],
                                        ),
                                      ),
                                      if (!isReadOnly)
                                        Column(
                                          children: [
                                            IconButton.filledTonal(onPressed: () => _pickUecPhoto(context, ref, u), icon: const Icon(Icons.camera_alt), tooltip: 'Scatta Foto Georeferenziata'),
                                            const SizedBox(height: 4),
                                            const Text('Foto', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (!isReadOnly) ...[
                                    const Divider(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Elimina UEC'),
                                                content: const Text('Sei sicuro di voler eliminare questa UEC? L\'operazione non è reversibile.'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
                                                ],
                                              ),
                                            );
                                            if (ok == true) { await ref.read(appDatabaseProvider).deleteUec(u.id); }
                                          },
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          label: const Text('Elimina UEC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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

class _QuadroVerificaSection extends ConsumerWidget {
  const _QuadroVerificaSection({required this.visitId, required this.isReadOnly});
  final String visitId;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(visitId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.rule_folder_rounded, size: 28, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quadro di verifica COLTIVAZIONE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade900, letterSpacing: -0.5)),
                  Text('Gestione centralizzata degli esiti e del campionamento', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          uecsAsync.when(
            data: (uecs) {
              if (uecs.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.agriculture_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nessuna UEC registrata', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Aggiungine una nella sezione "Coltura e UEC"', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              }
              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: uecs.length,
                  itemBuilder: (context, index) {
                    final u = uecs[index];
                    return _UecVerificationCard(uec: u, isReadOnly: isReadOnly);
                  },
                ),
              );
            },
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => Expanded(child: Center(child: Text('Errore: $e'))),
          ),
        ],
      ),
    );
  }
}

class _UecVerificationCard extends ConsumerWidget {
  const _UecVerificationCard({required this.uec, required this.isReadOnly});
  final VisitUec uec;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = uec.nAggregato.isNotEmpty ? 'Agg. ${uec.nAggregato} - ${uec.descrizione}' : (uec.descrizione.isNotEmpty ? uec.descrizione : uec.id);
    final isCompleteAsync = ref.watch(isUecChecklistCompleteProvider((visitId: uec.visitId, uecId: uec.id)));
    final samplesAsync = ref.watch(samplesByVisitIdProvider(uec.visitId));
    final samples = samplesAsync.value ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          initiallyExpanded: true,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.agriculture_rounded, color: Color(0xFF1B5E20), size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF263238))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.label_important_outline, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(uec.coltura, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isCompleteAsync.when(
                data: (isComplete) {
                  final isFilled = uec.sqnpiConsistency.isNotEmpty && uec.sqnpiCompliance.isNotEmpty;
                  if (isFilled) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.2))),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                          SizedBox(width: 6),
                          Text('Dati Completati', style: TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_outlined, color: Colors.orange.shade800, size: 14),
                        const SizedBox(width: 6),
                        const Text('Da Completare', style: TextStyle(color: Color(0xFFBF360C), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.expand_more_rounded, color: Colors.grey),
            ],
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Notice 
                isCompleteAsync.when(
                  data: (isComplete) => isComplete 
                     ? const SizedBox.shrink()
                     : Container(
                         margin: const EdgeInsets.only(bottom: 32),
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                         decoration: BoxDecoration(
                           color: Colors.orange.shade50, 
                           borderRadius: BorderRadius.circular(16), 
                           border: Border.all(color: Colors.orange.shade200, width: 1),
                         ),
                         child: Row(
                           children: [
                             Icon(Icons.info_rounded, color: Colors.orange.shade800, size: 24),
                             const SizedBox(width: 16),
                             const Expanded(child: Text('La checklist per questa UEC non è ancora completa. Assicurati di compilare Coerenza e Conformità dopo aver risposto a tutte le domande.', style: TextStyle(fontSize: 13, color: Color(0xFFBF360C), fontWeight: FontWeight.w600, height: 1.4))),
                           ],
                         ),
                       ),
                  loading: () => const Padding(padding: EdgeInsets.only(bottom: 32), child: LinearProgressIndicator()),
                  error: (e, stack) => const SizedBox.shrink(),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: SQNPI Outcomes
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('OUTCOME SQNPI', Icons.assignment_turned_in_outlined),
                          const SizedBox(height: 24),
                          const _DialogSectionHeader(title: 'Coerenza con domanda SQNPI'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'Si', label: Text('Si', style: TextStyle(fontWeight: FontWeight.bold))),
                                ButtonSegment(value: 'No', label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                                ButtonSegment(value: 'N/A', label: Text('N/A', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              selected: {uec.sqnpiConsistency},
                              onSelectionChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(sqnpiConsistency: val.first)),
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: const Color(0xFF1B5E20),
                                selectedForegroundColor: Colors.white,
                                visualDensity: VisualDensity.comfortable,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _DialogSectionHeader(title: 'Conformità con standard SQNPI'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'Si', label: Text('Si', style: TextStyle(fontWeight: FontWeight.bold))),
                                ButtonSegment(value: 'No', label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                                ButtonSegment(value: 'N/A', label: Text('N/A', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              selected: {uec.sqnpiCompliance},
                              onSelectionChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(sqnpiCompliance: val.first)),
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: const Color(0xFF1B5E20),
                                selectedForegroundColor: Colors.white,
                                visualDensity: VisualDensity.comfortable,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // RIGHT COLUMN: Switches and Process
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('DETTAGLI VERIFICA', Icons.fact_check_outlined),
                          const SizedBox(height: 12),
                          _buildModernSwitchTile(
                            title: 'Prodotto Identificabile',
                            subtitle: 'Verifica tracciabilità e identificazione',
                            value: uec.isTraceable,
                            onChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(isTraceable: val)),
                            icon: Icons.qr_code_scanner_rounded,
                          ),
                          _buildModernSwitchTile(
                            title: 'Reclami Presenti',
                            subtitle: 'Segnalazione di reclami sul prodotto',
                            value: uec.hasClaims,
                            isNegative: true,
                            onChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(hasClaims: val)),
                            icon: Icons.report_problem_outlined,
                          ),
                          _buildModernSwitchTile(
                            title: 'Processo Verificato in Campo',
                            subtitle: 'Sopralluogo e verifica processi produttivi',
                            value: uec.isFieldProcessVerified,
                            onChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(isFieldProcessVerified: val)),
                            icon: Icons.visibility_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Divider(height: 1),
                ),

                // SAMPLING SECTION
                _buildSectionLabel('ATTIVITÀ DI CAMPIONAMENTO', Icons.science_outlined),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildModernSwitchTile(
                        title: 'Campionamento Effettuato',
                        subtitle: 'Indica se è stato prelevato un campione',
                        value: uec.hasSampling,
                        onChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(hasSampling: val)),
                        icon: Icons.biotech_outlined,
                      ),
                    ),
                    const SizedBox(width: 48),
                    if (uec.hasSampling)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('Lotto di Riferimento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5)),
                             const SizedBox(height: 12),
                             DropdownButtonFormField<String>(
                              initialValue: uec.samplingLotId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1B5E20)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5)),
                              ),
                              items: samples.isEmpty 
                                ? [const DropdownMenuItem(value: null, child: Text('Nessun campione disponibile'))]
                                : samples.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.sampleCode} - ${s.matrixType}'))).toList(),
                              onChanged: isReadOnly ? null : (val) => _updateUec(ref, uec.copyWith(samplingLotId: Value(val))),
                            ),
                            if (samples.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(top: 12, left: 4),
                                 child: Row(
                                   children: [
                                     Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                                     const SizedBox(width: 8),
                                     Text('Registra prima un campione nell\'area dedicata', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                                   ],
                                 ),
                               ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                // SECTION: NOTES
                _buildSectionLabel('NOTE E OSSERVAZIONI', Icons.note_alt_outlined),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: uec.note,
                  maxLines: 4,
                  minLines: 2,
                  readOnly: isReadOnly,
                  onChanged: (val) => _updateUec(ref, uec.copyWith(note: val)),
                  decoration: InputDecoration(
                    hintText: 'Inserisci qui eventuali note o osservazioni...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5)),
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF263238), height: 1.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    required IconData icon,
    bool isNegative = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value 
          ? (isNegative ? Colors.red.shade50.withValues(alpha: 0.3) : const Color(0xFF1B5E20).withValues(alpha: 0.03)) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value 
            ? (isNegative ? Colors.red.shade100 : const Color(0xFF1B5E20).withValues(alpha: 0.1)) 
            : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF263238))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        secondary: Icon(icon, color: value ? (isNegative ? Colors.red : const Color(0xFF1B5E20)) : Colors.grey.shade400),
        value: value,
        activeTrackColor: isNegative ? Colors.red.shade200 : const Color(0xFF81C784),
        activeThumbColor: isNegative ? Colors.red.shade800 : const Color(0xFF1B5E20),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
  

  Future<void> _updateUec(WidgetRef ref, VisitUec u) async {
    await ref.read(appDatabaseProvider).upsertUec(
      id: u.id,
      visitId: u.visitId,
      coltura: u.coltura,
      descrizione: u.descrizione,
      nAggregato: u.nAggregato,
      note: u.note,
      sqnpiConsistency: u.sqnpiConsistency,
      sqnpiCompliance: u.sqnpiCompliance,
      isTraceable: u.isTraceable,
      hasClaims: u.hasClaims,
      isFieldProcessVerified: u.isFieldProcessVerified,
      hasSampling: u.hasSampling,
      samplingLotId: u.samplingLotId,
      photoPath: u.photoPath,
      latitude: u.latitude,
      longitude: u.longitude,
    );
  }
}

class _DialogSectionHeader extends StatelessWidget {
  final String title;
  const _DialogSectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)));
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

  Future<void> _pickIdentityDoc(
    BuildContext context,
    WidgetRef ref,
    String sigId,
  ) async {
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
                    signerName: representativeSig?.signerName ?? 'Titolare',
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
                        ? () => _pickIdentityDoc(
                            context,
                            ref,
                            representativeSig.id,
                          )
                        : null,
                  ),
                  _SignatureCard(
                    title: 'Delegato Aziendale',
                    signerName: delegateSig?.signerName ?? 'Sostituto delegato',
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
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
    final purchased =
        double.tryParse(_purchased.text.replaceAll(',', '.')) ?? 0;
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
                            border: Border.all(color: Colors.teal.shade200),
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
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue.shade400,
                              size: 18,
                            ),
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
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
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
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
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
            subtitle:
                'Fatture di acquisto, bolle di consegna, registri di carico',
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
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Note aggiuntive sulla documentazione verificata...',
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
                      Icon(Icons.folder_open, color: Colors.grey.shade400),
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
                                      onPressed: () => Navigator.pop(ctx, true),
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
            maxLines: null,
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

  Future<List<String>> _getIncompleteUecNames() async {
    final db = ref.read(appDatabaseProvider);
    final visit = await db.watchVisitById(widget.visitId).first;
    if (visit == null) return [];

    final uecs = await db.watchUecsByVisitId(widget.visitId).first;
    final allFasi = await db.watchFasi().first;
    final visitType = visit.visitType;
    final filteredFasi = allFasi.where((f) => isPhaseVisible(f, visitType)).toList();
    if (filteredFasi.isEmpty) return [];

    // Fetch all applicable items once for these phases
    List<ChecklistItem> allApplicableItems = [];
    for (var f in filteredFasi) {
      final items = await db.watchChecklistItemsByFase(f).first;
      allApplicableItems.addAll(items);
    }

    // Requirements are items that are NOT headers
    final requirements = allApplicableItems.where((item) {
      final codeTrimmed = item.code.trim();
      return !(!codeTrimmed.contains('.') ||
          RegExp(r'\.0$').hasMatch(codeTrimmed) ||
          RegExp(r'\.(?!\d)').hasMatch(codeTrimmed));
    }).toList();

    if (requirements.isEmpty) return [];

    List<String> missing = [];
    for (final uec in uecs) {
      final responses = await db.watchResponsesByUecId(uec.id).first;
      final respondedCodes = responses.map((r) => r.itemCode).toSet();
      final isComplete = requirements.every((item) => respondedCodes.contains(item.code));

      if (isComplete) {
        if (uec.sqnpiConsistency.isEmpty || uec.sqnpiCompliance.isEmpty) {
          missing.add(uec.nAggregato.isNotEmpty ? 'UEC ${uec.nAggregato}' : uec.descrizione);
        }
      }
    }
    return missing;
  }

  void _showValidationErrorDialog(List<String> missingUecs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Dati Mancanti', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le seguenti UEC hanno la checklist completata ma mancano gli esiti SQNPI (Coerenza/Conformità):'),
            const SizedBox(height: 16),
            ...missingUecs.map((name) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $name', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            )),
            const SizedBox(height: 16),
            const Text('Imposta gli esiti nella sezione "Coltura e UEC" prima di chiudere la visita.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ho capito', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isClosed) {
      final missing = await _getIncompleteUecNames();
      if (missing.isNotEmpty) {
        if (mounted) {
          _showValidationErrorDialog(missing);
        }
        return;
      }
    }

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
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
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
              content: Text(
                success
                    ? 'Dati inviati correttamente al gestionale.'
                    : 'Errore durante la sincronizzazione col gestionale.',
              ),
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
              maxLines: null,
              keyboardType: TextInputType.multiline,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 28,
                                  ),
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
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    12,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Attiva "Visita Chiusa"',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color:
                                                          Colors.amber.shade900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Devi abilitare il toggle prima di poter confermare la chiusura.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.amber.shade800,
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
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    24,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueGrey.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ho capito',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

  Future<void> _showAddSampleDialog([VisitSample? sample]) async {
    final producerCtrl = TextEditingController(text: sample?.producerName);
    final producerCodeCtrl = TextEditingController(text: sample?.producerCode);
    final lotGeorefCtrl =
        TextEditingController(text: sample?.lotNumberGeoref);
    final inspectorCtrl = TextEditingController(text: sample?.inspectorName);
    final inspectorCodeCtrl =
        TextEditingController(text: sample?.inspectorCode);
    final matrixCtrl = TextEditingController(text: sample?.matrixType);
    final sealCtrl = TextEditingController(text: sample?.sealNumber);
    final codeCtrl = TextEditingController(text: sample?.sampleCode);

    // Initial photo list
    final List<String> photos =
        sample?.photoPaths.split(',').where((p) => p.isNotEmpty).toList() ??
        [];

    // Inspection date pre-filled from visit summary logic
    // We can fetch it once if needed, but for now we'll use DateTime.now() or visit scheduled date if available
    // For this context, let's assume we want to match the visit's scheduled date as requested
    final visit = await ref.read(appDatabaseProvider).watchVisitById(widget.visitId).first;
    if (!mounted) return;
    final inspectionDate = visit?.scheduledAt ?? DateTime.now();

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 600,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.science_outlined,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sample == null
                                      ? 'Registra Nuovo Campione'
                                      : 'Dettagli Campione',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  'M904 Rev. 08 - Sezione Campionamento',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildInputField(
                                      controller: producerCtrl,
                                      label: 'Produttore / Azienda',
                                      icon: Icons.business,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: _buildInputField(
                                      controller: producerCodeCtrl,
                                      label: 'Codice Bios',
                                      icon: Icons.numbers,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: lotGeorefCtrl,
                                label: 'Numero Lotto Georeferenziato',
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      controller: inspectorCtrl,
                                      label: 'Ispettore',
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      controller: inspectorCodeCtrl,
                                      label: 'Codice Ispettore',
                                      icon: Icons.badge_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      controller: matrixCtrl,
                                      label: 'Matrice Campionata',
                                      icon: Icons.grass,
                                      hint: 'es. Uva, Foglie...',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      controller: sealCtrl,
                                      label: 'Numero Sigillo',
                                      icon: Icons.lock_outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: codeCtrl,
                                label: 'Codice Identificativo Campione',
                                icon: Icons.qr_code,
                              ),
                              const SizedBox(height: 24),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DOCUMENTAZIONE FOTOGRAFICA (Minimo 3)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PhotoManagerGrid(
                                photos: photos,
                                onAdd: () async {
                                  final source =
                                      await _showImageSourcePicker();
                                  if (source != null) {
                                    final img = await _picker.pickImage(
                                      source: source,
                                      imageQuality: 70,
                                    );
                                    if (img != null) {
                                      setState(() => photos.add(img.path));
                                    }
                                  }
                                },
                                onRemove: (idx) {
                                  setState(() => photos.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: photos.length >= 3
                                  ? () => Navigator.pop(ctx, true)
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                photos.length >= 3
                                    ? 'Salva Campione'
                                    : 'Aggiungi ${3 - photos.length} foto',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (res == true) {
      final db = ref.read(appDatabaseProvider);
      final id = sample?.id ??
          'SMP-${widget.visitId}-${DateTime.now().millisecondsSinceEpoch}';

      await db.upsertSample(
        id: id,
        visitId: widget.visitId,
        producerName: producerCtrl.text,
        producerCode: producerCodeCtrl.text,
        lotNumberGeoref: lotGeorefCtrl.text,
        inspectorName: inspectorCtrl.text,
        inspectorCode: inspectorCodeCtrl.text,
        matrixType: matrixCtrl.text,
        sealNumber: sealCtrl.text,
        sampleCode: codeCtrl.text,
        inspectionDate: inspectionDate,
        photoPaths: photos.join(','),
      );
    }

    producerCtrl.dispose();
    producerCodeCtrl.dispose();
    lotGeorefCtrl.dispose();
    inspectorCtrl.dispose();
    inspectorCodeCtrl.dispose();
    matrixCtrl.dispose();
    sealCtrl.dispose();
    codeCtrl.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.sampleCode.isEmpty
                                      ? 'Campione senza codice'
                                      : s.sampleCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: s.photoPaths.split(',').length >= 3
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 12,
                                      color: s.photoPaths.split(',').length >= 3
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${s.photoPaths.split(',').where((p) => p.isNotEmpty).length} foto',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: s.photoPaths.split(',').length >= 3
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Produttore: ${s.producerName} (${s.producerCode})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Matrice: ${s.matrixType} • Sigillo: ${s.sealNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Ispettore: ${s.inspectorName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
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

class _PhotoManagerGrid extends StatelessWidget {
  const _PhotoManagerGrid({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: photos.length + 1,
      itemBuilder: (ctx, i) {
        if (i == photos.length) {
          return InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.blue),
            ),
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photos[i]),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
