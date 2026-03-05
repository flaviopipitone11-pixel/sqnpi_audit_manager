import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';

import 'checklist_page.dart';
import 'nc_page.dart';
import 'attachments_page.dart';
import 'report_page.dart';
import '../application/report_provider.dart';
import 'widgets/signature_dialog.dart';

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

class VisitWorkspacePage extends ConsumerStatefulWidget {
  const VisitWorkspacePage({super.key, required this.visitId});

  final String visitId;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Torna alla home',
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => ref
                              .read(reportServiceProvider)
                              .generateAndShareReport(widget.visitId),
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          tooltip: 'Esporta PDF',
                          color: Theme.of(context).primaryColor,
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.none,
            extended: true,
            minExtendedWidth: 160,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Riepilogo'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Azienda'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.agriculture_outlined),
                selectedIcon: Icon(Icons.agriculture),
                label: Text('UEC/Lotti'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: Text('Checklist'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning),
                label: Text('NC'),
              ),
              NavigationRailDestination(
                icon: Consumer(
                  builder: (ctx, ref, _) {
                    final count =
                        ref
                            .watch(_attachmentCountProvider(widget.visitId))
                            .valueOrNull ??
                        0;
                    return Badge(
                      label: count > 0 ? Text('$count') : null,
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.attach_file_outlined),
                    );
                  },
                ),
                selectedIcon: Consumer(
                  builder: (ctx, ref, _) {
                    final count =
                        ref
                            .watch(_attachmentCountProvider(widget.visitId))
                            .valueOrNull ??
                        0;
                    return Badge(
                      label: count > 0 ? Text('$count') : null,
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.attach_file),
                    );
                  },
                ),
                label: const Text('Allegati'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.draw_outlined),
                selectedIcon: Icon(Icons.draw),
                label: Text('Firme'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.picture_as_pdf_outlined),
                selectedIcon: Icon(Icons.picture_as_pdf),
                label: Text('Esporta PDF'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: visitAsync.when(
                data: (visit) {
                  if (visit == null) {
                    return const Center(child: Text('Visita non trovata.'));
                  }
                  return IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _RiepilogoSection(visit: visit),
                      _AziendaSection(
                        visitId: visit.id,
                        defaultCompanyName: visit.companyName,
                      ),
                      _UecLottiSection(
                        visitId: visit.id,
                        defaultColtura: visit.crop,
                      ),
                      ChecklistPage(visitId: visit.id),
                      NcPage(visitId: visit.id),
                      AttachmentsPage(visitId: visit.id),
                      _SignatureSection(visitId: visit.id),
                      ReportPage(visitId: visit.id),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Errore caricamento visita: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiepilogoSection extends StatelessWidget {
  const _RiepilogoSection({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final d = visit.scheduledAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
                value: visitStatusLabel(visit.status),
                icon: Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              _infoCard(
                context,
                title: 'Data e Ora',
                value: '$dateStr alle $timeStr',
                icon: Icons.calendar_today,
                color: Colors.blue.shade700,
              ),
            ],
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
                  _detailRow('Azienda', visit.companyName, Icons.business),
                  const Divider(height: 32),
                  _detailRow('Coltura principale', visit.crop, Icons.grass),
                  const Divider(height: 32),
                  _detailRow('ID Sistema', visit.id, Icons.fingerprint),
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

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String value,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
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
}

class _AziendaSection extends ConsumerStatefulWidget {
  const _AziendaSection({
    required this.visitId,
    required this.defaultCompanyName,
  });
  final String visitId;
  final String defaultCompanyName;

  @override
  ConsumerState<_AziendaSection> createState() => _AziendaSectionState();
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

  bool _loaded = false;
  bool _saving = false;

  double? _latitude;
  double? _longitude;

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
    _latitude = c?.latitude;
    _longitude = c?.longitude;
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
        latitude: _latitude,
        longitude: _longitude,
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
          child: companyAsync.when(
            data: (company) {
              _fillIfNeeded(company);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Azienda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _field(
                        'Ragione sociale',
                        _ragioneSociale,
                        width: 420,
                        icon: Icons.business,
                      ),
                      _field('CUAA', _cuaa, width: 220),
                      _field('Partita IVA', _piva, width: 220),
                      _field(
                        'Indirizzo',
                        _indirizzo,
                        width: 420,
                        icon: Icons.location_on_outlined,
                      ),
                      _field('CAP', _cap, width: 140),
                      _field('Comune', _comune, width: 280),
                      _field('Provincia', _provincia, width: 140),
                      _field(
                        'Referente',
                        _referente,
                        width: 280,
                        icon: Icons.person_outline,
                      ),
                      _field(
                        'Telefono',
                        _telefono,
                        width: 220,
                        icon: Icons.phone_outlined,
                      ),
                      _field(
                        'Email',
                        _email,
                        width: 340,
                        icon: Icons.email_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salva Azienda'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Salvataggio locale (offline). Verrà sincronizzato quando attiveremo la sync.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Errore caricamento azienda: $e')),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    required double width,
    IconData? icon,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: Colors.grey.shade500)
              : null,
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
  }
}

class _UecLottiSection extends ConsumerWidget {
  const _UecLottiSection({required this.visitId, required this.defaultColtura});
  final String visitId;
  final String defaultColtura;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _showAddUecDialog(BuildContext context, WidgetRef ref) async {
    final coltura = TextEditingController(text: defaultColtura);
    final descrizione = TextEditingController();
    final note = TextEditingController();

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
      coltura.dispose();
      descrizione.dispose();
      note.dispose();
      return;
    }

    final db = ref.read(appDatabaseProvider);
    await db.upsertUec(
      id: _newId('UEC'),
      visitId: visitId,
      coltura: coltura.text.trim(),
      descrizione: descrizione.text.trim(),
      note: note.text.trim(),
    );

    coltura.dispose();
    descrizione.dispose();
    note.dispose();
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
  const _SignatureSection({required this.visitId});
  final String visitId;

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
                        representativeSig?.signerName ?? 'Titolare / Delegato',
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
  });

  final String title;
  final String signerName;
  final VisitSignature? signature;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasSignature = signature != null;

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
              Column(
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
                        Text(
                          'Tocca per firmare',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.7),
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
          ],
        ],
      ),
    );
  }
}
