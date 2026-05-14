import 'dart:io';
import 'dart:async';
import '../../../core/utils/file_storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

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
import '../application/visit_validation_provider.dart';
import '../application/management_sync_service.dart';
import 'widgets/signature_dialog.dart';
import 'widgets/post_raccolta_section.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../admin/application/activity_logger.dart';
import '../../../core/widgets/help_tooltip.dart';
import '../../../core/constants/help_texts.dart';
import '../data/audits_repository.dart';

// Provider per il conteggio allegati (badge nella NavigationRail)
final _attachmentCountProvider = StreamProvider.family<int, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .watchAttachmentsByVisitId(visitId)
      .map((list) => list.where((a) => a.filePath.isNotEmpty).length);
});

// Nuovo provider per i documenti di riferimento e visionati (Tabella dedicata)
final _documentsListProvider =
    StreamProvider.family<List<VisitDocument>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchDocumentsByVisitId(visitId);
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

// Provider for managing the current selected index in the workspace
final visitWorkspaceIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

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
  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < 800 ||
        MediaQuery.sizeOf(context).height < 500;
    final visitAsync = ref.watch(visitByIdProvider(widget.visitId));

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      drawer: isMobile ? _buildDrawer(context, visitAsync) : null,
      appBar: AppBar(
        title: visitAsync.when(
          data: (v) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v?.companyName ?? 'Visita'),
              if (v != null)
                Text(
                  'ID: ${v.id}',
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
                                final confirmed = await _showDocConfirm(
                                  context,
                                  title: 'Aggiorna Checklist?',
                                  message:
                                      'Vuoi forzare il ricaricamento dei dati dall\'Excel? Tutte le risposte attuali verranno mantenute.',
                                  confirmLabel: 'Sì, aggiorna',
                                  icon: Icons.refresh_rounded,
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
                              case 'sync':
                                final auth = ref.read(authControllerProvider);
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sincronizzazione in corso...',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  await ref
                                      .read(auditsRepositoryProvider)
                                      .syncWithCloud(
                                        auth.username ?? '',
                                        isAdmin: auth.isAdmin,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sincronizzazione completata!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Errore sync: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
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
                            const PopupMenuItem(
                              value: 'sync',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cloud_upload_rounded,
                                    color: Colors.teal,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Sincronizza Documenti Cloud'),
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

        final auth = ref.watch(authControllerProvider);
        final isReadOnly =
            widget.forceReadOnly || (visit.status >= 2 && !auth.isAdmin);

        final List<({NavigationRailDestination dest, Widget page})> navItems = [
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              selectedIcon: Icon(Icons.dashboard, size: 20),
              label: Text('Riepilogo'),
            ),
            page: _RiepilogoSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.business_outlined, size: 20),
              selectedIcon: Icon(Icons.business, size: 20),
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
              icon: Icon(Icons.assignment_outlined, size: 20),
              selectedIcon: Icon(Icons.assignment, size: 20),
              label: Text('Scopo Controllo'),
            ),
            page: _ScopoControlloSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.verified_user_outlined, size: 20),
              selectedIcon: Icon(Icons.verified_user, size: 20),
              label: Text(
                'Documenti di rif.\ne visionati',
                textAlign: TextAlign.center,
              ),
            ),
            page: _DocumentiRiferimentoSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.history_rounded, size: 20),
              selectedIcon: Icon(Icons.history_toggle_off_rounded, size: 20),
              label: Text(
                'Gestione NC e\nazioni corr.',
                textAlign: TextAlign.center,
              ),
            ),
            page: _GestioneNcPrecedentiSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.agriculture_outlined, size: 20),
              selectedIcon: Icon(Icons.agriculture, size: 20),
              label: Text('Colture/ Prodotto in domanda e UEC'),
            ),
            page: _UecLottiSection(
              visitId: visit.id,
              defaultColtura: visit.crop,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.fact_check_outlined, size: 20),
              selectedIcon: Icon(Icons.fact_check, size: 20),
              label: Text('Checklist'),
            ),
            page: ChecklistPage(visitId: visit.id, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.rule_folder_outlined, size: 20),
              selectedIcon: Icon(Icons.rule_folder, size: 20),
              label: Text('Coltivazione'),
            ),
            page: _QuadroVerificaSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.calculate_outlined, size: 20),
              selectedIcon: Icon(Icons.calculate, size: 20),
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
                icon: Icon(Icons.conveyor_belt, size: 20),
                selectedIcon: Icon(Icons.conveyor_belt, size: 20),
                label: Text('Post-raccolta'),
              ),
              page: PostRaccoltaSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.warning_amber_outlined, size: 20),
              selectedIcon: Icon(Icons.warning, size: 20),
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
              icon: Icon(
                Icons.ads_click_rounded,
                size: 20,
              ), // Sensazione premium
              selectedIcon: Icon(Icons.ads_click, size: 20),
              label: Text('Valutazione\nFinale', textAlign: TextAlign.center),
            ),
            page: FinalEvaluationPage(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.gavel_outlined, size: 20),
              selectedIcon: Icon(Icons.gavel, size: 20),
              label: Text('Durata e Avvisi'),
            ),
            page: _DurataChiusuraSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.draw_outlined, size: 20),
              selectedIcon: Icon(Icons.draw, size: 20),
              label: Text('Firme e Chiusura'),
            ),
            page: _SignatureSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
              onIndexChanged: (i) =>
                  ref.read(visitWorkspaceIndexProvider.notifier).state = i,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.picture_as_pdf_outlined, size: 20),
              selectedIcon: Icon(Icons.picture_as_pdf, size: 20),
              label: Text('Esporta Report'),
            ),
            page: ReportPage(visitId: visit.id),
          ),
        ];

        final selectedIndex = ref.watch(visitWorkspaceIndexProvider);

        // Assicurarsi che l'indice selezionato rientri nei limiti se le schede cambiano
        if (selectedIndex >= navItems.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(visitWorkspaceIndexProvider.notifier).state = 0;
          });
        }

        if (isMobile) {
          return Column(
            children: [
              if (visit.status >= 2)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFF059669),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        visit.status == 2
                            ? 'CONCLUSO (SOLA LETTURA)'
                            : 'SINCRONIZZATO (SOLA LETTURA)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFE2E8F0),
                  child: IndexedStack(
                    index: selectedIndex.clamp(
                      0,
                      navItems.isEmpty ? 0 : navItems.length - 1,
                    ),
                    children: navItems.map((e) => e.page).toList(),
                  ),
                ),
              ),
            ],
          );
        }

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Column(
          children: [
            if (visit.status >= 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.9),
                      const Color(0xFF059669).withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      visit.status == 2
                          ? 'VERBALE CONCLUSO - SOLA LETTURA'
                          : 'VERBALE SINCRONIZZATO - SOLA LETTURA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
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
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    20,
                                    isLandscape ? 32 : 48,
                                    20,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'VERBALE ISPEZIONE',
                                          style: TextStyle(
                                            color: Color(0xFF065F46),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        visit.companyName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.6,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final companyAsync = ref.watch(
                                            companyByVisitIdProvider(visit.id),
                                          );
                                          return companyAsync.when(
                                            data: (company) => Text(
                                              'CUAA: ${company?.cuaa ?? ''}  •  P.IVA: ${company?.partitaIva ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueGrey.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (_, _) =>
                                                const SizedBox.shrink(),
                                          );
                                        },
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
                                  selectedIndex: selectedIndex.clamp(
                                    0,
                                    navItems.isEmpty ? 0 : navItems.length - 1,
                                  ),
                                  onDestinationSelected: (i) =>
                                      ref
                                              .read(
                                                visitWorkspaceIndexProvider
                                                    .notifier,
                                              )
                                              .state =
                                          i,
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
                                    fontSize: 12, // Standardized
                                    letterSpacing: -0.2, // Tighter for space
                                  ),
                                  unselectedLabelTextStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12, // Standardized
                                    letterSpacing: -0.2,
                                  ),
                                  destinations: navItems
                                      .map((e) => e.dest)
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(indent: 20, endIndent: 20),
                        // Uscita Azione Rapida
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                      color: const Color(0xFFE2E8F0),
                      child: IndexedStack(
                        index: selectedIndex.clamp(
                          0,
                          navItems.isEmpty ? 0 : navItems.length - 1,
                        ),
                        children: navItems.map((e) => e.page).toList(),
                      ),
                    ),
                  ),
                ],
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

        final auth = ref.watch(authControllerProvider);
        final isReadOnly =
            widget.forceReadOnly || (visit.status >= 2 && !auth.isAdmin);
        final List<({NavigationRailDestination dest, Widget page})> navItems = [
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              selectedIcon: Icon(Icons.dashboard, size: 20),
              label: Text('Riepilogo'),
            ),
            page: _RiepilogoSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.business_outlined, size: 20),
              selectedIcon: Icon(Icons.business, size: 20),
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
              icon: Icon(Icons.assignment_outlined, size: 20),
              selectedIcon: Icon(Icons.assignment, size: 20),
              label: Text('Scopo Controllo'),
            ),
            page: _ScopoControlloSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.verified_user_outlined, size: 20),
              selectedIcon: Icon(Icons.verified_user, size: 20),
              label: Text('Documenti'),
            ),
            page: _DocumentiRiferimentoSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.history_rounded, size: 20),
              selectedIcon: Icon(Icons.history_toggle_off_rounded, size: 20),
              label: Text('Gestione NC'),
            ),
            page: _GestioneNcPrecedentiSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.agriculture_outlined, size: 20),
              selectedIcon: Icon(Icons.agriculture, size: 20),
              label: Text('Colture/ Prodotto in domanda e UEC'),
            ),
            page: _UecLottiSection(
              visitId: visit.id,
              defaultColtura: visit.crop,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.fact_check_outlined, size: 20),
              selectedIcon: Icon(Icons.fact_check, size: 20),
              label: Text('Checklist'),
            ),
            page: ChecklistPage(visitId: visit.id, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.rule_folder_outlined, size: 20),
              selectedIcon: Icon(Icons.rule_folder, size: 20),
              label: Text('Coltivazione'),
            ),
            page: _QuadroVerificaSection(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.calculate_outlined, size: 20),
              selectedIcon: Icon(Icons.calculate, size: 20),
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
                icon: Icon(Icons.conveyor_belt, size: 20),
                selectedIcon: Icon(Icons.conveyor_belt, size: 20),
                label: Text('Post-raccolta'),
              ),
              page: PostRaccoltaSection(
                visitId: visit.id,
                isReadOnly: isReadOnly,
              ),
            ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.warning_amber_outlined, size: 20),
              selectedIcon: Icon(Icons.warning, size: 20),
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
              icon: Icon(Icons.ads_click_rounded, size: 20),
              selectedIcon: Icon(Icons.ads_click, size: 20),
              label: Text('Valutazione Finale'),
            ),
            page: FinalEvaluationPage(
              visitId: visit.id,
              isReadOnly: isReadOnly,
            ),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.draw_outlined, size: 20),
              selectedIcon: Icon(Icons.draw, size: 20),
              label: Text('Firme'),
            ),
            page: _SignatureSection(visitId: visit.id, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.gavel_outlined, size: 20),
              selectedIcon: Icon(Icons.gavel, size: 20),
              label: Text('Chiusura'),
            ),
            page: _DurataChiusuraSection(visit: visit, isReadOnly: isReadOnly),
          ),
          (
            dest: const NavigationRailDestination(
              icon: Icon(Icons.picture_as_pdf_outlined, size: 20),
              selectedIcon: Icon(Icons.picture_as_pdf, size: 20),
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
                    final selectedIndex = ref.watch(
                      visitWorkspaceIndexProvider,
                    );
                    final isSelected = selectedIndex == index;
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
                        ref.read(visitWorkspaceIndexProvider.notifier).state =
                            index;
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
      child: Icon(icon, size: 20),
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
        side: const BorderSide(color: Colors.black87, width: 1.2),
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
              label: 'Natura prodotto (freschi, trasformati...) *',
              hint: 'Es. Uva da tavola, Vino, Olio...',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _processesController,
              label:
                  'Processi di produzione effettuati (vinificazione, imbottigliamento, etichettatura o calibratura, cernita, confezionamento...) *',
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
      maxLines: null,
      minLines: maxLines ?? 2,
      keyboardType: TextInputType.multiline,
      onChanged: (_) => _onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: widget.isReadOnly ? Colors.grey.shade50 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
        final screenWidth = MediaQuery.sizeOf(context).width;
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
  Timer? _debounceTimer;

  List<TextEditingController> get _allControllers => [
    _inspectorController,
    _companionController,
    _representativeController,
    _otherOperatorsController,
    _contactedPersonsController,
  ];

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

    for (final controller in _allControllers) {
      controller.addListener(_onFieldChanged);
    }

    // Gestione auto-popolamento ispettore (RGVI) con formato: Nome Cognome (Codice)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated) return;

      final currentText = _inspectorController.text.trim();
      final fullName = auth.fullName;
      final code = auth.inspectorCode;

      // Costruiamo il nome visualizzato ideale (con codice se disponibile)
      String? displayInspector;
      if (fullName != null && fullName.isNotEmpty) {
        displayInspector = fullName;
        if (code != null && code.isNotEmpty) {
          displayInspector = '$fullName ($code)';
        }
      } else {
        displayInspector = auth.username;
      }

      if (displayInspector == null || displayInspector.isEmpty) return;

      bool shouldUpdate = false;
      if (currentText.isEmpty) {
        // Se è vuoto, lo popoliamo
        shouldUpdate = true;
      } else if (currentText.contains('@') &&
          currentText.toLowerCase() == auth.username?.toLowerCase()) {
        // Se contiene l'email dell'utente corrente, lo aggiorniamo al nome reale
        shouldUpdate = true;
      } else if (fullName != null &&
          currentText == fullName.trim() &&
          code != null &&
          code.isNotEmpty) {
        // Se contiene il nome ma senza codice, facciamo l'upgrade
        // (es: "Mario Rossi" -> "Mario Rossi (ISP-001)")
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        setState(() {
          _inspectorController.text = displayInspector!;
        });
        _saveNames();
      }
    });
  }

  @override
  void dispose() {
    // Forza salvataggio finale se c'è un timer pendente
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _saveNames();
    }
    _debounceTimer?.cancel();
    for (final controller in _allControllers) {
      controller.removeListener(_onFieldChanged);
    }
    _inspectorController.dispose();
    _companionController.dispose();
    _representativeController.dispose();
    _otherOperatorsController.dispose();
    _contactedPersonsController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _saveNames();
      }
    });
  }

  Future<void> _saveNames() async {
    final db = ref.read(appDatabaseProvider);
    await db.upsertVisit(
      id: widget.visit.id,
      scheduledAt: widget.visit.scheduledAt,
      scheduledUntil: widget.visit.scheduledUntil,
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
      lastInspectionDate: widget.visit.lastInspectionDate,
    );
  }

  Future<void> _selectDateRange() async {
    if (widget.isReadOnly) return;

    final initialRange = DateTimeRange(
      start: widget.visit.scheduledAt,
      end: widget.visit.scheduledUntil ?? widget.visit.scheduledAt,
    );

    final newRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      saveText: 'Conferma',
      helpText: 'Seleziona le date della visita',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertVisit(
        id: widget.visit.id,
        scheduledAt: newRange.start,
        scheduledUntil: newRange.end,
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
        lastInspectionDate: widget.visit.lastInspectionDate,
      );
    }
  }

  Future<void> _editPlannedDuration() async {
    if (widget.isReadOnly) return;

    final controller = TextEditingController(
      text: widget.visit.plannedDurationHours.toString(),
    );
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: Colors.teal.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Durata Programmata',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Specifica le ore previste per la verifica',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  final val = int.tryParse(controller.text) ?? 0;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$val',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ore',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.teal.shade600,
                          inactiveTrackColor: Colors.teal.shade100,
                          thumbColor: Colors.teal.shade800,
                          overlayColor: Colors.teal.withValues(alpha: 0.1),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value: val.toDouble(),
                          min: 0,
                          max: 24,
                          divisions: 24,
                          onChanged: (v) {
                            setStateDialog(() {
                              controller.text = v.toInt().toString();
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0h',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '24h',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'ANNULLA',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final val = int.tryParse(controller.text);
                        Navigator.pop(ctx, val);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.teal.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        'SALVA',
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
    );

    if (res != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertVisit(
        id: widget.visit.id,
        scheduledAt: widget.visit.scheduledAt,
        scheduledUntil: widget.visit.scheduledUntil,
        companyName: widget.visit.companyName,
        crop: widget.visit.crop,
        status: VisitStatus.values[widget.visit.status],
        visitType: widget.visit.visitType,
        durationHours: widget.visit.durationHours,
        plannedDurationHours: res,
        durationJustification: widget.visit.durationJustification,
        inspectorName: _inspectorController.text,
        companionName: _companionController.text,
        representativeName: _representativeController.text,
        otherOperators: _otherOperatorsController.text,
        contactedPersons: _contactedPersonsController.text,
        lastInspectionDate: widget.visit.lastInspectionDate,
      );
    }
  }

  Future<void> _editSubmissionNumber() async {
    if (widget.isReadOnly) return;

    final company = await ref.read(
      companyByVisitIdProvider(widget.visit.id).future,
    );
    final current = company?.submissionNumber ?? '';
    final controller = TextEditingController(text: current);

    if (!mounted) return;
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.purple.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Modifica Numero Domanda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Numero Domanda SQNPI',
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ANNULLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SALVA',
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
    );

    if (res != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertCompany(visitId: widget.visit.id, submissionNumber: res);
    }
  }

  Future<void> _editSqnpiProtocol() async {
    if (widget.isReadOnly) return;

    final company = await ref.read(
      companyByVisitIdProvider(widget.visit.id).future,
    );
    final current = company?.sqnpiProtocol ?? '';
    final controller = TextEditingController(text: current);

    if (!mounted) return;
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tag_rounded,
                  color: Colors.blueGrey.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Modifica Protocollo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Protocollo SQNPI',
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                      color: Colors.blueGrey,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ANNULLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SALVA',
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
    );

    if (res != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertCompany(visitId: widget.visit.id, sqnpiProtocol: res);
    }
  }

  Future<void> _selectSqnpiDate() async {
    if (widget.isReadOnly) return;

    final company = await ref.read(
      companyByVisitIdProvider(widget.visit.id).future,
    );
    if (!mounted) return;
    final initialDate = company?.sqnpiSubmissionDate ?? DateTime.now();

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data domanda SQNPI',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertCompany(
        visitId: widget.visit.id,
        sqnpiSubmissionDate: newDate,
      );
    }
  }

  Future<void> _selectLastInspectionDate() async {
    if (widget.isReadOnly) return;

    final initialDate = widget.visit.lastInspectionDate ?? DateTime.now();

    if (!mounted) return;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data ultima verifica',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      final db = ref.read(appDatabaseProvider);
      await db.upsertVisit(
        id: widget.visit.id,
        scheduledAt: widget.visit.scheduledAt,
        scheduledUntil: widget.visit.scheduledUntil,
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
        lastInspectionDate: newDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final start = widget.visit.scheduledAt;
    final end = widget.visit.scheduledUntil;

    String dateStr = DateFormat('dd/MM/yyyy').format(start);
    if (end != null &&
        (end.year != start.year ||
            end.month != start.month ||
            end.day != start.day)) {
      dateStr += ' - ${DateFormat('dd/MM/yyyy').format(end)}';
    }

    ref.listen(companyByVisitIdProvider(widget.visit.id), (previous, next) {
      final company = next.valueOrNull;
      if (company != null &&
          _representativeController.text.isEmpty &&
          company.referente.isNotEmpty) {
        setState(() {
          _representativeController.text = company.referente;
        });
        _saveNames();
      }
    });

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
                childAspectRatio: 2.2,
                children: [
                  _infoCard(
                    context,
                    title: 'Data Visita *',
                    value: dateStr,
                    icon: Icons.calendar_today,
                    color: Colors.blue.shade700,
                    onTap: widget.isReadOnly ? null : _selectDateRange,
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
                    onTap: widget.isReadOnly ? null : _editPlannedDuration,
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
              final crossAxisCount = constraints.maxWidth > 1300
                  ? 4
                  : (constraints.maxWidth > 900
                        ? 3
                        : (constraints.maxWidth > 600 ? 2 : 1));
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _infoCard(
                    context,
                    title: 'Numero domanda',
                    value: submissionNumber,
                    subtitle: 'Adesione SQNPI',
                    icon: Icons.description_outlined,
                    color: Colors.purple.shade700,
                    onTap: widget.isReadOnly ? null : _editSubmissionNumber,
                    onClear:
                        (company != null &&
                            company.submissionNumber.isNotEmpty &&
                            !widget.isReadOnly)
                        ? () async {
                            final db = ref.read(appDatabaseProvider);
                            await db.upsertCompany(
                              visitId: widget.visit.id,
                              submissionNumber: '',
                            );
                          }
                        : null,
                  ),
                  _infoCard(
                    context,
                    title: 'Protocollo',
                    value: sqnpiProtocol,
                    icon: Icons.tag_rounded,
                    color: Colors.blueGrey.shade700,
                    onTap: widget.isReadOnly ? null : _editSqnpiProtocol,
                    onClear:
                        (company != null &&
                            company.sqnpiProtocol.isNotEmpty &&
                            !widget.isReadOnly)
                        ? () async {
                            final db = ref.read(appDatabaseProvider);
                            await db.upsertCompany(
                              visitId: widget.visit.id,
                              sqnpiProtocol: '',
                            );
                          }
                        : null,
                  ),
                  _infoCard(
                    context,
                    title: 'Data domanda SQNPI',
                    value: sqnpiDateStr,
                    icon: Icons.event_note_outlined,
                    color: Colors.indigo.shade600,
                    onTap: widget.isReadOnly ? null : _selectSqnpiDate,
                    onClear: companyAsync.when(
                      data: (c) =>
                          (c?.sqnpiSubmissionDate != null && !widget.isReadOnly)
                          ? () async {
                              final db = ref.read(appDatabaseProvider);
                              await db.upsertCompany(
                                visitId: widget.visit.id,
                                clearSqnpiSubmissionDate: true,
                              );
                            }
                          : null,
                      loading: () => null,
                      error: (e, s) => null,
                    ),
                  ),
                  _infoCard(
                    context,
                    title: 'Data ultima verifica',
                    value: widget.visit.lastInspectionDate != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(widget.visit.lastInspectionDate!)
                        : '-',
                    subtitle: 'Se applicabile',
                    icon: Icons.history_rounded,
                    color: Colors.blue.shade800,
                    onTap: widget.isReadOnly ? null : _selectLastInspectionDate,
                    onClear:
                        (widget.visit.lastInspectionDate != null &&
                            !widget.isReadOnly)
                        ? () async {
                            final db = ref.read(appDatabaseProvider);
                            await db.upsertVisit(
                              id: widget.visit.id,
                              scheduledAt: widget.visit.scheduledAt,
                              companyName: widget.visit.companyName,
                              crop: widget.visit.crop,
                              status: VisitStatus.values[widget.visit.status],
                              clearLastInspectionDate: true,
                            );
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // _DashboardProgress(visitId: widget.visit.id),
          // const SizedBox(height: 24),
          // _ValidationAlerts(uecId: widget.visit.id),
          // const SizedBox(height: 24),

          // --- SOGGETTI PRESENTI ---
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black87, width: 1.2),
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
                                  'RGVI *',
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
                                  'GVI2',
                                  _companionController,
                                  Icons.person_add_alt_1_outlined,
                                  'Nome affiancatore (opzionale)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _nameField(
                            'Altri Operatori Presenti',
                            _otherOperatorsController,
                            Icons.people_outline,
                            'Nomi altri operatori (se presenti)',
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
          readOnly: widget.isReadOnly,
          enabled: true, // Keep enabled true so M3 respects fillColor
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: widget.isReadOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black87, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: color.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onClear != null && !widget.isReadOnly)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
                color: Colors.red.shade400,
                tooltip: 'Rimuovi',
              ),
            )
          else if (onTap != null)
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.edit_outlined,
                size: 14,
                color: color.withValues(alpha: 0.4),
              ),
            ),
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
                        'Durata della verifica ispettiva *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specifica la durata complessiva (1 giornata = 8 ore)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_center,
                            size: 20,
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
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Durata della verifica ispettiva *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specifica la durata complessiva (1 giornata = 8 ore)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_center,
                            size: 20,
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
                _JustificationField(visit: visit, isReadOnly: isReadOnly),
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
                if (!isMobile) _buildSliderLabel(4, '4h'),
                _buildSliderLabel(
                  8,
                  isMobile ? '8h' : '8h (1gg)',
                  isBold: true,
                ),
                if (!isMobile) _buildSliderLabel(12, '12h'),
                _buildSliderLabel(
                  16,
                  isMobile ? '16h' : '16h (2gg)',
                  isBold: true,
                ),
                _buildSliderLabel(24, '24h'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _JustificationField extends ConsumerStatefulWidget {
  final Visit visit;
  final bool isReadOnly;

  const _JustificationField({required this.visit, required this.isReadOnly});

  @override
  ConsumerState<_JustificationField> createState() =>
      _JustificationFieldState();
}

class _JustificationFieldState extends ConsumerState<_JustificationField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.visit.durationJustification,
    );
  }

  @override
  void dispose() {
    // Forza salvataggio finale
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      try {
        final db = ref.read(appDatabaseProvider);
        db.upsertVisit(
          id: widget.visit.id,
          scheduledAt: widget.visit.scheduledAt,
          scheduledUntil: widget.visit.scheduledUntil,
          companyName: widget.visit.companyName,
          crop: widget.visit.crop,
          status: VisitStatus.values[widget.visit.status],
          visitType: widget.visit.visitType,
          durationHours: widget.visit.durationHours,
          plannedDurationHours: widget.visit.plannedDurationHours,
          durationJustification: _controller.text.trim(),
          inspectorName: widget.visit.inspectorName,
          companionName: widget.visit.companionName,
          representativeName: widget.visit.representativeName,
          otherOperators: widget.visit.otherOperators,
          contactedPersons: widget.visit.contactedPersons,
          lastInspectionDate: widget.visit.lastInspectionDate,
        );
      } catch (e) {
        debugPrint('Error during final justification save: $e');
      }
    }
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (mounted) {
        final db = ref.read(appDatabaseProvider);
        await db.upsertVisit(
          id: widget.visit.id,
          scheduledAt: widget.visit.scheduledAt,
          scheduledUntil: widget.visit.scheduledUntil,
          companyName: widget.visit.companyName,
          crop: widget.visit.crop,
          status: VisitStatus.values[widget.visit.status],
          visitType: widget.visit.visitType,
          durationHours: widget.visit.durationHours,
          plannedDurationHours: widget.visit.plannedDurationHours,
          durationJustification: val.trim(),
          inspectorName: widget.visit.inspectorName,
          companionName: widget.visit.companionName,
          representativeName: widget.visit.representativeName,
          otherOperators: widget.visit.otherOperators,
          contactedPersons: widget.visit.contactedPersons,
          lastInspectionDate: widget.visit.lastInspectionDate,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: null,
      keyboardType: TextInputType.multiline,
      readOnly: widget.isReadOnly,
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText:
            'Inserisci il motivo per cui la visita ha richiesto più tempo del previsto...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
      ),
    );
  }
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
  String _processingType = 'singolo';

  Timer? _debounceTimer;

  /// List of all text controllers for auto-save listeners
  List<TextEditingController> get _allControllers => [
    _ragioneSociale,
    _cuaa,
    _piva,
    _indirizzo,
    _cap,
    _comune,
    _provincia,
    _referente,
    _telefono,
    _email,
    _pec,
    _sedeOperativaIndirizzo,
    _sedeOperativaCap,
    _sedeOperativaComune,
    _sedeOperativaProvincia,
    _sedeOperativaLatitude,
    _sedeOperativaLongitude,
    _manipulationSiteAddress,
    _manipulationSiteCap,
    _manipulationSiteComune,
    _manipulationSiteProvincia,
    _jointVisitDetails,
    _previousOdcName,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _loaded && !_saving) {
        _autoSave();
      }
    });
  }

  @override
  void dispose() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _autoSave();
    }
    _debounceTimer?.cancel();
    for (final c in _allControllers) {
      c.removeListener(_onFieldChanged);
    }
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
    _debounceTimer?.cancel();
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
    _processingType = (c?.processingType.isNotEmpty ?? false)
        ? c!.processingType
        : 'singolo';
  }

  /// Salvataggio automatico silenzioso: salva tutti i campi senza feedback visivo.
  Future<void> _autoSave() async {
    if (widget.isReadOnly || _saving) return;
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
        processingType: _processingType,
        thirdPartyCertNumber: '',
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

      // Sincronizzazione OdC allegato
      await _syncOdcAttachment(db);
    } catch (e) {
      debugPrint('Error in autoSave: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncOdcAttachment(AppDatabase db) async {
    final currentAttachments = await (db.select(
      db.visitAttachments,
    )..where((t) => t.visitId.equals(widget.visitId))).get();

    final filteredOdc = currentAttachments.where(
      (a) =>
          a.category == 'viewed' && a.attachmentType == 'ESITO_CERT_ALTRO_ODC',
    );
    final existingOdc = filteredOdc.isEmpty ? null : filteredOdc.first;

    final hasOdcData =
        _isNewOperator && _previousOdcName.text.trim().isNotEmpty;

    if (hasOdcData) {
      if (existingOdc == null) {
        await db.insertAttachment(
          visitId: widget.visitId,
          filePath: _previousOdcOutcomesPath ?? '',
          category: 'viewed',
          attachmentType: 'ESITO_CERT_ALTRO_ODC',
          caption:
              'Esito certificazione OdC precedente: ${_previousOdcName.text.trim()}',
        );
      } else {
        final newPath = _previousOdcOutcomesPath ?? '';
        if (existingOdc.filePath != newPath) {
          await db.updateAttachmentFile(id: existingOdc.id, filePath: newPath);
        }
      }
    } else if (!_isNewOperator && existingOdc != null) {
      await db.deleteAttachment(existingOdc.id);
    }
  }

  Future<void> _pickPreviousOdcFile() async {
    if (widget.isReadOnly) return;
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final destPath = await _copyToAppStorage(result.files.single.path!);
      setState(() {
        _previousOdcOutcomesPath = destPath;
      });
      // Trigger autosave immediato per l'allegato
      await _autoSave();
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
                    'Ragione sociale *',
                    _ragioneSociale,
                    flex: 2,
                    icon: Icons.business,
                  ),
                  _field('CUAA *', _cuaa),
                  _field('Partita IVA *', _piva),
                ],
              ),
              const SizedBox(height: 24),

              _FormGroup(
                title: 'Sede Legale',
                icon: Icons.location_on_rounded,
                children: [
                  _field(
                    'Indirizzo *',
                    _indirizzo,
                    flex: 2,
                    icon: Icons.map_outlined,
                  ),
                  _field('Comune *', _comune, flex: 1),
                  _field('CAP *', _cap, width: 120),
                  _field('Provincia *', _provincia, width: 80),
                ],
              ),
              const SizedBox(height: 24),
              _FormGroup(
                title: 'Sede Operativa',
                icon: Icons.map_outlined,
                children: [
                  _field(
                    'Indirizzo *',
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
                  _field('Comune *', _sedeOperativaComune, flex: 1),
                  _field('CAP *', _sedeOperativaCap, width: 120),
                  _field('Provincia *', _sedeOperativaProvincia, width: 80),
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
                    'Mesi di Picco dell\'Attività *',
                    _peakPeriodFrom ?? '',
                    (v) {
                      setState(() => _peakPeriodFrom = v);
                      _autoSave();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FormGroup(
                title: 'Rappresentante Aziendale',
                icon: Icons.contact_mail_rounded,
                children: [
                  _field(
                    'Nome Referente *',
                    _referente,
                    flex: 1,
                    icon: Icons.person_outline,
                  ),
                  _field('Telefono *', _telefono, icon: Icons.phone_outlined),
                  _field(
                    'Email *',
                    _email,
                    flex: 2,
                    icon: Icons.alternate_email_rounded,
                  ),
                  _field(
                    'PEC *',
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
                    'Visita Ispettiva Congiunta con altri schemi',
                    _isJointVisit,
                    (v) {
                      setState(() => _isJointVisit = v);
                      _autoSave();
                    },
                    subtitle: 'Esempio: GlobalGAP, Biologico, etc.',
                  ),
                  if (_isJointVisit)
                    _field(
                      'Dettaglio schema di certificazione congiunto *',
                      _jointVisitDetails,
                      icon: Icons.account_tree_outlined,
                      flex: 1,
                    ),
                  const SizedBox(height: 16),
                  _switchField(
                    'Operatore certificato da un altro OdC negli anni precedenti',
                    _isNewOperator,
                    (v) async {
                      setState(() => _isNewOperator = v);
                      // Trigger autosave immediato
                      await _autoSave();
                    },
                    subtitle: 'Se attivo, sblocca la verifica OdC precedente',
                  ),
                  if (_isNewOperator) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          'Nome precedente OdC *',
                          _previousOdcName,
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 16),
                        _odcAttachmentField(),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 48),

              Row(
                children: [
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
                        'Esiti verifica precedente (Allegato) *',
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
                  if (!widget.isReadOnly)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: () =>
                          setState(() => _previousOdcOutcomesPath = null),
                      tooltip: 'Rimuovi',
                    ),
                ] else if (!widget.isReadOnly)
                  TextButton.icon(
                    onPressed: _pickPreviousOdcFile,
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
            enabled: true, // Keep enabled true so M3 respects fillColor
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
              fillColor: effectiveReadOnly ? Colors.grey.shade50 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.black, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
          onTap: widget.isReadOnly
              ? null
              : () async {
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
                                                .compareTo(
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
              color: widget.isReadOnly
                  ? Colors.grey.shade50
                  : Colors.grey.shade50,
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
                if (!widget.isReadOnly)
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
            color: Colors.white,
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
    final colturaController = TextEditingController(text: uec?.coltura ?? '');

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
                                  'Verifica Colture/ Prodotto in domanda e UEC (Rev. 08)',
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
                                label: 'Codice Aggregato',
                                hint: 'Inserisci numero aggregato...',
                                icon: Icons.numbers,
                                enabled: !isReadOnly,
                              ),
                              const SizedBox(height: 16),
                              _buildDialogInputField(
                                controller: colturaController,
                                label: 'Colture/ Prodotto in domanda',
                                hint: 'es. Vite, Olivo...',
                                icon: Icons.agriculture,
                                enabled: !isReadOnly,
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
                          if (!isReadOnly) const SizedBox(width: 16),
                          if (!isReadOnly)
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
      colturaController.dispose();

      return;
    }

    final coltura = colturaController.text.trim();
    final db = ref.read(appDatabaseProvider);
    await db.upsertUec(
      id: isEdit ? uec.id : _newId('UEC'),
      visitId: visitId,
      coltura: coltura,
      descrizione: '',
      nAggregato: nAggregato.text.trim(),
      note: '',
    );

    nAggregato.dispose();
    colturaController.dispose();
  }

  Widget _buildDialogInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? hint,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      readOnly: !enabled,
      enabled: true, // Keep enabled true so M3 respects fillColor
      maxLines: maxLines,
      minLines: maxLines == null ? 1 : null,
      keyboardType: maxLines == null
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
    if (!context.mounted) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Scatta Foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galleria / File'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    String? path;

    if (source == 'camera') {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (image != null) path = image.path;
    } else {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        path = result.files.single.path;
      }
    }

    if (path == null) return;
    final db = ref.read(appDatabaseProvider);
    double? lat;
    double? lon;
    try {
      final company = await db.watchCompanyByVisitId(u.visitId).first;
      if (company != null) {
        if (company.latitudeText.isNotEmpty) {
          lat = double.tryParse(company.latitudeText.replaceAll(',', '.'));
        }
        lat ??= company.latitude;

        if (company.longitudeText.isNotEmpty) {
          lon = double.tryParse(company.longitudeText.replaceAll(',', '.'));
        }
        lon ??= company.longitude;
      }
    } catch (_) {}

    lat ??= u.latitude;
    lon ??= u.longitude;

    await db.upsertUec(
      id: u.id,
      visitId: u.visitId,
      coltura: u.coltura,
      descrizione: u.descrizione,
      nAggregato: u.nAggregato,
      note: '',
      latitude: lat,
      longitude: lon,
      photoPath: path,
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
            data: (allUecs) {
              final uecs = allUecs
                  .where((u) => u.coltura.trim().toUpperCase() != 'OPERATORE')
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Text(
                        'Colture/ Prodotto in domanda e UEC',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Esiti SQNPI da compilare in "Coltivazione"',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              ? '${u.coltura} (Codice Aggregato ${u.nAggregato})'
                              : u.id;
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: Colors.black87,
                                width: 1.2,
                              ),
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
                                      size: 20,
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
                                                  size: 20,
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
                                              _PersistentImage(
                                                filePath: u.photoPath!,
                                                height: 120,
                                                width: 160,
                                                fit: BoxFit.cover,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                                child: Center(
                                                  child: Icon(
                                                    Icons.camera_alt_outlined,
                                                    color: Colors.grey.shade400,
                                                    size: 24,
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
                                            if (u.photoPath != null) ...[
                                              const SizedBox(height: 8),
                                              IconButton.filledTonal(
                                                onPressed: () async {
                                                  final ok = await _showDocConfirm(
                                                    context,
                                                    title: 'Elimina Foto',
                                                    message:
                                                        'Sei sicuro di voler eliminare questa foto?',
                                                    confirmLabel: 'Elimina',
                                                    isDestructive: true,
                                                  );
                                                  if (ok == true) {
                                                    try {
                                                      final file = File(
                                                        u.photoPath!,
                                                      );
                                                      if (await file.exists()) {
                                                        await file.delete();
                                                      }
                                                    } catch (_) {}
                                                    await ref
                                                        .read(
                                                          appDatabaseProvider,
                                                        )
                                                        .upsertUec(
                                                          id: u.id,
                                                          visitId: u.visitId,
                                                          coltura: u.coltura,
                                                          descrizione:
                                                              u.descrizione,
                                                          nAggregato:
                                                              u.nAggregato,
                                                          note: u.note,
                                                          latitude: null,
                                                          longitude: null,
                                                          photoPath: null,
                                                          sqnpiConsistency: u
                                                              .sqnpiConsistency,
                                                          sqnpiCompliance:
                                                              u.sqnpiCompliance,
                                                          isTraceable:
                                                              u.isTraceable,
                                                          hasClaims:
                                                              u.hasClaims,
                                                          isFieldProcessVerified:
                                                              u.isFieldProcessVerified,
                                                          hasSampling:
                                                              u.hasSampling,
                                                          samplingLotId:
                                                              u.samplingLotId,
                                                          foundProduct:
                                                              u.foundProduct,
                                                          fieldProcessDetails: u
                                                              .fieldProcessDetails,
                                                        );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Elimina Foto',
                                              ),
                                            ],
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
                                            final ok = await _showDocConfirm(
                                              context,
                                              title: 'Elimina UEC',
                                              message:
                                                  'Sei sicuro di voler eliminare questa UEC? L\'operazione non è reversibile.',
                                              confirmLabel: 'Elimina',
                                              isDestructive: true,
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
            data: (allUecs) {
              final uecs = allUecs
                  .where((u) => u.coltura.trim().toUpperCase() != 'OPERATORE')
                  .toList();
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
                          'Aggiungine una nella sezione "Colture/ Prodotto in domanda e UEC"',
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
  Timer? _debounceTimer;

  @override
  void dispose() {
    // Forza salvataggio finale se c'è un timer pendente
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _updateUec(widget.uec);
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedUpdate(VisitUec u) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _updateUec(u);
      }
    });
  }

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
        ? '${uec.coltura} (Codice Aggregato ${uec.nAggregato})'
        : (uec.coltura.isNotEmpty ? uec.coltura : uec.id);

    final isCompleteAsync = ref.watch(
      isUecChecklistCompleteProvider((visitId: uec.visitId, uecId: uec.id)),
    );

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
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              uec.coltura.isNotEmpty
                                  ? uec.coltura
                                  : 'Colture/ Prodotto in domanda',
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
                                size: 20,
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
                              size: 20,
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
                            const SizedBox(height: 24),
                            _buildModernTextField(
                              title: 'Prodotto riscontrato in ispezione',
                              subtitle:
                                  'Indicare il prodotto oggetto di ispezione',
                              initialValue: uec.foundProduct ?? '',
                              isReadOnly: isReadOnly,
                              onChanged: isReadOnly
                                  ? null
                                  : (val) => _updateUec(
                                      uec.copyWith(foundProduct: Value(val)),
                                    ),
                              icon: Icons.inventory_2_outlined,
                            ),
                            _buildModernTextField(
                              title: 'Processo produttivo verificato in campo',
                              subtitle: 'Dettagli del processo verificato',
                              initialValue: uec.fieldProcessDetails ?? '',
                              isReadOnly: isReadOnly,
                              onChanged: isReadOnly
                                  ? null
                                  : (val) => _updateUec(
                                      uec.copyWith(
                                        fieldProcessDetails: Value(val),
                                      ),
                                    ),
                              icon: Icons.checklist_rtl_rounded,
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
                                    _buildModernTextField(
                                      title: 'Numero Lotto',
                                      subtitle:
                                          'Inserire il numero del lotto campionato',
                                      initialValue: uec.samplingLotId ?? '',
                                      isReadOnly: isReadOnly,
                                      onChanged: isReadOnly
                                          ? null
                                          : (val) => _debouncedUpdate(
                                              uec.copyWith(
                                                samplingLotId: Value(val),
                                              ),
                                            ),
                                      icon: Icons.tag,
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
                      maxLines: null,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      readOnly: isReadOnly,
                      onChanged: (val) =>
                          _debouncedUpdate(uec.copyWith(note: val)),
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
                          borderSide: const BorderSide(
                            color: Colors.black87,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.black87,
                            width: 1.2,
                          ),
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

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
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
            maxLines: null,
            keyboardType: TextInputType.multiline,
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
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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

class _SignatureSection extends ConsumerStatefulWidget {
  const _SignatureSection({
    required this.visitId,
    this.isReadOnly = false,
    this.onIndexChanged,
  });
  final String visitId;
  final bool isReadOnly;
  final Function(int)? onIndexChanged;

  @override
  ConsumerState<_SignatureSection> createState() => _SignatureSectionState();
}

class _SignatureSectionState extends ConsumerState<_SignatureSection> {
  bool _isClosing = false;

  Future<void> _pickIdentityDoc(
    BuildContext context,
    WidgetRef ref,
    String sigId,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final db = ref.read(appDatabaseProvider);

      // Copia in cartella app
      final appDir = await getApplicationSupportDirectory();
      final destDir = Directory(
        '${appDir.path}/sqnpi_audit_manager/signatures/${widget.visitId}/id_docs',
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
        visitId: widget.visitId,
        signatureType: type,
        filePath: result['filePath'] as String,
        signerName: result['signerName'] as String?,
      );
    }
  }

  Future<void> _closeVisit(BuildContext context) async {
    setState(() => _isClosing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final logger = ref.read(activityLoggerProvider);
      final auth = ref.read(authControllerProvider);
      final syncService = ref.read(managementSyncServiceProvider);

      final currentClosing = await db
          .watchClosingByVisitId(widget.visitId)
          .first;
      await db.upsertClosing(
        visitId: widget.visitId,
        correctiveActions: currentClosing?.correctiveActions ?? '',
        resolutionDeadline:
            currentClosing?.resolutionDeadline ??
            DateTime.now().add(const Duration(days: 7)),
        isClosed: true,
      );

      // Log attività
      await logger.log(
        action: 'MANUAL_CLOSE_ON_CONFIRMATION',
        description:
            'Visita ${widget.visitId} chiusa manualmente dopo conferma',
        actor: auth.username ?? 'Sistema',
      );

      // Automatic Sync to Management System
      if (context.mounted) {
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
                Text('Chiusura in corso: invio dati al gestionale...'),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );

        final success = await syncService.syncVisitToManagement(widget.visitId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Visita chiusa e sincronizzata correttamente.'
                    : 'Visita chiusa. Errore sincronizzazione gestionale.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signaturesAsync = ref.watch(_signaturesProvider(widget.visitId));
    final validationAsync = ref.watch(visitValidationProvider(widget.visitId));
    final closingAsync = ref.watch(closingByVisitIdProvider(widget.visitId));
    final db = ref.read(appDatabaseProvider);

    final validationErrors = validationAsync.value ?? [];
    final isClosed = closingAsync.value?.isClosed ?? false;

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
              const SizedBox(height: 24),
              if (validationErrors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBDEFB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isClosed
                              ? 'La visita è chiusa. Non è possibile apportare ulteriori modifiche.'
                              : 'Dopo aver apposto le firme necessarie, potrai procedere alla chiusura definitiva tramite il tasto in basso.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isClosed
                                ? Colors.grey.shade700
                                : Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _SignatureCard(
                    title: 'Ispettore SQNPI',
                    signerName:
                        inspectorSig?.signerName ?? 'Ispettore incaricato',
                    signature: inspectorSig,
                    onTap: isClosed
                        ? null
                        : () {
                            final auth = ref.read(authControllerProvider);
                            String? name;
                            if (auth.fullName != null) {
                              name = auth.fullName;
                              if (auth.inspectorCode != null &&
                                  auth.inspectorCode!.isNotEmpty) {
                                name =
                                    '${auth.fullName} (${auth.inspectorCode})';
                              }
                            }
                            _addSignature(
                              context,
                              ref,
                              'inspector',
                              signerName: name,
                            );
                          },
                    onDelete: (inspectorSig != null && !isClosed)
                        ? () => db.deleteSignature(inspectorSig.id)
                        : null,
                  ),
                  _SignatureCard(
                    title: 'Legale Rappresentante',
                    signerName: representativeSig?.signerName ?? 'Titolare',
                    signature: representativeSig,
                    errors: validationErrors,
                    onTap: isClosed
                        ? null
                        : () => _addSignature(
                            context,
                            ref,
                            'representative',
                            signerName: representativeSig?.signerName,
                          ),
                    onDelete: (representativeSig != null && !isClosed)
                        ? () => db.deleteSignature(representativeSig.id)
                        : null,
                    onPickIdentityDoc: (representativeSig != null && !isClosed)
                        ? () => _pickIdentityDoc(
                            context,
                            ref,
                            representativeSig.id,
                          )
                        : null,
                    onValidationErrorTap: (err) {
                      if (widget.onIndexChanged != null) {
                        int targetIndex = -1;
                        if (err.section == 'Coltivazione') {
                          targetIndex = 7;
                        } else if (err.section == 'Checklist') {
                          targetIndex = 6;
                        }
                        if (targetIndex != -1) {
                          widget.onIndexChanged!(targetIndex);
                        }
                      }
                    },
                  ),
                  _SignatureCard(
                    title: 'Delegato Aziendale',
                    signerName: delegateSig?.signerName ?? 'Sostituto delegato',
                    signature: delegateSig,
                    errors: validationErrors,
                    onTap: isClosed
                        ? null
                        : () => _addSignature(
                            context,
                            ref,
                            'delegate',
                            signerName: delegateSig?.signerName,
                          ),
                    onDelete: (delegateSig != null && !isClosed)
                        ? () => db.deleteSignature(delegateSig.id)
                        : null,
                    onPickIdentityDoc: (delegateSig != null && !isClosed)
                        ? () => _pickIdentityDoc(context, ref, delegateSig.id)
                        : null,
                    onValidationErrorTap: (err) {
                      if (widget.onIndexChanged != null) {
                        int targetIndex = -1;
                        if (err.section == 'Coltivazione') {
                          targetIndex = 7;
                        } else if (err.section == 'Checklist') {
                          targetIndex = 6;
                        }
                        if (targetIndex != -1) {
                          widget.onIndexChanged!(targetIndex);
                        }
                      }
                    },
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
              const SizedBox(height: 48),
              if (!isClosed)
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isClosing ? null : () => _closeVisit(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: _isClosing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isClosing
                            ? 'Chiusura in corso...'
                            : 'CONFERMA CHIUSURA VISITA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                )
              else if (isClosed)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'VISITA CHIUSA',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 80),
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

class _PersistentImage extends StatefulWidget {
  final String filePath;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;

  const _PersistentImage({
    required this.filePath,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
  });

  @override
  State<_PersistentImage> createState() => _PersistentImageState();
}

class _PersistentImageState extends State<_PersistentImage> {
  String? _normalizedPath;

  @override
  void initState() {
    super.initState();
    _normalize();
  }

  @override
  void didUpdateWidget(_PersistentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _normalize();
    }
  }

  Future<void> _normalize() async {
    final path = await FileStorageUtils.getNormalizedPath(widget.filePath);
    if (mounted) {
      setState(() => _normalizedPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_normalizedPath == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Image.file(
        File(_normalizedPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.title,
    required this.signerName,
    this.signature,
    this.errors,
    this.onTap,
    this.onDelete,
    this.onPickIdentityDoc,
    this.onValidationErrorTap,
  });

  final String title;
  final String signerName;
  final VisitSignature? signature;
  final List<VisitValidationError>? errors;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPickIdentityDoc;
  final Function(VisitValidationError)? onValidationErrorTap;

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
              if (hasSignature && onDelete != null)
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
                  width: 1,
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
                          child: _PersistentImage(
                            filePath: signature!.filePath,
                            borderRadius: BorderRadius.circular(20),
                            fit: BoxFit.contain,
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
                                  size: 20,
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
                    size: 20,
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
                        size: 20,
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
                                    ? '${u.coltura} (Codice Aggregato ${u.nAggregato})'
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
                    size: 20,
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
  Timer? _debounceTimer;

  List<TextEditingController> get _allControllers => [
    _verifiedProducts,
    _ingressData,
    _ingressDocs,
    _egressData,
    _egressDocs,
    _comment,
  ];

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

    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_saving) {
        _autoSave();
      }
    });
  }

  @override
  void dispose() {
    // 1. Forza un ultimo salvataggio se c'è un timer pendente MENTRE i controller sono ancora vivi
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      try {
        final db = ref.read(appDatabaseProvider);
        db.upsertMassBalance(
          id: widget.record.id,
          visitId: widget.visitId,
          verifiedProducts: _verifiedProducts.text,
          ingressData: _ingressData.text,
          ingressDocs: _ingressDocs.text,
          egressData: _egressData.text,
          egressDocs: _egressDocs.text,
          comment: _comment.text,
        );
      } catch (e) {
        debugPrint('Error during final mass balance save: $e');
      }
    }
    _debounceTimer?.cancel();

    // 2. Rimuovi i listener
    for (final c in _allControllers) {
      c.removeListener(_onFieldChanged);
    }

    // 3. Ora puoi distruggere i controller
    _verifiedProducts.dispose();
    _ingressData.dispose();
    _ingressDocs.dispose();
    _egressData.dispose();
    _egressDocs.dispose();
    _comment.dispose();
    super.dispose();
  }

  /// Salvataggio automatico silenzioso
  Future<void> _autoSave() async {
    if (widget.isReadOnly || _saving) return;
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
    } catch (e) {
      debugPrint('Error in MassBalance autoSave: $e');
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
    int? maxLines,
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
              child: Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
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
          maxLines: null,
          minLines: maxLines ?? 2,
          keyboardType: TextInputType.multiline,
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
              borderSide: const BorderSide(color: Colors.black87, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
              const SizedBox(height: 8),
              if (!widget.isReadOnly)
                Row(
                  children: [
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
  bool _isClosed = false;
  bool _loaded = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _fillIfNeeded(VisitClosing? c) {
    if (c == null) {
      if (!_loaded) {
        _loaded = true;
      }
      return;
    }

    if (!_loaded) {
      _loaded = true;
    }

    // Always update the closed state to reflect DB changes (like auto-close on signature)
    if (_isClosed != c.isClosed) {
      setState(() => _isClosed = c.isClosed);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
        .watch(closingByVisitIdProvider(widget.visit.id))
        .whenData(_fillIfNeeded);

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

          // VALIDATION SUMMARY
          _buildValidationSection(context, ref),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildValidationSection(BuildContext context, WidgetRef ref) {
    final validationAsync = ref.watch(visitValidationProvider(widget.visit.id));

    return validationAsync.when(
      data: (errors) {
        if (errors.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC6F6D5), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6F6D5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2D6A4F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VALIDAZIONE COMPLETATA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D6A4F),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tutti i campi obbligatori risultano compilati. La visita può essere chiusa con le firme.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _CardGroup(
          title: 'Campi Incompleti o Anomalie',
          subtitle:
              'L\'ispezione non può essere chiusa finché questi punti non sono risolti',
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: errors.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.blueGrey.shade50, height: 32),
                itemBuilder: (context, index) {
                  final error = errors[index];
                  return InkWell(
                    onTap: () {
                      final hasMarchio = widget.visit.visitType.contains(
                        'MARCHIO',
                      );
                      int targetIndex = 0;

                      switch (error.section) {
                        case 'Riepilogo':
                          targetIndex = 0;
                          break;
                        case 'Anagrafica':
                          targetIndex = 1;
                          break;
                        case 'Scopo Controllo':
                          targetIndex = 2;
                          break;
                        case 'Documenti di rif.':
                          targetIndex = 3;
                          break;
                        case 'Gestione NC':
                          targetIndex = 4;
                          break;
                        case 'UEC/Lotti':
                          targetIndex = 5;
                          break;
                        case 'Checklist':
                          targetIndex = 6;
                          break;
                        case 'Coltivazione':
                          targetIndex = 7;
                          break;
                        case 'Bilancio di massa':
                          targetIndex = 8;
                          break;
                        case 'Post-raccolta':
                          targetIndex = 9;
                          break;
                        case 'Attività':
                          targetIndex = hasMarchio ? 10 : 9;
                          break;
                        case 'Allegati':
                          targetIndex = hasMarchio ? 11 : 10;
                          break;
                        case 'Esito/Chiusura':
                          targetIndex = hasMarchio ? 12 : 11;
                          break;
                      }

                      ref.read(visitWorkspaceIndexProvider.notifier).state =
                          targetIndex;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      error.section.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueGrey.shade400,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.blueGrey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  error.message,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
        ),
      ),
      error: (e, s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Errore nel caricamento della validazione: $e',
          style: TextStyle(color: Colors.red.shade700),
        ),
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
  Timer? _debounceTimer;

  List<TextEditingController> get _allControllers => [
    _prevNcRequirementsStillKO,
    _prevCorrectiveActionsDetails,
    _prevOrgCertifiedDate,
    _prevOrgSanctionedDate,
    _biosSanctionDetails,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _loaded && !_saving) {
        _autoSave();
      }
    });
  }

  @override
  void dispose() {
    // Forza salvataggio finale se c'è un timer pendente
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      try {
        final db = ref.read(appDatabaseProvider);
        db.upsertPreviousNcManagement(
          visitId: widget.visitId,
          prevNcResults: _prevNcResults,
          prevNcRequirementsStillKO: _prevNcRequirementsStillKO.text.trim(),
          prevCorrectiveActionsCoherent: _prevCorrectiveActionsCoherent,
          prevCorrectiveActionsDetails: _prevCorrectiveActionsDetails.text
              .trim(),
          prevOrgCertifiedDate: _prevOrgCertifiedDate.text.trim(),
          prevOrgSanctionedDate: _prevOrgSanctionedDate.text.trim(),
          biosSanctionDetails: _biosSanctionDetails.text.trim(),
        );
      } catch (e) {
        debugPrint('Error during final NC save: $e');
      }
    }
    _debounceTimer?.cancel();
    for (final c in _allControllers) {
      c.removeListener(_onFieldChanged);
    }
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

  /// Salvataggio automatico silenzioso
  Future<void> _autoSave() async {
    if (widget.isReadOnly || _saving) return;
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
    } catch (e) {
      debugPrint('Error in NC autoSave: $e');
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
                    (v) {
                      setState(() => _prevNcResults = int.parse(v!));
                      _autoSave();
                    },
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
                    (v) {
                      setState(
                        () => _prevCorrectiveActionsCoherent = int.parse(v!),
                      );
                      _autoSave();
                    },
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

              Row(
                children: [
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
            enabled: true, // Keep enabled true so M3 respects fillColor
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
                borderSide: const BorderSide(color: Colors.black, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black87, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? initialDate;
                      try {
                        if (controller.text.isNotEmpty) {
                          initialDate = DateFormat(
                            'dd/MM/yyyy',
                          ).parse(controller.text);
                        }
                      } catch (_) {}

                      final now = DateTime.now();
                      DateTime initDate = initialDate ?? now;
                      final firstDate = DateTime(2000);
                      final lastDate = DateTime(2100);
                      if (initDate.isBefore(firstDate)) initDate = firstDate;
                      if (initDate.isAfter(lastDate)) initDate = lastDate;

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        locale: const Locale('it', 'IT'),
                        builder: (dialogContext, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2D6A4F),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF1B4332),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2D6A4F),
                                ),
                              ),
                              datePickerTheme: DatePickerThemeData(
                                headerBackgroundColor: const Color(0xFF2D6A4F),
                                headerForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                dayStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                surfaceTintColor: Colors.transparent,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                        setState(() {});
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2D6A4F,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon ?? Icons.calendar_today_rounded,
                              size: 20,
                              color: const Color(0xFF2D6A4F),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.text.isEmpty
                                      ? 'Seleziona data'
                                      : controller.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty && !widget.isReadOnly)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                      color: Colors.red.shade400,
                      tooltip: 'Pulisci data',
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
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
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.black87, width: 1.2),
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
  final TextEditingController _extraController = TextEditingController();

  @override
  void dispose() {
    _extraController.dispose();
    super.dispose();
  }

  bool _isImage(String filePath) {
    const imageExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
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
    final documentsAsync = ref.watch(_documentsListProvider(widget.visitId));

    return documentsAsync.when(
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
              icon: Icons.verified_user_rounded,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blueGrey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  'Disciplinare/i Regionale di Difesa Integrata adottati dall\'azienda (rev.08)',
                            ),
                            (
                              type: 'LINEE_GUIDA',
                              label:
                                  'Linee Guida Nazionali di Difesa Integrata',
                            ),
                            (
                              type: 'CHECKLIST_CONTROL_REV',
                              label:
                                  'Checklist di Controllo (Allegato interno Bios) (Digitale in-App)',
                            ),
                            (
                              type: 'RIFERIMENTO_ALTRO',
                              label:
                                  'Altro documento di riferimento (specificare)',
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
                                  'REGISTRO AZIENDALE SQNPI (quaderno di campagna, Registro operazioni colturali, magazzino)',
                            ),
                            (
                              type: 'AUTOCONTROLLO',
                              label: 'Evidenza autocontrollo interno',
                            ),
                            (
                              type: 'AUDIT_BIOS_PREC',
                              label:
                                  "Rapporto dell'audit Bios precedente (se applicabile)",
                            ),
                            (
                              type: 'ESITO_CERT_ALTRO_ODC',
                              label:
                                  'Esito certificazione / NC altro OdC (se applicabile)',
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
    required List<VisitDocument> attachments,
    required String title,
    required String category,
    required List<({String type, String label})> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => _buildDocItem(
            context: context,
            documents: attachments,
            category: category,
            type: item.type,
            label: item.label,
          ),
        ),
      ],
    );
  }

  Widget _buildDocItem({
    required BuildContext context,
    required List<VisitDocument> documents,
    required String category,
    required String type,
    required String label,
  }) {
    final companyAsync = ref.watch(companyByVisitIdProvider(widget.visitId));
    final isNewOperator = companyAsync.value?.isNewOperator ?? false;

    final isSystemDoc =
        type == 'CHECKLIST_CONTROL_REV' || type == 'ESITO_CERT_ALTRO_ODC';

    // Selezione forzata automatica
    final isAutomaticSelection =
        type == 'CHECKLIST_CONTROL_REV' ||
        (type == 'ESITO_CERT_ALTRO_ODC' && isNewOperator);

    final isSelected =
        isAutomaticSelection ||
        documents.any(
          (d) => d.category == category && d.docType == type && d.isChecked,
        );
    final doc = documents.firstWhereOrNull(
      (d) => d.category == category && d.docType == type,
    );
    final hasFile = doc != null && doc.filePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.blueGrey.shade100,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.isReadOnly
              ? null
              : () async {
                  if (hasFile) {
                    _openFile(doc.filePath);
                  } else if (isSelected) {
                    await _handleAddFileToDoc(category, type, label, doc);
                  } else {
                    // Se NON è selezionato, lo selezioniamo e poi apriamo il selettore file
                    await _handleToggleDocSelection(category, type, label);
                    if (mounted) {
                      await Future.delayed(const Duration(milliseconds: 50));
                      final updatedDocs = await ref
                          .read(appDatabaseProvider)
                          .getDocumentsByVisitId(widget.visitId);
                      final newDoc = updatedDocs.firstWhereOrNull(
                        (d) => d.category == category && d.docType == type,
                      );
                      if (mounted) {
                        await _handleAddFileToDoc(
                          category,
                          type,
                          label,
                          newDoc,
                        );
                      }
                    }
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.isReadOnly || isSystemDoc
                      ? null
                      : () async {
                          if (isSelected) {
                            await _handleDeleteDoc(doc!);
                          } else {
                            await _handleToggleDocSelection(
                              category,
                              type,
                              label,
                            );
                          }
                        },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isSystemDoc ? Colors.green : Colors.blue)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? (isSystemDoc ? Colors.green : Colors.blue)
                            : Colors.blueGrey.shade200,
                        width: isSelected ? 0 : 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: (isSystemDoc && isSelected)
                              ? Colors.green.shade700
                              : (isSelected
                                    ? Colors.blue.shade900
                                    : Colors.blueGrey.shade900),
                        ),
                      ),
                      if (isSystemDoc)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'AUTOMATICO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      if (isSelected && !isSystemDoc) ...[
                        if (type == 'DISCIPLINARE' || type.contains('ALTRO'))
                          _buildDocExtraField(doc!, 'DETTAGLI REGIONE/ANNO'),
                        if (type == 'LINEE_GUIDA')
                          _buildDocYearDropdown(doc!, 'ANNO DI RIFERIMENTO'),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Row(
                    children: [
                      if (hasFile)
                        _DocCircleIconButton(
                          icon: _isImage(doc.filePath)
                              ? Icons.visibility_rounded
                              : Icons.file_present_rounded,
                          color: Colors.blueAccent,
                          onPressed: () => _openFile(doc.filePath),
                          tooltip: 'Visualizza',
                        )
                      else
                        _DocCircleIconButton(
                          icon: Icons.add_a_photo_rounded,
                          color: Colors.blueGrey.shade400,
                          onPressed: () =>
                              _handleAddFileToDoc(category, type, label, doc),
                          tooltip: 'Allega file',
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

  Widget _buildDocExtraField(VisitDocument doc, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: doc.extraValue,
            maxLines: null,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.blueGrey.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.blueGrey.shade200,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.blueGrey.shade200,
                  width: 1,
                ),
              ),
            ),
            onChanged: (val) {
              ref
                  .read(appDatabaseProvider)
                  .updateDocumentExtra(id: doc.id, extraValue: val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocYearDropdown(VisitDocument doc, String label) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => (currentYear - index).toString());

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey.shade200, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: years.contains(doc.extraValue) ? doc.extraValue : null,
                isExpanded: true,
                hint: const Text(
                  'Seleziona anno...',
                  style: TextStyle(fontSize: 11),
                ),
                items: years
                    .map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Text(
                          y,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.isReadOnly
                    ? null
                    : (val) {
                        if (val != null) {
                          ref
                              .read(appDatabaseProvider)
                              .updateDocumentExtra(id: doc.id, extraValue: val);
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleDocSelection(
    String category,
    String type,
    String label,
  ) async {
    String extraValue = '';
    if (type.contains('ALTRO')) {
      final name = await _showNameDialog();
      if (!mounted || name == null || name.trim().isEmpty) return;
      extraValue = name.trim();
    }

    final docId = 'DOC-${widget.visitId}-$category-$type';
    await ref
        .read(appDatabaseProvider)
        .upsertDocument(
          id: docId,
          visitId: widget.visitId,
          category: category,
          docType: type,
          isChecked: true,
          extraValue: extraValue,
        );
  }

  Future<void> _handleDeleteDoc(VisitDocument doc) async {
    final ok = await _showDocConfirm(
      context,
      title: 'Rimuovi Selezione',
      message: 'Vuoi rimuovere questo documento?',
    );
    if (ok == true) {
      if (doc.filePath.isNotEmpty) {
        try {
          await File(doc.filePath).delete();
        } catch (_) {}
      }
      await ref.read(appDatabaseProvider).deleteDocument(doc.id);
    }
  }

  Future<void> _handleAddFileToDoc(
    String category,
    String type,
    String label, [
    VisitDocument? existing,
  ]) async {
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
              title: const Text('File / Galleria'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    XFile? file;
    if (source == 'camera') {
      file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } else {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        file = XFile(result.files.first.path!);
      }
    }

    if (file == null) return;

    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'visit_documents'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final destPath = p.join(
      dir.path,
      'DOC_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
    );
    await File(file.path).copy(destPath);

    if (existing != null) {
      await ref
          .read(appDatabaseProvider)
          .updateDocumentFile(id: existing.id, filePath: destPath);
    } else {
      final docId = 'DOC-${widget.visitId}-$category-$type';
      await ref
          .read(appDatabaseProvider)
          .upsertDocument(
            id: docId,
            visitId: widget.visitId,
            category: category,
            docType: type,
            filePath: destPath,
            isChecked: true,
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
                const Text(
                  'Specifica Nome Documento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Es: Certificato Bio, Registro 2024...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, controller.text),
                        child: const Text('Conferma'),
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
  String? message,
  Widget? content,
  IconData? icon,
  Color? iconColor,
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
          margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  color:
                      (isDestructive ? Colors.red : (iconColor ?? Colors.blue))
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ??
                      (isDestructive
                          ? Icons.delete_outline_rounded
                          : Icons.info_outline_rounded),
                  color: isDestructive
                      ? Colors.red
                      : (iconColor ?? Colors.blue),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (message != null)
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ?content,
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Annulla',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                            : (iconColor ?? Colors.blueAccent),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
