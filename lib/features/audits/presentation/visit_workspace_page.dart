import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:drift/drift.dart' show Value;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';
import '../../../core/services/geocoding_service.dart';

import 'checklist_page.dart';
import 'final_evaluation_page.dart';
import 'nc_page.dart';
import 'attachments_page.dart';
import 'report_page.dart';
import '../application/report_provider.dart';
import '../application/audit_stats_provider.dart';
import '../application/management_sync_service.dart';
import 'widgets/signature_dialog.dart';
import 'widgets/post_raccolta_section.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../admin/application/activity_logger.dart';
import '../../../core/widgets/help_tooltip.dart';
import '../../../core/constants/help_texts.dart';

// Provider per il conteggio allegati (badge nella NavigationRail)
final _attachmentCountProvider = StreamProvider.family<int, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAttachmentsByVisitId(visitId).map((list) => list.length);
});

// Provider per la lista allegati (usato da _DocumentiRiferimentoSection)
final _attachmentsListProvider =
    StreamProvider.family<List<VisitAttachment>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchAttachmentsByVisitId(visitId);
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

// isNewOperatorVisibilityProvider rimosso perché la sezione è ora sempre visibile

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

final massBalancesByVisitIdProvider =
    StreamProvider.family<List<MassBalanceRecord>, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalancesByVisitId(id);
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

final previousNcManagementByVisitIdProvider =
    StreamProvider.family<VisitPreviousNcManagement?, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchPreviousNcManagementByVisitId(id);
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
    final isMobile = MediaQuery.of(context).size.width < 800 || MediaQuery.of(context).size.height < 500;
    final visitAsync = ref.watch(visitByIdProvider(widget.visitId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? _buildDrawer(context, visitAsync) : null,
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
      body: _buildBody(context, isMobile, visitAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isMobile,
    AsyncValue<Visit?> visitAsync,
  ) {
    return visitAsync.when(
      data: (visit) {
        if (visit == null) {
          return const Center(child: Text('Visita non trovata.'));
        }

        final isReadOnly = widget.forceReadOnly || visit.status >= 2;

        final List<({NavigationRailDestination dest, Widget page})> navItems = [
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
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: Text('Anagrafica azienda'),
            ),
            page: _AziendaSection(
              visitId: visit.id,
              defaultCompanyName: visit.companyName,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: Text('Scopo Controllo'),
            ),
            page: _ScopoControlloSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: Text(
                'Documenti di rif.\ne visionati',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
            page: _DocumentiRiferimentoSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_toggle_off_rounded),
              label: Text(
                'Gestione NC e\nazioni corr.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
            page: _GestioneNcPrecedentiSection(
              visitId: visit.id,
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
              icon: Icon(Icons.rule_folder_outlined),
              selectedIcon: Icon(Icons.rule_folder),
              label: Text('Coltivazione'),
            ),
            page: _QuadroVerificaSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: Text('Bilancio di massa'),
            ),
            page: _MassBalanceSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          if (visit.visitType.contains('MARCHIO'))
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.conveyor_belt),
                selectedIcon: Icon(Icons.conveyor_belt),
                label: Text('Post-raccolta'),
              ),
              page: PostRaccoltaSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning),
              label: Text('Attività'),
            ),
            page: NcPage(visitId: visit.id, isReadOnly: isReadOnly),
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
              icon: Icon(Icons.ads_click_rounded), // Premium feel
              selectedIcon: Icon(Icons.ads_click),
              label: Text(
                'Valutazione\nFinale',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
            page: FinalEvaluationPage(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.draw_outlined),
              selectedIcon: Icon(Icons.draw),
              label: Text('Firme'),
            ),
            page: _SignatureSection(visitId: visit.id, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel),
              label: Text('Chiusura'),
            ),
            page: _DurataChiusuraSection(visit: visit, isReadOnly: isReadOnly),
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

        if (isMobile) {
          return Container(
            color: const Color(0xFFF8F9FA),
            child: IndexedStack(
              index: _selectedIndex,
              children: navItems.map((e) => e.page).toList(),
            ),
          );
        }

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        return Row(
          children: [
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, isLandscape ? 32 : 48, 20, 24),
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
                        ),
                        const SliverToBoxAdapter(
                          child: Divider(indent: 20, endIndent: 20),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: NavigationRail(
                            selectedIndex: _selectedIndex.clamp(
                              0,
                              navItems.isEmpty ? 0 : navItems.length - 1,
                            ),
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
                      ],
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
    );
  }

  Widget _buildDrawer(BuildContext context, AsyncValue<Visit?> visitAsync) {
    return visitAsync.when(
      data: (visit) {
        if (visit == null) return const Drawer();

        final isReadOnly = widget.forceReadOnly || visit.status >= 2;
        final List<({NavigationRailDestination dest, Widget page})> navItems = [
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
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: Text('Anagrafica azienda'),
            ),
            page: _AziendaSection(
              visitId: visit.id,
              defaultCompanyName: visit.companyName,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: Text('Scopo Controllo'),
            ),
            page: _ScopoControlloSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user),
              label: Text('Documenti'),
            ),
            page: _DocumentiRiferimentoSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_toggle_off_rounded),
              label: Text('Gestione NC'),
            ),
            page: _GestioneNcPrecedentiSection(
              visitId: visit.id,
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
              icon: Icon(Icons.rule_folder_outlined),
              selectedIcon: Icon(Icons.rule_folder),
              label: Text('Coltivazione'),
            ),
            page: _QuadroVerificaSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: Text('Bilancio di massa'),
            ),
            page: _MassBalanceSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          if (visit.visitType.contains('MARCHIO'))
            (
              dest: const NavigationRailDestination(
                icon: Icon(Icons.conveyor_belt),
                selectedIcon: Icon(Icons.conveyor_belt),
                label: Text('Post-raccolta'),
              ),
              page: PostRaccoltaSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning),
              label: Text('Attività'),
            ),
            page: NcPage(visitId: visit.id, isReadOnly: isReadOnly),
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
              icon: Icon(Icons.ads_click_rounded),
              selectedIcon: Icon(Icons.ads_click),
              label: Text('Valutazione Finale'),
            ),
            page: FinalEvaluationPage(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.draw_outlined),
              selectedIcon: Icon(Icons.draw),
              label: Text('Firme'),
            ),
            page: _SignatureSection(visitId: visit.id, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel),
              label: Text('Chiusura'),
            ),
            page: _DurataChiusuraSection(visit: visit, isReadOnly: isReadOnly),
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

        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VERBALE ISPEZIONE',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
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
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: navItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = _selectedIndex == index;
                    return ListTile(
                      leading: isSelected
                          ? item.dest.selectedIcon
                          : item.dest.icon,
                      title: Text(
                        (item.dest.label as Text).data ?? '',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.05),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Chiudi Workspace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Drawer(child: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Drawer(child: Center(child: Text('Errore: ${e.toString()}'))),
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
            Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Acquisita bozza etichetta',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Se siamo su schermi piccoli (mobile), occupiamo tutto lo spazio meno il padding della pagina
        // Altrimenti usiamo una larghezza fissa o basata sul wrap.
        // 16 è lo spacing del Wrap padre.
        final cardWidth = screenWidth < 640 ? constraints.maxWidth : 300.0;

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
                    if (title == 'MARCHIO' &&
                        !types.contains('CAMPIONAMENTO')) {
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
            width: cardWidth,
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
                    color: isSelected
                        ? Colors.blue.shade900
                        : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final d = widget.visit.scheduledAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final companyAsync = ref.watch(companyByVisitIdProvider(widget.visit.id));
    final company = companyAsync.valueOrNull;
    final submissionNumber =
        (company == null || company.submissionNumber.isEmpty)
        ? '-'
        : company.submissionNumber;

    final sqnpiDate = company?.sqnpiSubmissionDate;
    final sqnpiDateStr = sqnpiDate != null
        ? '${sqnpiDate.day.toString().padLeft(2, '0')}/${sqnpiDate.month.toString().padLeft(2, '0')}/${sqnpiDate.year}'
        : '-';
    final sqnpiProtocol = (company == null || company.sqnpiProtocol.isEmpty)
        ? '-'
        : company.sqnpiProtocol;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000
                  ? 4
                  : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _infoCard(
                    context,
                    title: 'Data Visita',
                    value: dateStr,
                    icon: Icons.calendar_today,
                    color: Colors.blue.shade700,
                  ),
                  _infoCard(
                    context,
                    title: 'Stato Visita',
                    value: visitStatusLabel(widget.visit.status),
                    icon: Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
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
                  _infoCard(
                    context,
                    title: 'Scopo Controllo',
                    value: widget.visit.visitType
                        .split(',')
                        .where(
                          (s) =>
                              s.isNotEmpty &&
                              !s.contains('Controllo SQNPI') &&
                              !s.contains('Auto-creato'),
                        )
                        .join(' + '),
                    icon: Icons.assignment_outlined,
                    color: Colors.orange.shade700,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _infoCard(
                    context,
                    title: 'Data domanda SQNPI',
                    value: sqnpiDateStr,
                    icon: Icons.event_note_outlined,
                    color: Colors.indigo.shade600,
                  ),
                  _infoCard(
                    context,
                    title: 'Numero domanda',
                    value: submissionNumber,
                    subtitle: 'Adesione SQNPI',
                    icon: Icons.description_outlined,
                    color: Colors.purple.shade700,
                  ),
                  _infoCard(
                    context,
                    title: 'Protocollo',
                    value: sqnpiProtocol,
                    icon: Icons.tag_rounded,
                    color: Colors.blueGrey.shade700,
                  ),
                ],
              );
            },
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: isMobile
                                    ? double.infinity
                                    : (constraints.maxWidth - 40) / 2,
                                child: _nameField(
                                  'Ispettore RGVI',
                                  _inspectorController,
                                  Icons.badge_outlined,
                                  'Nome dell\'ispettore',
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? double.infinity
                                    : (constraints.maxWidth - 40) / 2,
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
                          Wrap(
                            spacing: 16,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: isMobile
                                    ? double.infinity
                                    : (constraints.maxWidth - 40) / 2,
                                child: _nameField(
                                  'Rappresentante Aziendale / Delegato',
                                  _representativeController,
                                  Icons.business_center_outlined,
                                  'Nome del legale rappresentante o suo delegato',
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? double.infinity
                                    : (constraints.maxWidth - 40) / 2,
                                child: _nameField(
                                  'Altri Operatori Presenti',
                                  _otherOperatorsController,
                                  Icons.people_outline,
                                  'Nomi altri operatori (se presenti)',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
    return Container(
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
    );
  }
}

Widget _durationSlider(
  BuildContext context,
  WidgetRef ref,
  Visit visit,
  bool isReadOnly,
  bool isMobile,
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
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
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
              )
            : Row(
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
          child: SizedBox(
            height: 20,
            child: Stack(
              children: [
                _buildSliderLabel(0, '0h'),
                _buildSliderLabel(4, '4h'),
                _buildSliderLabel(8, '8h (1gg)', isBold: true),
                _buildSliderLabel(12, '12h'),
                _buildSliderLabel(16, '16h (2gg)', isBold: true),
                _buildSliderLabel(24, '24h'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSliderLabel(int hour, String label, {bool isBold = false}) {
  return Align(
    alignment: FractionalOffset(hour / 24, 0),
    child: FractionalTranslation(
      translation: Offset(
        hour == 0
            ? 0
            : hour == 24
            ? -1
            : -0.5,
        0,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
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

// _DurataSection removed, integrated into _DurataChiusuraSection

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

  // Sede Operativa
  final _sedeOperativaIndirizzo = TextEditingController();
  final _sedeOperativaCap = TextEditingController();
  final _sedeOperativaComune = TextEditingController();
  final _sedeOperativaProvincia = TextEditingController();
  final _sedeOperativaLatitude = TextEditingController();
  final _sedeOperativaLongitude = TextEditingController();

  final _manipulationSiteAddress = TextEditingController();
  final _manipulationSiteCap = TextEditingController();
  final _manipulationSiteComune = TextEditingController();
  final _manipulationSiteProvincia = TextEditingController();
  final _jointVisitDetails = TextEditingController();
  final _previousOdcName = TextEditingController();
  String? _previousOdcOutcomesPath;

  bool _loaded = false;
  bool _saving = false;

  bool _isNewOperator = false; // M904

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
    _sedeOperativaIndirizzo.dispose();
    _sedeOperativaCap.dispose();
    _sedeOperativaComune.dispose();
    _sedeOperativaProvincia.dispose();
    _sedeOperativaLatitude.dispose();
    _sedeOperativaLongitude.dispose();
    _manipulationSiteAddress.dispose();
    _manipulationSiteCap.dispose();
    _manipulationSiteComune.dispose();
    _manipulationSiteProvincia.dispose();
    _jointVisitDetails.dispose();
    _previousOdcName.dispose();
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
    _sedeOperativaIndirizzo.text = c?.sedeOperativaIndirizzo ?? '';
    _sedeOperativaCap.text = c?.sedeOperativaCap ?? '';
    _sedeOperativaComune.text = c?.sedeOperativaComune ?? '';
    _sedeOperativaProvincia.text = c?.sedeOperativaProvincia ?? '';
    _sedeOperativaLatitude.text = c?.latitudeText ?? '';
    _sedeOperativaLongitude.text = c?.longitudeText ?? '';
    _isNewOperator = c?.isNewOperator ?? false;
    _manipulationSiteAddress.text = c?.manipulationSiteAddress ?? '';
    _manipulationSiteCap.text = c?.manipulationSiteCap ?? '';
    _manipulationSiteComune.text = c?.manipulationSiteComune ?? '';
    _manipulationSiteProvincia.text = c?.manipulationSiteProvincia ?? '';
    _peakPeriodFrom = (c?.peakPeriodFrom.isNotEmpty ?? false)
        ? c?.peakPeriodFrom
        : null;
    _isJointVisit = c?.isJointVisit ?? false;
    _jointVisitDetails.text = c?.jointVisitDetails ?? '';
    _previousOdcName.text = c?.previousOdcName ?? '';
    _previousOdcOutcomesPath = (c?.previousOdcOutcomes.isNotEmpty ?? false)
        ? c?.previousOdcOutcomes
        : null;
  }

  Future<void> _pickPreviousOdcFile() async {
    if (widget.isReadOnly) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final destPath = await _copyToAppStorage(result.files.single.path!);
      setState(() {
        _previousOdcOutcomesPath = destPath;
      });
    }
  }

  Future<String> _copyToAppStorage(String srcPath) async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'visit_files', widget.visitId));
    if (!await dir.exists()) await dir.create(recursive: true);
    final filename =
        'previousOdc_${DateTime.now().millisecondsSinceEpoch}${p.extension(srcPath)}';
    final destPath = p.join(dir.path, filename);
    await File(srcPath).copy(destPath);
    return destPath;
  }

  Future<void> _openFile(String path) async {
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
        isNewOperator: _isNewOperator,
        processingType: 'proprio', // Defaulted as field was removed
        thirdPartyCertNumber: '', // Defaulted as field was removed
        sedeOperativaProvincia: _sedeOperativaProvincia.text.trim(),
        manipulationSiteAddress: _manipulationSiteAddress.text.trim(),
        manipulationSiteCap: _manipulationSiteCap.text.trim(),
        manipulationSiteComune: _manipulationSiteComune.text.trim(),
        manipulationSiteProvincia: _manipulationSiteProvincia.text.trim(),
        peakPeriodFrom: _peakPeriodFrom ?? '',
        peakPeriodTo: '',
        isJointVisit: _isJointVisit,
        jointVisitDetails: _jointVisitDetails.text.trim(),
        previousOdcName: _previousOdcName.text.trim(),
        previousOdcOutcomes: _previousOdcOutcomesPath ?? '',
        latitudeText: _sedeOperativaLatitude.text.trim(),
        longitudeText: _sedeOperativaLongitude.text.trim(),
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

  Future<void> _geocodeSedeOperativa() async {
    final address = _sedeOperativaIndirizzo.text.trim();
    final city = _sedeOperativaComune.text.trim();
    final cap = _sedeOperativaCap.text.trim();
    final province = _sedeOperativaProvincia.text.trim();

    if (address.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci almeno indirizzo e comune.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final coords = await ref
          .read(geocodingServiceProvider)
          .getCoordinates(
            address: address,
            city: city,
            province: province,
            postalCode: cap,
          );

      if (coords != null) {
        if (coords.error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(coords.error!),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() {
            _sedeOperativaLatitude.text = coords.lat.toString();
            _sedeOperativaLongitude.text = coords.lon.toString();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Coordinate calcolate con successo.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossibile trovare l\'indirizzo specificato.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore imprevisto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                title: 'Sede Legale',
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
                ],
              ),
              const SizedBox(height: 24),
              _FormGroup(
                title: 'Sede Operativa',
                icon: Icons.map_outlined,
                children: [
                  _field(
                    'Indirizzo',
                    _sedeOperativaIndirizzo,
                    flex: 2,
                    icon: Icons.location_on_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: IconButton.filled(
                      onPressed: widget.isReadOnly
                          ? null
                          : _geocodeSedeOperativa,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
                      tooltip: 'Calcola coordinate dall\'indirizzo',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade100,
                        foregroundColor: Colors.blueGrey.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  _field('Comune', _sedeOperativaComune, flex: 1),
                  _field('CAP', _sedeOperativaCap, width: 120),
                  _field('Provincia', _sedeOperativaProvincia, width: 80),
                  _field(
                    'Latitudine',
                    _sedeOperativaLatitude,
                    width: 180,
                    icon: Icons.location_on_outlined,
                  ),
                  _field(
                    'Longitudine',
                    _sedeOperativaLongitude,
                    width: 180,
                    icon: Icons.location_on_outlined,
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
                    flex: 2,
                    icon: Icons.location_on_outlined,
                  ),
                  _field('Comune', _manipulationSiteComune, flex: 1),
                  _field('CAP', _manipulationSiteCap, width: 120),
                  _field('Provincia', _manipulationSiteProvincia, width: 80),
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
                    (v) {
                      setState(() => _isNewOperator = v);
                    },
                    subtitle: 'Se attivo, sblocca la verifica OdC precedente',
                  ),
                  if (_isNewOperator) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          'Nome precedente OdC',
                          _previousOdcName,
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 16),
                        _odcAttachmentField(),
                      ],
                    ),
                  ],
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

              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 4),
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

  Widget _odcAttachmentField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth > 700
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        final hasFile = _previousOdcOutcomesPath != null;
        final filename = hasFile
            ? p.basename(_previousOdcOutcomesPath!)
            : 'Nessun file';

        return SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_edu_outlined,
                  color: Colors.blueGrey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Esiti verifica precedente (Allegato)',
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        filename,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasFile
                              ? Colors.blueGrey.shade900
                              : Colors.blueGrey.shade300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasFile) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
                    onPressed: () => _openFile(_previousOdcOutcomesPath!),
                    tooltip: 'Visualizza',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: widget.isReadOnly
                        ? null
                        : () => setState(() => _previousOdcOutcomesPath = null),
                    tooltip: 'Rimuovi',
                  ),
                ] else
                  TextButton.icon(
                    onPressed: widget.isReadOnly ? null : _pickPreviousOdcFile,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('Scegli File'),
                  ),
              ],
            ),
          ),
        );
      },
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
    final helpText = HelpTexts.get(label);

    // Calcoliamo una larghezza approssimativa basata sul flex se non fornita
    // In un Wrap, usiamo SizedBox per dare una base.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            width ??
            (constraints.maxWidth > 700
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
              suffixIcon: helpText != null ? HelpTooltip(text: helpText) : null,
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
    final helpText = HelpTexts.get(label);

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
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (helpText != null) HelpTooltip(text: helpText),
                ],
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
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueGrey.shade500,
                    letterSpacing: 1.2,
                  ),
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

  Future<void> _showAddUecDialog(
    BuildContext context,
    WidgetRef ref, {
    VisitUec? uec,
  }) async {
    final isEdit = uec != null;
    final nAggregato = TextEditingController(text: uec?.nAggregato);
    final note = TextEditingController(text: uec?.note);
    final List<TextEditingController> cultureControllers;
    if (isEdit && uec.coltura.isNotEmpty) {
      cultureControllers = uec.coltura
          .split(', ')
          .map((c) => TextEditingController(text: c))
          .toList();
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
                  constraints: const BoxConstraints(maxWidth: 550),
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
                              color: const Color(
                                0xFF1B5E20,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              color: Color(0xFF1B5E20),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verifica Coltura e UEC (Rev. 08)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Compila i dati di verifica e campionamento',
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECTION 1: DATI GENERALI
                              const Text(
                                'DATI GENERALI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDialogInputField(
                                controller: nAggregato,
                                label: 'N. Aggregato',
                                hint: 'Inserisci numero aggregato...',
                                icon: Icons.numbers,
                              ),
                              const SizedBox(height: 16),
                              ...cultureControllers.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final controller = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildDialogInputField(
                                          controller: controller,
                                          label:
                                              'Coltura ${cultureControllers.length > 1 ? index + 1 : ""}',
                                          hint: 'es. Vite, Olivo...',
                                          icon: Icons.agriculture,
                                        ),
                                      ),
                                      if (cultureControllers.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => setState(() {
                                            controller.dispose();
                                            cultureControllers.removeAt(index);
                                          }),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              if (!isReadOnly)
                                TextButton.icon(
                                  onPressed: () => setState(
                                    () => cultureControllers.add(
                                      TextEditingController(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'Aggiungi un\'altra coltura',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                  ),
                                ),

                              _buildDialogInputField(
                                controller: note,
                                label: 'Note',
                                hint: 'Aggiungi eventuali osservazioni...',
                                icon: Icons.notes,
                                maxLines: 3,
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
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
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
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Salva Dati',
                                style: TextStyle(
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

    if (res != true) {
      nAggregato.dispose();
      note.dispose();
      for (var c in cultureControllers) {
        c.dispose();
      }
      return;
    }

    final jointCulture = cultureControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join(', ');
    final db = ref.read(appDatabaseProvider);
    await db.upsertUec(
      id: isEdit ? uec.id : _newId('UEC'),
      visitId: visitId,
      coltura: jointCulture.isNotEmpty ? jointCulture : defaultColtura,
      descrizione: '',
      nAggregato: nAggregato.text.trim(),
      note: note.text.trim(),
    );

    nAggregato.dispose();
    note.dispose();
    for (var c in cultureControllers) {
      c.dispose();
    }
  }

  Widget _buildDialogInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
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
    } catch (_) {}
    await db.upsertUec(
      id: u.id,
      visitId: u.visitId,
      coltura: u.coltura,
      descrizione: u.descrizione,
      nAggregato: u.nAggregato,
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
                        'Coltura e UEC',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (!isReadOnly)
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
                          final title = u.nAggregato.isNotEmpty
                              ? 'Agg. ${u.nAggregato} (${u.coltura})'
                              : u.id;
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                backgroundColor: Colors.white,
                                collapsedBackgroundColor: Colors.white,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (!isReadOnly)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          color: Color(0xFF1B5E20),
                                        ),
                                        onPressed: () => _showAddUecDialog(
                                          context,
                                          ref,
                                          uec: u,
                                        ),
                                        tooltip: 'Modifica Dati UEC',
                                      ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    const Icon(
                                      Icons.eco_outlined,
                                      size: 14,
                                      color: Color(0xFF1B5E20),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      u.coltura,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                childrenPadding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 8),
                                  if (u.note.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.amber.shade100,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.notes,
                                                size: 16,
                                                color: Colors.amber.shade900,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'NOTE',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            u.note,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.amber.shade900,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  Row(
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
                                      if (!isReadOnly)
                                        Column(
                                          children: [
                                            IconButton.filledTonal(
                                              onPressed: () => _pickUecPhoto(
                                                context,
                                                ref,
                                                u,
                                              ),
                                              icon: const Icon(
                                                Icons.camera_alt,
                                              ),
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
                                                title: const Text(
                                                  'Elimina UEC',
                                                ),
                                                content: const Text(
                                                  'Sei sicuro di voler eliminare questa UEC? L\'operazione non è reversibile.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'Annulla',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Elimina',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await ref
                                                  .read(appDatabaseProvider)
                                                  .deleteUec(u.id);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Elimina UEC',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
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
  const _QuadroVerificaSection({
    required this.visitId,
    required this.isReadOnly,
  });
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              final headerContent = [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.rule_folder_rounded,
                    size: 28,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                if (!isMobile) const SizedBox(width: 20),
                if (isMobile) const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quadro di verifica COLTIVAZIONE',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Gestione centralizzata degli esiti e del campionamento',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ];

              return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: headerContent,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: headerContent,
                    );
            },
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
                        Icon(
                          Icons.agriculture_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessuna UEC registrata',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aggiungine una nella sezione "Coltura e UEC"',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
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
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Expanded(child: Center(child: Text('Errore: $e'))),
          ),
        ],
      ),
    );
  }
}

class _UecVerificationCard extends ConsumerStatefulWidget {
  const _UecVerificationCard({required this.uec, required this.isReadOnly});
  final VisitUec uec;
  final bool isReadOnly;

  @override
  ConsumerState<_UecVerificationCard> createState() =>
      _UecVerificationCardState();
}

class _UecVerificationCardState extends ConsumerState<_UecVerificationCard> {
  bool _showAddSample = false;

  Future<void> _updateUec(VisitUec u) async {
    await ref
        .read(appDatabaseProvider)
        .upsertUec(
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
          foundProduct: u.foundProduct,
          fieldProcessDetails: u.fieldProcessDetails,
        );
  }

  @override
  Widget build(BuildContext context) {
    final uec = widget.uec;
    final isReadOnly = widget.isReadOnly;

    final title = uec.nAggregato.isNotEmpty
        ? 'Agg. ${uec.nAggregato} (${uec.coltura})'
        : (uec.coltura.isNotEmpty ? uec.coltura : uec.id);

    final isCompleteAsync = ref.watch(
      isUecChecklistCompleteProvider((visitId: uec.visitId, uecId: uec.id)),
    );

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              tilePadding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 24,
                vertical: 8,
              ),
              childrenPadding: EdgeInsets.fromLTRB(
                isNarrow ? 16 : 32,
                0,
                isNarrow ? 16 : 32,
                32,
              ),
              initiallyExpanded: true,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 12 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.label_important_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              uec.coltura,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
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
                      final isFilled =
                          uec.sqnpiConsistency.isNotEmpty &&
                          uec.sqnpiCompliance.isNotEmpty;
                      if (isFilled) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF1B5E20,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E7D32),
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Dati Completati',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending_outlined,
                              color: Colors.orange.shade800,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Da Completare',
                              style: TextStyle(
                                color: Color(0xFFBF360C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, stack) => const SizedBox.shrink(),
                  ),
                  const Icon(Icons.expand_more_rounded, color: Colors.grey),
                ],
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final isMobile = MediaQuery.sizeOf(context).width < 700;

                        final leftCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                              'OUTCOME SQNPI',
                              Icons.assignment_turned_in_outlined,
                            ),
                            const SizedBox(height: 24),
                            const _DialogSectionHeader(
                              title: 'Coerenza con domanda SQNPI',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'Si',
                                    label: Text(
                                      'Si',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'No',
                                    label: Text(
                                      'No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'N/A',
                                    label: Text(
                                      'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                selected: {uec.sqnpiConsistency},
                                onSelectionChanged: isReadOnly
                                    ? null
                                    : (val) => _updateUec(
                                        uec.copyWith(
                                          sqnpiConsistency: val.first,
                                        ),
                                      ),
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: const Color(
                                    0xFF1B5E20,
                                  ),
                                  selectedForegroundColor: Colors.white,
                                  visualDensity: VisualDensity.comfortable,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const _DialogSectionHeader(
                              title: 'Conformità con standard SQNPI',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'Si',
                                    label: Text(
                                      'Si',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'No',
                                    label: Text(
                                      'No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'N/A',
                                    label: Text(
                                      'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                selected: {uec.sqnpiCompliance},
                                onSelectionChanged: isReadOnly
                                    ? null
                                    : (val) => _updateUec(
                                        uec.copyWith(
                                          sqnpiCompliance: val.first,
                                        ),
                                      ),
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: const Color(
                                    0xFF1B5E20,
                                  ),
                                  selectedForegroundColor: Colors.white,
                                  visualDensity: VisualDensity.comfortable,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );

                        final rightCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                              'DETTAGLI VERIFICA',
                              Icons.fact_check_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildModernTextField(
                              title: 'Prodotto riscontrato in ispezione',
                              subtitle:
                                  'Indicare il prodotto oggetto di ispezione',
                              initialValue: uec.foundProduct ?? '',
                              onChanged: isReadOnly
                                  ? null
                                  : (val) => _updateUec(
                                      uec.copyWith(foundProduct: Value(val)),
                                    ),
                              icon: Icons.inventory_2_outlined,
                            ),
                            _buildModernSwitchTile(
                              title: 'Identificato e tracciabile',
                              subtitle:
                                  'Verifica tracciabilità e identificazione',
                              value: uec.isTraceable,
                              onChanged: isReadOnly
                                  ? null
                                  : (val) => _updateUec(
                                      uec.copyWith(isTraceable: val),
                                    ),
                              icon: Icons.qr_code_scanner_rounded,
                            ),
                            _buildModernSwitchTile(
                              title: 'Reclami presentati',
                              subtitle: 'Segnalazione di reclami sul prodotto',
                              value: uec.hasClaims,
                              isNegative: true,
                              onChanged: isReadOnly
                                  ? null
                                  : (val) => _updateUec(
                                      uec.copyWith(hasClaims: val),
                                    ),
                              icon: Icons.report_problem_outlined,
                            ),
                            const SizedBox(height: 24),
                            _buildSectionLabel(
                              'DETTAGLI CAMPIONAMENTO',
                              Icons.science_outlined,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B5E20,
                                ).withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1B5E20,
                                  ).withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _DialogSectionHeader(
                                    title: 'Campionamento Effettuato',
                                  ),
                                  const SizedBox(height: 8),
                                  SwitchListTile(
                                    value: uec.hasSampling,
                                    onChanged: isReadOnly
                                        ? null
                                        : (val) {
                                            _updateUec(
                                              uec.copyWith(hasSampling: val),
                                            );
                                            if (val) {
                                              setState(
                                                () => _showAddSample = true,
                                              );
                                            }
                                          },
                                    title: Text(
                                      uec.hasSampling ? 'SÌ' : 'NO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: uec.hasSampling
                                            ? const Color(0xFF1B5E20)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    activeThumbColor: const Color(0xFF1B5E20),
                                  ),
                                  if (uec.hasSampling) ...[
                                    const SizedBox(height: 16),
                                    if (!isReadOnly && !_showAddSample)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () => setState(
                                              () => _showAddSample = true,
                                            ),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'AGGIUNGI CAMPIONE',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF1B5E20,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFF1B5E20),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    _buildSamplingLotDropdown(
                                      uec,
                                      samples,
                                      isReadOnly,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              leftCol,
                              const SizedBox(height: 32),
                              rightCol,
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: leftCol),
                              const SizedBox(width: 48),
                              Expanded(flex: 5, child: rightCol),
                            ],
                          );
                        }
                      },
                    ),
                    if (uec.hasSampling && _showAddSample)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _InlineSampleForm(
                          visitId: uec.visitId,
                          onSave: () {
                            setState(() => _showAddSample = false);
                          },
                          onCancel: () {
                            setState(() => _showAddSample = false);
                          },
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _buildSectionLabel(
                      'NOTE E OSSERVAZIONI',
                      Icons.note_alt_outlined,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: uec.note,
                      maxLines: 4,
                      minLines: 2,
                      readOnly: isReadOnly,
                      onChanged: (val) => _updateUec(uec.copyWith(note: val)),
                      decoration: InputDecoration(
                        hintText:
                            'Inserisci qui eventuali note o osservazioni...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B5E20),
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF263238),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSamplingLotDropdown(
    VisitUec uec,
    List<VisitSample> samples,
    bool isReadOnly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lotto di Riferimento',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: uec.samplingLotId,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1B5E20),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
            ),
          ),
          items: samples.isEmpty
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nessun campione disponibile'),
                  ),
                ]
              : samples
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.sampleCode} - ${s.matrixType}'),
                      ),
                    )
                    .toList(),
          onChanged: isReadOnly
              ? null
              : (val) => _updateUec(uec.copyWith(samplingLotId: Value(val))),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
            letterSpacing: 1.2,
          ),
        ),
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
            ? (isNegative
                  ? Colors.red.withValues(alpha: 0.05)
                  : const Color(0xFF1B5E20).withValues(alpha: 0.03))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? (isNegative
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFF1B5E20).withValues(alpha: 0.1))
              : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        secondary: Icon(
          icon,
          color: value
              ? (isNegative ? Colors.red : const Color(0xFF1B5E20))
              : Colors.grey.shade400,
        ),
        value: value,
        activeTrackColor: isNegative
            ? Colors.red.shade200
            : const Color(0xFF81C784),
        activeThumbColor: isNegative
            ? Colors.red.shade800
            : const Color(0xFF1B5E20),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildModernTextField({
    required String title,
    required String subtitle,
    required String initialValue,
    required void Function(String)? onChanged,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: initialValue,
            readOnly: isReadOnly,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineSampleForm extends ConsumerStatefulWidget {
  const _InlineSampleForm({
    required this.visitId,
    required this.onSave,
    required this.onCancel,
  });

  final String visitId;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<_InlineSampleForm> createState() => _InlineSampleFormState();
}

class _InlineSampleFormState extends ConsumerState<_InlineSampleForm> {
  final _picker = ImagePicker();
  final _producerCtrl = TextEditingController();
  final _producerCodeCtrl = TextEditingController();
  final _lotGeorefCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _inspectorCodeCtrl = TextEditingController();
  final _matrixCtrl = TextEditingController();
  final _sealCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final List<String> _photos = [];
  DateTime? _inspectionDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final visit = await ref
        .read(appDatabaseProvider)
        .watchVisitById(widget.visitId)
        .first;
    if (mounted) {
      setState(() {
        _inspectionDate = visit?.scheduledAt ?? DateTime.now();
      });
    }
  }

  @override
  void dispose() {
    _producerCtrl.dispose();
    _producerCodeCtrl.dispose();
    _lotGeorefCtrl.dispose();
    _inspectorCtrl.dispose();
    _inspectorCodeCtrl.dispose();
    _matrixCtrl.dispose();
    _sealCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<ImageSource?> _showImageSourcePicker() async {
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

  Future<void> _saveSample() async {
    final db = ref.read(appDatabaseProvider);
    final id = 'SMP-${widget.visitId}-${DateTime.now().millisecondsSinceEpoch}';

    await db.upsertSample(
      id: id,
      visitId: widget.visitId,
      producerName: _producerCtrl.text,
      producerCode: _producerCodeCtrl.text,
      lotNumberGeoref: _lotGeorefCtrl.text,
      inspectorName: _inspectorCtrl.text,
      inspectorCode: _inspectorCodeCtrl.text,
      matrixType: _matrixCtrl.text,
      sealNumber: _sealCtrl.text,
      sampleCode: _codeCtrl.text,
      inspectionDate: _inspectionDate ?? DateTime.now(),
      photoPaths: _photos.join(','),
    );
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Nuova Registrazione Campione',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInputField(
                  controller: _producerCtrl,
                  label: 'Produttore / Azienda',
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildInputField(
                  controller: _producerCodeCtrl,
                  label: 'Codice Bios',
                  icon: Icons.numbers,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _lotGeorefCtrl,
            label: 'Numero Lotto Georeferenziato',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _inspectorCtrl,
                  label: 'Ispettore',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _inspectorCodeCtrl,
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
                  controller: _matrixCtrl,
                  label: 'Matrice Campionata',
                  icon: Icons.grass,
                  hint: 'es. Uva, Foglie...',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _sealCtrl,
                  label: 'Numero Sigillo',
                  icon: Icons.lock_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _codeCtrl,
            label: 'Codice Identificativo Campione',
            icon: Icons.qr_code,
          ),
          const SizedBox(height: 24),
          const Text(
            'DOCUMENTAZIONE FOTOGRAFICA (Minimo 3)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _PhotoManagerGrid(
            photos: _photos,
            onAdd: () async {
              final source = await _showImageSourcePicker();
              if (source != null) {
                final img = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                );
                if (img != null) {
                  setState(() => _photos.add(img.path));
                }
              }
            },
            onRemove: (idx) => setState(() => _photos.removeAt(idx)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _photos.length >= 3 ? _saveSample : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _photos.length >= 3
                        ? 'Salva Campione'
                        : 'Mancano ${3 - _photos.length} foto',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.blueGrey.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogSectionHeader extends StatelessWidget {
  final String title;
  const _DialogSectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
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
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildDisclaimerRow(
                      context,
                      'La sottoscrizione del presente report da parte del Tecnico Ispettore incaricato implica l\'obbligo di inviare a Bios copia del presente report di verifica ispettiva e della checklist di verifica SQNPI entro e non oltre 5 giorni lavorativi dall\'esecuzione dell\'incarico pena applicazione delle sanzioni previste da D035 nella revisione applicabile.',
                      isFirst: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerRow(
                      context,
                      'Con la sottoscrizione del presente report da parte del Responsabile dell\'Organizzazione (Titolare/Rappresentante legale o delegati in possesso di delega scritta), lo stesso dichiara di aver ricevuto copia di tutti i rilievi segnalati dal Tecnico Ispettore incaricato, così come elencati e descritti per ciascun prodotto;',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerRow(context, '... (rev.08)'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore caricamento firme: $e')),
    );
  }

  Widget _buildDisclaimerRow(
    BuildContext context,
    String text, {
    bool isFirst = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_rounded, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: isFirst
              ? RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                      fontFamily: 'Roboto',
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'La sottoscrizione del presente report da parte del Tecnico Ispettore incaricato implica l\'obbligo di inviare a Bios copia del presente report di verifica ispettiva e della checklist di verifica SQNPI ',
                      ),
                      TextSpan(
                        text: 'entro e non oltre 5 giorni lavorativi',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' dall\'esecuzione dell\'incarico pena applicazione delle sanzioni previste da D035 nella revisione applicabile.',
                      ),
                    ],
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
        ),
      ],
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
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasSignature
              ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: hasSignature ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSignature)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Rimuovi firma',
                  ),
                )
              else
                Icon(Icons.draw_outlined, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasSignature ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasSignature
                      ? Colors.grey.shade100
                      : Colors.grey.shade200,
                  style: hasSignature ? BorderStyle.none : BorderStyle.solid,
                ),
                boxShadow: hasSignature
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: hasSignature
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
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
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Firmato',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tocca per firmare',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (hasSignature) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blueGrey.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firma acquisita digitalmente',
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Text(
                  'Stato Avanzamento Checklist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                u.nAggregato.isNotEmpty
                                    ? '${u.nAggregato} (${u.coltura})'
                                    : u.id,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUecId = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            progressAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Errore dashboard: $e'),
              data: (stats) {
                return LayoutBuilder(
                  builder: (context, statsConstraints) {
                    final int crossAxisCount;
                    if (statsConstraints.maxWidth > 1200) {
                      crossAxisCount = 4;
                    } else if (statsConstraints.maxWidth > 800) {
                      crossAxisCount = 2;
                    } else {
                      crossAxisCount = 1;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 140,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        return _StatCard(stat: stats[index]);
                      },
                    );
                  },
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
  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(massBalancesByVisitIdProvider(widget.visitId));

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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Bilancio di massa tenuto conto anche delle scorte di magazzino da eseguire su almeno due sostanze attive di particolare rilevanza ai fini del controllo. Verifica dei documenti fiscali.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey.shade700,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          listAsync.when(
            data: (list) {
              return Column(
                children: [
                  ...list.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _MassBalanceCard(
                        record: record,
                        visitId: widget.visitId,
                        isReadOnly: widget.isReadOnly,
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly) _buildAddButton(),
                  if (list.isNotEmpty) ...[
                    const SizedBox(height: 48),
                    _CardGroup(
                      title: 'ALLEGATI AGGIUNTIVI',
                      subtitle:
                          'Carica foto o documenti originali se necessario',
                      child: Column(
                        children: [
                          _buildDocSection(
                            title: 'Documenti di Entrata (Acquisto)',
                            subtitle:
                                'Fatture di acquisto, bolle di consegna, registri di carico',
                            docType: 'entrata',
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 24),
                          _buildDocSection(
                            title: 'Documenti di Uscita (Utilizzo)',
                            subtitle:
                                'Quaderno di campagna, DDT, registri di scarico',
                            docType: 'uscita',
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Errore: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final db = ref.read(appDatabaseProvider);
          await db.upsertMassBalance(visitId: widget.visitId);
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 16),
            const Text(
              'AGGIUNGI ALTRO BILANCIO',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
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
                OutlinedButton.icon(
                  onPressed: () => _pickImageDocument(docType),
                  icon: Icon(Icons.camera_alt, color: color),
                  label: Text(
                    'Scatta Foto',
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
              ],
            ),
          const SizedBox(height: 16),
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
                            _isImageFile(doc.fileName)
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
                                'Allegato il ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
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
                                builder: (ctx) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Container(
                                    width: 340,
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.delete_forever_rounded,
                                            color: Colors.red.shade700,
                                            size: 40,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Elimina Allegato',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF263238),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Vuoi eliminare definitivamente questo allegato?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blueGrey.shade600,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'ANNULLA',
                                                  style: TextStyle(
                                                    color: Colors
                                                        .blueGrey
                                                        .shade400,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade700,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'ELIMINA',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14,
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

                              if (confirmed == true) {
                                final db = ref.read(appDatabaseProvider);
                                await db.deleteMassBalanceDoc(doc.id);
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
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
}

class _MassBalanceCard extends ConsumerStatefulWidget {
  final MassBalanceRecord record;
  final String visitId;
  final bool isReadOnly;

  const _MassBalanceCard({
    required this.record,
    required this.visitId,
    required this.isReadOnly,
  });

  @override
  ConsumerState<_MassBalanceCard> createState() => _MassBalanceCardState();
}

class _MassBalanceCardState extends ConsumerState<_MassBalanceCard> {
  late TextEditingController _verifiedProducts;
  late TextEditingController _ingressData;
  late TextEditingController _ingressDocs;
  late TextEditingController _egressData;
  late TextEditingController _egressDocs;
  late TextEditingController _comment;
  bool _saving = false;
  bool _showAddSample = false;

  @override
  void initState() {
    super.initState();
    _verifiedProducts = TextEditingController(
      text: widget.record.verifiedProducts ?? '',
    );
    _ingressData = TextEditingController(text: widget.record.ingressData ?? '');
    _ingressDocs = TextEditingController(text: widget.record.ingressDocs ?? '');
    _egressData = TextEditingController(text: widget.record.egressData ?? '');
    _egressDocs = TextEditingController(text: widget.record.egressDocs ?? '');
    _comment = TextEditingController(text: widget.record.comment ?? '');
  }

  @override
  void dispose() {
    _verifiedProducts.dispose();
    _ingressData.dispose();
    _ingressDocs.dispose();
    _egressData.dispose();
    _egressDocs.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertMassBalance(
        id: widget.record.id,
        visitId: widget.visitId,
        verifiedProducts: _verifiedProducts.text,
        ingressData: _ingressData.text,
        ingressDocs: _ingressDocs.text,
        egressData: _egressData.text,
        egressDocs: _egressDocs.text,
        comment: _comment.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilancio salvato con successo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.red.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Elimina Bilancio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sei sicuro di voler eliminare questo bilancio di massa? L\'azione è irreversibile e i dati andranno persi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade600,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ANNULLA',
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ELIMINA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
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

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await db.deleteMassBalance(widget.record.id);
    }
  }

  Widget _buildResponsivePair({
    required bool isMobile,
    required Widget child1,
    required Widget child2,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [child1, const SizedBox(height: 24), child2],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 16),
        Expanded(child: child2),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF37474F)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1B5E20),
                width: 1.5,
              ),
            ),
            hoverColor: const Color(0xFF1B5E20).withValues(alpha: 0.02),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CardGroup(
      title: 'BILANCIO DI MASSA',
      subtitle: 'Evidenza di un bilancio di massa specifico',
      trailing: !widget.isReadOnly
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _delete,
              tooltip: 'Elimina questo bilancio',
            )
          : null,
      child: Builder(
        builder: (context) {
          final isMobile = MediaQuery.sizeOf(context).width < 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernTextField(
                label: 'Prodotti verificati:',
                controller: _verifiedProducts,
                isReadOnly: widget.isReadOnly,
                icon: Icons.inventory_2_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              _buildResponsivePair(
                isMobile: isMobile,
                child1: _buildModernTextField(
                  label: 'Dati in ingresso:',
                  controller: _ingressData,
                  isReadOnly: widget.isReadOnly,
                  icon: Icons.login_rounded,
                  maxLines: 4,
                ),
                child2: _buildModernTextField(
                  label: 'Documenti (Ingresso):',
                  controller: _ingressDocs,
                  isReadOnly: widget.isReadOnly,
                  icon: Icons.receipt_long_outlined,
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 24),
              _buildResponsivePair(
                isMobile: isMobile,
                child1: _buildModernTextField(
                  label: 'Dati in uscita:',
                  controller: _egressData,
                  isReadOnly: widget.isReadOnly,
                  icon: Icons.logout_rounded,
                  maxLines: 4,
                ),
                child2: _buildModernTextField(
                  label: 'Documenti (Uscita):',
                  controller: _egressDocs,
                  isReadOnly: widget.isReadOnly,
                  icon: Icons.fact_check_outlined,
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                label: 'Commento Finale:',
                controller: _comment,
                isReadOnly: widget.isReadOnly,
                icon: Icons.comment_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              if (!widget.isReadOnly && !_showAddSample)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showAddSample = true),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('AGGIUNGI CAMPIONE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showAddSample)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _InlineSampleForm(
                    visitId: widget.visitId,
                    onSave: () => setState(() => _showAddSample = false),
                    onCancel: () => setState(() => _showAddSample = false),
                  ),
                ),
              const SizedBox(height: 8),
              if (!widget.isReadOnly)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _saving
                          ? [Colors.grey, Colors.grey.shade400]
                          : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!_saving)
                        BoxShadow(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'SALVA BILANCIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DurataChiusuraSection extends ConsumerStatefulWidget {
  const _DurataChiusuraSection({required this.visit, required this.isReadOnly});
  final Visit visit;
  final bool isReadOnly;

  @override
  ConsumerState<_DurataChiusuraSection> createState() =>
      _DurataChiusuraSectionState();
}

class _DurataChiusuraSectionState
    extends ConsumerState<_DurataChiusuraSection> {
  DateTime? _deadline;
  bool _isClosed = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
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

    _deadline = c.resolutionDeadline;
    _isClosed = c.isClosed;
  }

  Future<List<String>> _getIncompleteUecNames() async {
    final db = ref.read(appDatabaseProvider);
    final visitId = widget.visit.id;
    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return [];

    final uecs = await db.watchUecsByVisitId(visitId).first;
    final allFasi = await db.watchFasi().first;
    final visitType = visit.visitType;
    final filteredFasi = allFasi
        .where((f) => isPhaseVisible(f, visitType))
        .toList();
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
      final isComplete = requirements.every(
        (item) => respondedCodes.contains(item.code),
      );

      if (isComplete) {
        if (uec.sqnpiConsistency.isEmpty || uec.sqnpiCompliance.isEmpty) {
          missing.add(
            uec.nAggregato.isNotEmpty
                ? 'UEC ${uec.nAggregato} (${uec.coltura})'
                : uec.coltura,
          );
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
            Text(
              'Dati Mancanti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le seguenti UEC hanno la checklist completata ma mancano gli esiti SQNPI (Coerenza/Conformità):',
            ),
            const SizedBox(height: 16),
            ...missingUecs.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Imposta gli esiti nella sezione "Coltura e UEC" prima di chiudere la visita.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Ho capito',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

    try {
      final db = ref.read(appDatabaseProvider);
      final visitId = widget.visit.id;
      // Fetch current closing to preserve correctiveActions if they still exist in DB
      final current = await db.watchClosingByVisitId(visitId).first;

      await db.upsertClosing(
        visitId: visitId,
        correctiveActions: current?.correctiveActions ?? '',
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
        description: 'Visita $visitId: stato impostato a $statusStr',
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

        final success = await syncService.syncVisitToManagement(visitId);

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
    ref.watch(closingByVisitIdProvider(widget.visit.id)).whenData(_fillIfNeeded);

    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Chiusura e Durata',
            subtitle: 'Specifica la durata e conferma la chiusura della visita',
            icon: Icons.gavel_rounded,
          ),
          const SizedBox(height: 32),

          // INTEGRATED DURATA SECTION
          _CardGroup(
            title: 'Durata Verifica',
            subtitle: 'Indica la durata effettiva della visita ispettiva',
            child: _durationSlider(
              context,
              ref,
              widget.visit,
              widget.isReadOnly,
              isMobile,
            ),
          ),

          const SizedBox(height: 24),

          if (isMobile) ...[
            _CardGroup(
              title: 'Scadenza Risolutiva',
              subtitle: 'Termine massimo per la risoluzione (M904: max 7gg)',
              child: InkWell(
                onTap: widget.isReadOnly
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final firstD = now.subtract(const Duration(days: 30));
                        final lastD = now.add(const Duration(days: 365));

                        DateTime initD = _deadline ?? now;
                        if (initD.isBefore(firstD)) initD = firstD;
                        if (initD.isAfter(lastD)) initD = lastD;

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initD,
                          firstDate: firstD,
                          lastDate: lastD,
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
                      const Icon(Icons.calendar_today,
                          size: 20, color: Colors.blue),
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
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CardGroup(
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
          ] else
            Row(
              children: [
                Expanded(
                  child: _CardGroup(
                    title: 'Scadenza Risolutiva',
                    subtitle: 'Termine massimo per la risoluzione (M904: max 7gg)',
                    child: InkWell(
                      onTap: widget.isReadOnly
                          ? null
                          : () async {
                              final now = DateTime.now();
                              final firstD = now.subtract(
                                const Duration(days: 30),
                              );
                              final lastD = now.add(const Duration(days: 365));

                              DateTime initD = _deadline ?? now;
                              if (initD.isBefore(firstD)) initD = firstD;
                              if (initD.isAfter(lastD)) initD = lastD;

                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initD,
                                firstDate: firstD,
                                lastDate: lastD,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade700.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
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
        ),
      ],
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Expanded(
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
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blueGrey.shade50, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

// _NcSummary removed as it is no longer used in the Chiusura section

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
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GestioneNcPrecedentiSection extends ConsumerStatefulWidget {
  const _GestioneNcPrecedentiSection({
    required this.visitId,
    required this.isReadOnly,
  });

  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<_GestioneNcPrecedentiSection> createState() =>
      _GestioneNcPrecedentiSectionState();
}

class _GestioneNcPrecedentiSectionState
    extends ConsumerState<_GestioneNcPrecedentiSection> {
  int _prevNcResults = 0;
  final _prevNcRequirementsStillKO = TextEditingController();
  int _prevCorrectiveActionsCoherent = 0;
  final _prevCorrectiveActionsDetails = TextEditingController();
  final _prevOrgCertifiedDate = TextEditingController();
  final _prevOrgSanctionedDate = TextEditingController();
  final _biosSanctionDetails = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _prevNcRequirementsStillKO.dispose();
    _prevCorrectiveActionsDetails.dispose();
    _prevOrgCertifiedDate.dispose();
    _prevOrgSanctionedDate.dispose();
    _biosSanctionDetails.dispose();
    super.dispose();
  }

  void _fillIfNeeded(VisitPreviousNcManagement? m) {
    if (_loaded) return;
    _loaded = true;
    if (m == null) return;

    _prevNcResults = m.prevNcResults;
    _prevNcRequirementsStillKO.text = m.prevNcRequirementsStillKO;
    _prevCorrectiveActionsCoherent = m.prevCorrectiveActionsCoherent;
    _prevCorrectiveActionsDetails.text = m.prevCorrectiveActionsDetails;
    _prevOrgCertifiedDate.text = m.prevOrgCertifiedDate;
    _prevOrgSanctionedDate.text = m.prevOrgSanctionedDate;
    _biosSanctionDetails.text = m.biosSanctionDetails;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.upsertPreviousNcManagement(
        visitId: widget.visitId,
        prevNcResults: _prevNcResults,
        prevNcRequirementsStillKO: _prevNcRequirementsStillKO.text.trim(),
        prevCorrectiveActionsCoherent: _prevCorrectiveActionsCoherent,
        prevCorrectiveActionsDetails: _prevCorrectiveActionsDetails.text.trim(),
        prevOrgCertifiedDate: _prevOrgCertifiedDate.text.trim(),
        prevOrgSanctionedDate: _prevOrgSanctionedDate.text.trim(),
        biosSanctionDetails: _biosSanctionDetails.text.trim(),
      );

      final logger = ref.read(activityLoggerProvider);
      final auth = ref.read(authControllerProvider);
      await logger.log(
        action: 'UPDATE_PREV_NC_MANAGEMENT',
        description:
            'Aggiornata gestione NC e azioni correttive per la visita ${widget.visitId}',
        actor: auth.username ?? 'Ispettore',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dati salvati correttamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managementAsync = ref.watch(
      previousNcManagementByVisitIdProvider(widget.visitId),
    );

    return managementAsync.when(
      data: (management) {
        _fillIfNeeded(management);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestione NC e azioni correttive',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Text(
                  'NOTA: Per gli operatori, certificati da altri OdC nei due anni precedenti l\'entrata in Bios, è obbligatorio verificare eventuali NC e i provvedimenti emessi (esclusione, sospensione) al fine del calcolo delle recidive.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _FormGroup(
                title:
                    'Le N/C rilevate nel corso della precedente visita ispettiva risulta:',
                icon: Icons.history_edu_rounded,
                children: [
                  _dropdownField(
                    'Esito Verifica',
                    _prevNcResults.toString(),
                    {
                      '0': 'N/A (nel caso non vi siano NC precedenti)',
                      '1': 'Risolte',
                      '2': 'Non risolte',
                    },
                    (v) => setState(() => _prevNcResults = int.parse(v!)),
                  ),
                  if (_prevNcResults == 2)
                    _field(
                      'Specificare quali requisiti risultano ancora NC',
                      _prevNcRequirementsStillKO,
                      icon: Icons.warning_amber_rounded,
                      flex: 1,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Nota: per operatore proveniente da altro OdC verificare 2 annate',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title:
                    'Le azioni correttive risultano coerenti in relazione alle NC trattate:',
                icon: Icons.fact_check_rounded,
                children: [
                  _dropdownField(
                    'Azioni Correttive Coerenti?',
                    _prevCorrectiveActionsCoherent.toString(),
                    {
                      '0': 'N/A (nel caso non vi siano NC precedenti)',
                      '1': 'Si',
                      '2': 'No',
                    },
                    (v) => setState(
                      () => _prevCorrectiveActionsCoherent = int.parse(v!),
                    ),
                  ),
                  if (_prevCorrectiveActionsCoherent == 2)
                    _field(
                      'Dettagli Azioni Correttive',
                      _prevCorrectiveActionsDetails,
                      icon: Icons.notes_rounded,
                      flex: 1,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title:
                    'Dettagli relativi alla precedente attività di sorveglianza e del relativo status di conformità (se applicabile)',
                icon: Icons.event_note_rounded,
                children: [
                  _dateField(
                    'L\'Organizzazione è certificata il:',
                    _prevOrgCertifiedDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                  _dateField(
                    'L\'Organizzazione è stata sanzionata il:',
                    _prevOrgSanctionedDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                  _field(
                    'Specificare quali sanzioni ha emesso Bios (se applicabile):',
                    _biosSanctionDetails,
                    icon: Icons.gavel_rounded,
                    flex: 1,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Errore: $e')),
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
    final helpText = HelpTexts.get(label);

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
              suffixIcon: helpText != null ? HelpTooltip(text: helpText) : null,
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

  Widget _dateField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    if (widget.isReadOnly) {
      return _field(label, controller, icon: icon);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth > 700
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return SizedBox(
          width: w,
          child: TextFormField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            onTap: () async {
              DateTime? initialDate;
              try {
                if (controller.text.isNotEmpty) {
                  initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
                }
              } catch (_) {}

              final now = DateTime.now();
              DateTime initDate = initialDate ?? now;
              final firstDate = DateTime(2000);
              final lastDate = DateTime(2100);
              if (initDate.isBefore(firstDate)) initDate = firstDate;
              if (initDate.isAfter(lastDate)) initDate = lastDate;

              final date = await showDatePicker(
                context: context,
                initialDate: initDate,
                firstDate: firstDate,
                lastDate: lastDate,
                locale: const Locale('it', 'IT'),
                builder: (dialogContext, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).primaryColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.blueGrey.shade900,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      datePickerTheme: DatePickerThemeData(
                        headerBackgroundColor: Theme.of(context).primaryColor,
                        headerForegroundColor: Colors.white,
                        backgroundColor: Colors.white,
                        dividerColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        dayStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                controller.text = DateFormat('dd/MM/yyyy').format(date);
              }
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
              ),
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (HelpTexts.get(label) != null)
                    HelpTooltip(text: HelpTexts.get(label)!),
                  const Icon(Icons.calendar_today_rounded, size: 20),
                  const SizedBox(width: 12),
                ],
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

  Widget _dropdownField(
    String label,
    String? value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    final helpText = HelpTexts.get(label);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth > 700
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
              ),
              suffixIcon: helpText != null ? HelpTooltip(text: helpText) : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: items.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: widget.isReadOnly ? null : onChanged,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _DocumentiRiferimentoSection
// ---------------------------------------------------------------------------

class _DocumentiRiferimentoSection extends ConsumerStatefulWidget {
  const _DocumentiRiferimentoSection({
    required this.visitId,
    required this.isReadOnly,
  });

  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<_DocumentiRiferimentoSection> createState() =>
      _DocumentiRiferimentoSectionState();
}

class _DocumentiRiferimentoSectionState
    extends ConsumerState<_DocumentiRiferimentoSection> {
  bool _isImage(String filePath) {
    const imageExts = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'tiff',
      'tif',
    };
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return imageExts.contains(ext);
  }

  Future<void> _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(
      _attachmentsListProvider(widget.visitId),
    );

    return attachmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (all) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Documenti di Riferimento e Visionati',
              subtitle:
                  'Documentazione Ufficiale Standard SQNPI • M904 Rev. 08',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.05),
                          Colors.blue.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Documentazione Ufficiale',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                'Standard SQNPI • M904 Rev. 08',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildCategoryGroup(
                          context: context,
                          attachments: all,
                          title: 'DOCUMENTI DI RIFERIMENTO UTILIZZATI',
                          category: 'reference',
                          items: [
                            (
                              type: 'DISCIPLINARE',
                              label:
                                  'Disciplinare/i Regionale di Difesa Integrata',
                            ),
                            (
                              type: 'LINEE_GUIDA',
                              label:
                                  'Linee Guida Nazionali di Difesa Integrata',
                            ),
                            (
                              type: 'CHECKLIST_CONTROL_REV',
                              label:
                                  'Checklist di Controllo (Allegato interno Bios)',
                            ),
                            (
                              type: 'RIFERIMENTO_ALTRO',
                              label: 'Altro documento di riferimento',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildCategoryGroup(
                          context: context,
                          attachments: all,
                          title: 'DOCUMENTI VISIONATI',
                          category: 'viewed',
                          items: [
                            (
                              type: 'REGISTRO_SQNPI',
                              label:
                                  'REGISTRO AZIENDALE SQNPI (Campagna, Operazioni, Magazzino)',
                            ),
                            (
                              type: 'AUTOCONTROLLO',
                              label: 'Evidenza autocontrollo interno',
                            ),
                            (
                              type: 'AUDIT_BIOS_PREC',
                              label: "Rapporto dell'audit Bios precedente",
                            ),
                            (
                              type: 'ESITO_CERT_ALTRO_ODC',
                              label: 'Esito certificazione / NC altro OdC',
                            ),
                            (
                              type: 'VISIONATI_ALTRO',
                              label: 'Altro documento visionato',
                            ),
                          ],
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
    );
  }

  Widget _buildCategoryGroup({
    required BuildContext context,
    required List<VisitAttachment> attachments,
    required String title,
    required String category,
    required List<({String type, String label})> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.blueGrey.shade400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => _buildSpecialItem(
            context: context,
            attachments: attachments,
            category: category,
            type: item.type,
            label: item.label,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialItem({
    required BuildContext context,
    required List<VisitAttachment> attachments,
    required String category,
    required String type,
    required String label,
  }) {
    final isDigitalChecklist = type == 'CHECKLIST_CONTROL_REV';
    final isSelected =
        isDigitalChecklist ||
        attachments.any(
          (a) => a.category == category && a.attachmentType == type,
        );
    final att = !isDigitalChecklist && isSelected
        ? attachments.firstWhere(
            (a) => a.category == category && a.attachmentType == type,
          )
        : null;
    final hasFile = att != null && att.filePath.isNotEmpty;
    final actualLabel = isDigitalChecklist ? '$label (Digitale in-App)' : label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.blueGrey.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: (widget.isReadOnly || isDigitalChecklist)
              ? null
              : () async {
                  if (hasFile) {
                    _openFile(att.filePath);
                  } else if (isSelected) {
                    await _handleAddSpecial(category, type, label, att!);
                  } else {
                    await _handleAddSpecial(category, type, label);
                  }
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: (widget.isReadOnly || isDigitalChecklist)
                      ? null
                      : () async {
                          if (isSelected) {
                            await _handleDeleteSpecial(att!);
                          } else {
                            await _handleToggleSelection(category, type, label);
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDigitalChecklist ? Colors.green : Colors.blue)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isSelected
                            ? (isDigitalChecklist ? Colors.green : Colors.blue)
                            : Colors.blueGrey.shade200,
                        width: isSelected ? 0 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    (isDigitalChecklist
                                            ? Colors.green
                                            : Colors.blue)
                                        .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actualLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDigitalChecklist
                              ? Colors.green.shade800
                              : (isSelected
                                    ? Colors.blue.shade900
                                    : Colors.blueGrey.shade800),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (isDigitalChecklist)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AUTOMATICO',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected && !isDigitalChecklist) ...[
                        if (type == 'DISCIPLINARE')
                          _buildExtraField(att!, 'Dettagli Regione/Anno'),
                        if (type.contains('ALTRO'))
                          _buildExtraField(att!, 'Specifiche Documento'),
                      ],
                    ],
                  ),
                ),
                if (isSelected && !isDigitalChecklist)
                  Row(
                    children: [
                      if (hasFile)
                        _DocCircleIconButton(
                          icon: _isImage(att.filePath)
                              ? Icons.visibility_rounded
                              : Icons.file_present_rounded,
                          color: Colors.blueAccent,
                          onPressed: () => _openFile(att.filePath),
                          tooltip: 'Visualizza',
                        )
                      else
                        _DocCircleIconButton(
                          icon: Icons.add_a_photo_rounded,
                          color: Colors.blueGrey.shade400,
                          onPressed: () =>
                              _handleAddSpecial(category, type, label, att!),
                          tooltip: 'Allega file',
                        ),
                      const SizedBox(width: 8),
                      _DocCircleIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        onPressed: () => _handleDeleteSpecial(att!),
                        tooltip: 'Rimuovi',
                      ),
                    ],
                  ),
                if (isDigitalChecklist)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraField(VisitAttachment att, String label) {
    final isMandatory = att.attachmentType.contains('ALTRO');
    final isEmpty = att.extraValue.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 10,
                color: (isMandatory && isEmpty)
                    ? Colors.red
                    : Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: (isMandatory && isEmpty)
                      ? Colors.red
                      : Colors.blueGrey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: att.extraValue,
            readOnly: widget.isReadOnly,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: (isMandatory && isEmpty)
                  ? Colors.red.shade900
                  : Colors.black87,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: (isMandatory && isEmpty)
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.blueGrey.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: isMandatory
                  ? 'SPECIFICA QUI...'
                  : 'Aggiungi dettagli...',
              hintStyle: TextStyle(
                color: (isMandatory && isEmpty)
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.blueGrey.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            onChanged: (val) {
              ref
                  .read(appDatabaseProvider)
                  .updateAttachmentExtra(id: att.id, extraValue: val);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSpecial(VisitAttachment att) async {
    if (!mounted) return;
    final ok = await _showDocConfirm(
      context,
      title: 'Rimuovi Selezione',
      message:
          "Vuoi rimuovere la selezione per questo punto? Verrà rimosso anche l'eventuale allegato associato.",
      confirmLabel: 'Rimuovi',
      isDestructive: true,
    );
    if (ok != true) return;

    try {
      if (att.filePath.isNotEmpty) {
        final f = File(att.filePath);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    await ref.read(appDatabaseProvider).deleteAttachment(att.id);
  }

  Future<void> _handleToggleSelection(
    String category,
    String type,
    String label,
  ) async {
    String extraValue = '';

    if (type.contains('ALTRO')) {
      final name = await _showNameDialog();
      if (!mounted) return;
      if (name == null || name.trim().isEmpty) return;
      extraValue = name.trim();
    }

    await ref
        .read(appDatabaseProvider)
        .insertAttachment(
          visitId: widget.visitId,
          filePath: '',
          caption: label,
          category: category,
          attachmentType: type,
          extraValue: extraValue,
        );
  }

  Future<void> _handleAddSpecial(
    String category,
    String type,
    String label, [
    VisitAttachment? existing,
  ]) async {
    String extraValue = existing?.extraValue ?? '';

    if (existing == null && type.contains('ALTRO')) {
      final name = await _showNameDialog();
      if (!mounted) return;
      if (name == null || name.trim().isEmpty) return;
      extraValue = name.trim();
    }

    if (!mounted) return;
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Seleziona File / Galleria'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    List<String> paths = [];
    if (source == 'camera') {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null) paths = [file.path];
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null) paths = result.paths.whereType<String>().toList();
    }

    if (paths.isEmpty) return;

    final path = paths.first;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final filename =
        'SPEC_${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
    final destPath = p.join(dir.path, filename);
    await File(path).copy(destPath);

    if (existing != null) {
      await ref
          .read(appDatabaseProvider)
          .updateAttachmentFile(id: existing.id, filePath: destPath);
    } else {
      await ref
          .read(appDatabaseProvider)
          .insertAttachment(
            visitId: widget.visitId,
            filePath: destPath,
            caption: label,
            category: category,
            attachmentType: type,
            extraValue: extraValue,
          );
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                        Icons.description_outlined,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Specifica Documento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Campo obbligatorio',
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
                const SizedBox(height: 32),
                const Text(
                  'Inserisci una descrizione o il nome del documento per poter procedere con il caricamento.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome documento',
                    hintText: 'es. Certificato X, Disciplinare Y...',
                    filled: true,
                    fillColor: Colors.blueGrey.shade50.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Annulla',
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            Navigator.pop(ctx, controller.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Conferma',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}

Future<bool?> _showDocConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Conferma',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : Colors.blue).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructive
                      ? Icons.delete_outline_rounded
                      : Icons.info_outline_rounded,
                  color: isDestructive ? Colors.red : Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Annulla',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? Colors.red
                            : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
  );
}

class _DocCircleIconButton extends StatelessWidget {
  const _DocCircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
