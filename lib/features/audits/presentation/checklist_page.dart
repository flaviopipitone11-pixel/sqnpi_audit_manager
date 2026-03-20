import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../data/audits_repository.dart';
import '../../admin/application/activity_logger.dart';
import '../../auth/presentation/auth_controller.dart';

final checklistResetProvider = StateProvider<int>((ref) => 0);

final uecsByVisitIdProvider = StreamProvider.family<List<VisitUec>, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUecsByVisitId(visitId);
});

final visitProvider = StreamProvider.family<Visit?, String>((ref, visitId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisitById(visitId);
});

final fasiProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchFasi();
});

final checklistItemsByFaseProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, fase) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchChecklistItemsByFase(fase);
});

final responsesByVisitAndItemProvider = StreamProvider.family<
    List<ChecklistResponse>,
    ({String visitId, String itemCode})>((ref, p) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchResponsesByVisitAndItem(p.visitId, p.itemCode);
});

final sumPunteggioUecProvider = StreamProvider.family<int, String>((
  ref,
  uecId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSumPunteggioUec(uecId);
});

final sumPunteggioOperatoreByVisitProvider = StreamProvider.family<int, String>(
  (ref, visitId) {
    final db = ref.watch(appDatabaseProvider);
    return db.watchSumPunteggioOperatoreByVisit(visitId);
  },
);

final attachmentsCountByCodeProvider = StreamProvider.family<int, String>((
  ref,
  code,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAttachmentsCountByChecklistCode(code);
});

final attachmentsByCodeProvider =
    StreamProvider.family<List<VisitAttachment>, String>((ref, code) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchAttachmentsLinkedToChecklist(code);
    });

final allResponsesByUecProvider = StreamProvider.family<List<ChecklistResponse>, String>((ref, uecId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchResponsesByUecId(uecId);
});

bool isPhaseVisible(String fase, String visitType) {
  final fUpper = fase.toUpperCase();
  
  // Sempre visibili (Valutazione, Coltivazione, Bilancio)
  if (fUpper.contains('COLTIVAZIONE')) return true;
  if (fUpper.contains('VALUTAZIONE')) return true;
  if (fUpper.contains('BILANCIO')) return true;
  if (fUpper.contains('GENERICA')) return true;
  if (fUpper.contains('IMPEGNI')) return true;

  // Condizionali in base allo scopo
  if (visitType.contains('ACA')) {
    if (fUpper.contains('ACA')) return true;
    if (fUpper.contains('AGRONOMICHE')) return true; 
  }
  
  if (visitType.contains('MARCHIO')) {
    if (fUpper.contains('ACA')) return true;
    if (fUpper.contains('MARCHIO')) return true;
    if (fUpper.contains('AGRONOMICHE')) return true;
    if (fUpper.contains('POST-RACCOLTA')) return true;
    if (fUpper.contains('RINTRACC')) return true;
  }
  
  if (visitType.contains('CAMPIONAMENTO')) {
    if (fUpper.contains('CAMPION')) return true;
  }

  // Se ALTRO è selezionato, mostriamo tutto
  if (visitType.contains('ALTRO')) return true;

  return false;
}

final isUecChecklistCompleteProvider = StreamProvider.family<bool, ({String visitId, String uecId})>((ref, p) async* {
  final visitAsync = ref.watch(visitProvider(p.visitId));
  final fasiAsync = ref.watch(fasiProvider);
  final responsesAsync = ref.watch(allResponsesByUecProvider(p.uecId));

  if (visitAsync.isLoading || fasiAsync.isLoading || responsesAsync.isLoading) {
    yield false;
    return;
  }

  final visit = visitAsync.value;
  final visitType = visit?.visitType ?? 'ACA';
  final allFasi = fasiAsync.value ?? [];
  final responses = responsesAsync.value ?? [];

  final filteredFasi = allFasi.where((f) => isPhaseVisible(f, visitType)).toList();
  if (filteredFasi.isEmpty) {
    yield true;
    return;
  }

  // To truly know if it's complete, we need the items of ALL filtered phases.
  // This is a bit heavy for a single stream, but necessary.
  List<ChecklistItem> allApplicableItems = [];
  for (var fase in filteredFasi) {
    final itemsAsync = ref.watch(checklistItemsByFaseProvider(fase));
    if (itemsAsync.hasValue) {
      allApplicableItems.addAll(itemsAsync.value!);
    }
  }

  // Requirements are items that are NOT headers
  final requirements = allApplicableItems.where((item) {
    final codeTrimmed = item.code.trim();
    return !(!codeTrimmed.contains('.') || 
             RegExp(r'\.0$').hasMatch(codeTrimmed) ||
             RegExp(r'\.(?!\d)').hasMatch(codeTrimmed));
  }).toList();

  if (requirements.isEmpty) {
    yield true;
    return;
  }

  final respondedCodes = responses.map((r) => r.itemCode).toSet();
  yield requirements.every((item) => respondedCodes.contains(item.code));
});

class ChecklistPage extends ConsumerStatefulWidget {
  const ChecklistPage({
    super.key,
    required this.visitId,
    this.isReadOnly = false,
  });
  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends ConsumerState<ChecklistPage> {
  String? _selectedFase;
  int _resetCounter = 0;

  Future<void> _clearAllResponses(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 450,
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
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Svuota Checklist',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sei sicuro di voler eliminare TUTTI gli esiti salvati in questa checklist? L\'operazione non è reversibile.',
                  style: TextStyle(
                      fontSize: 16, color: Colors.blueGrey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Annulla',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Svuota Tutto',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
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

    if (ok == true) {
      await ref
          .read(auditsRepositoryProvider)
          .clearAllVisitChecklistResponses(widget.visitId);

      if (mounted) {
        ref.read(checklistResetProvider.notifier).update((s) => s + 1);
        setState(() {
          _resetCounter++;
          final currentFase = _selectedFase;
          _selectedFase = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedFase = currentFase);
          });
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checklist svuotata con successo.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(widget.visitId));
    final visitAsync = ref.watch(visitProvider(widget.visitId));
    final fasiAsync = ref.watch(fasiProvider);

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
              if (uecs.isEmpty) {
                return const Center(
                  child: Text(
                    'Prima di compilare la checklist, crea almeno una UEC in “Coltura e UEC”.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Checklist SQNPI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (!widget.isReadOnly)
                        TextButton.icon(
                          onPressed: () => _clearAllResponses(context, ref),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: Colors.red, size: 20),
                          label: const Text('Pulisci tutto',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: fasiAsync.when(
                          data: (fasi) {
                            if (fasi.isEmpty) {
                              return const Text('Checklist non importata.');
                            }

                            final visit = visitAsync.value;
                            final visitType = visit?.visitType ?? 'ACA';

                            final filteredFasi = fasi
                                .where((f) => isPhaseVisible(f, visitType))
                                .toList();

                            if (filteredFasi.isEmpty) filteredFasi.addAll(fasi);

                            if (filteredFasi.isEmpty) {
                              return const Text(
                                  'Nessuna fase trovata nel database.');
                            }

                            final activeFase = (_selectedFase != null &&
                                    filteredFasi.contains(_selectedFase))
                                ? _selectedFase!
                                : filteredFasi.first;

                            if (activeFase != _selectedFase) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => _selectedFase = activeFase);
                                }
                              });
                            }

                            return Row(
                              children: [
                                const Text(
                                  'Fase:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: activeFase,
                                    items: filteredFasi
                                        .map(
                                          (f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(
                                              f,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedFase = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(
                            width: 180,
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, _) => Text('Errore fasi: $e'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ScoreBadges(visitId: widget.visitId),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: (_selectedFase == null)
                        ? const Center(child: Text('Seleziona una fase.'))
                        : _ChecklistList(
                            key: ValueKey('reset-$_resetCounter-$_selectedFase'),
                            visitId: widget.visitId,
                            fase: _selectedFase!,
                            isReadOnly: widget.isReadOnly,
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Errore UEC: $e'),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadges extends ConsumerWidget {
  const _ScoreBadges({required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Per ora mostriamo solo il punteggio operatore della visita.
    // In futuro potremmo mostrare il massimo punteggio UEC tra tutte le UEC della visita.
    final sumOpAsync = ref.watch(sumPunteggioOperatoreByVisitProvider(visitId));

    return Row(
      children: [
        /*
        sumUecAsync.when(
          data: (sum) {
            final warn = sum >= 10;
            return Row(
              children: [
                Text(
                  'Somma punteggi UEC: $sum',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warn ? Colors.red : null,
                  ),
                ),
                if (warn) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                ],
              ],
            );
          },
          loading: () =>
              const SizedBox(width: 140, child: LinearProgressIndicator()),
          error: (e, _) => Text('Somma UEC err: $e'),
        ),
        const SizedBox(width: 16),
        */
        sumOpAsync.when(
          data: (sum) {
            final warn = sum >= 20;
            return Row(
              children: [
                Text(
                  'Somma punteggi Operatore: $sum',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warn ? Colors.red : null,
                  ),
                ),
                if (warn) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                ],
              ],
            );
          },
          loading: () =>
              const SizedBox(width: 180, child: LinearProgressIndicator()),
          error: (e, _) => Text('Somma Op err: $e'),
        ),
      ],
    );
  }
}

class _ChecklistList extends ConsumerWidget {
  const _ChecklistList({
    super.key,
    required this.visitId,
    required this.fase,
    required this.isReadOnly,
  });
  final String visitId;
  final String fase;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsByFaseProvider(fase));
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('Nessun requisito trovato per questa fase.'),
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) => _ChecklistItemCard(
            visitId: visitId,
            item: items[i],
            isReadOnly: isReadOnly,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore checklist: $e')),
    );
  }
}

class _ChecklistItemCard extends ConsumerStatefulWidget {
  const _ChecklistItemCard({
    required this.visitId,
    required this.item,
    required this.isReadOnly,
  });
  final String visitId;
  final ChecklistItem item;
  final bool isReadOnly;

  @override
  ConsumerState<_ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends ConsumerState<_ChecklistItemCard> {
  Conformita _conf = Conformita.ok;
  int? _livelloKo;
  int? _pUec;
  int? _pOp;
  final _rilievo = TextEditingController();
  final _note = TextEditingController();

  final Set<String> _selectedUecIds = {};
  bool _loaded = false;
  bool _saving = false;

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rilievo.dispose();
    _note.dispose();
    super.dispose();
  }

  void _loadFromResponses(List<ChecklistResponse> responses, List<VisitUec> allUecs) {
    if (_loaded) return;
    _loaded = true;

    if (responses.isEmpty) {
      if (allUecs.isNotEmpty) {
        _selectedUecIds.add(allUecs.first.id);
      }
      return;
    }

    // Se ci sono risposte, selezioniamo le UEC che ne hanno una
    for (final r in responses) {
      _selectedUecIds.add(r.uecId);
    }

    // Carichiamo i dati dalla prima risposta (o dalla più comune, ma per ora la prima)
    final r = responses.first;
    _conf = Conformita.values[r.conformita];
    _livelloKo = r.livelloKo;
    _pUec = r.punteggioUec;
    _pOp = r.punteggioOperatore;
    _rilievo.text = r.rilievoNc;
    _note.text = r.note;
  }

  void _loadSingleResponse(ChecklistResponse r) {
    setState(() {
      _conf = Conformita.values[r.conformita];
      _livelloKo = r.livelloKo;
      _pUec = r.punteggioUec;
      _pOp = r.punteggioOperatore;
      _rilievo.text = r.rilievoNc;
      _note.text = r.note;
    });
  }

  Future<void> _save() async {
    if (_selectedUecIds.isEmpty) return;
    
    setState(() => _saving = true);
    try {
      final repo = ref.read(auditsRepositoryProvider);
      await repo.saveChecklistResponsesForUecs(
        uecIds: _selectedUecIds.toList(),
        itemCode: widget.item.code,
        conformita: _conf,
        livelloKo: _conf == Conformita.ko ? _livelloKo : null,
        punteggioUec: _pUec,
        punteggioOperatore: _pOp,
        rilievoNc: _rilievo.text.trim(),
        note: _note.text.trim(),
      );

      if (_conf == Conformita.ko) {
        final logger = ref.read(activityLoggerProvider);
        final auth = ref.read(authControllerProvider);
        await logger.log(
          action: 'CREATE_NON_CONFORMITY',
          description: 'Rilevata NC su requisito ${widget.item.code} per UEC: ${_selectedUecIds.join(", ")}',
          actor: auth.username ?? 'Ispettore',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedUecIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 450,
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
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_forever_outlined,
                      color: Colors.red.shade700, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Conferma Eliminazione',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 16, color: Colors.blueGrey, height: 1.4),
                    children: [
                      const TextSpan(
                          text:
                              'Vuoi eliminare definitivamente gli esiti salvati per le '),
                      TextSpan(
                        text: '${_selectedUecIds.length} colture',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const TextSpan(text: ' selezionate in questo punto?'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Annulla',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Elimina',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
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

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(auditsRepositoryProvider);
      await repo.deleteChecklistResponses(
        uecIds: _selectedUecIds.toList(),
        itemCode: widget.item.code,
      );
      // Reset local state for the deleted items if needed
      if (mounted) {
        setState(() {
          _selectedUecIds.clear();
          _conf = Conformita.ok;
          _livelloKo = null;
          _pUec = null;
          _pOp = null;
          _rilievo.clear();
          _note.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onTextChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _save();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for global reset signal
    ref.listen(checklistResetProvider, (prev, next) {
      if (next > 0) {
        setState(() {
          _selectedUecIds.clear();
          _conf = Conformita.ok;
          _livelloKo = null;
          _pUec = null;
          _pOp = null;
          _rilievo.clear();
          _note.clear();
          _loaded = false;
        });
      }
    });

    final respAsync = ref.watch(
      responsesByVisitAndItemProvider(
        (visitId: widget.visitId, itemCode: widget.item.code),
      ),
    );
    final uecsAsync = ref.watch(uecsByVisitIdProvider(widget.visitId));

    return uecsAsync.when(
      data: (allUecs) => respAsync.when(
        data: (responses) {
          _loadFromResponses(responses, allUecs);

          final codeTrimmed = widget.item.code.trim();
          final isHeaderOnly = !codeTrimmed.contains('.') ||
              RegExp(r'\.0$').hasMatch(codeTrimmed) ||
              RegExp(r'\.(?!\d)').hasMatch(codeTrimmed);

          String title = _cleanText(widget.item.obbligo);
          String displayCode = codeTrimmed;

          if (isHeaderOnly) {
            final match = RegExp(r'^(\d+(\.\d+)?)').firstMatch(codeTrimmed);
            final numericCode = match?.group(1) ?? codeTrimmed;
            String cleanTitle = title
                .replaceAll(
                    RegExp('^Requisito\\s*$numericCode\\.?',
                        caseSensitive: false),
                    '')
                .trim();
            cleanTitle = cleanTitle
                .replaceAll(RegExp('^$numericCode\\.?', caseSensitive: false),
                    '')
                .trim();
            if (cleanTitle.startsWith('—')) {
              cleanTitle = cleanTitle.substring(1).trim();
            }
            title =
                cleanTitle.isEmpty ? numericCode : '$numericCode $cleanTitle';
          } else {
            displayCode = widget.item.indicatorType.isNotEmpty
                ? '$codeTrimmed — ${widget.item.indicatorType}'
                : codeTrimmed;
            title = displayCode;
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            color: isHeaderOnly
                ? Colors.blue.shade50.withValues(alpha: 0.3)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isHeaderOnly ? Colors.blue.shade100 : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isHeaderOnly ? 16 : 15,
                            color: isHeaderOnly
                                ? Colors.blue.shade900
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (_saving)
                        const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (!isHeaderOnly) ...[
                        const SizedBox(width: 8),
                        _AttachmentBadge(code: widget.item.code),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isHeaderOnly) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _cleanText(widget.item.obbligo),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Applica a:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        if (_selectedUecIds.isNotEmpty && !widget.isReadOnly) ...[
                          const Spacer(),
                          InkWell(
                            onTap: _deleteSelected,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_sweep_outlined,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pulisci esiti',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: allUecs.map((u) {
                        final isSelected = _selectedUecIds.contains(u.id);
                        final hasResponse =
                            responses.any((r) => r.uecId == u.id);

                        return FilterChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            u.nAggregato.isNotEmpty
                                ? '${u.nAggregato} (${u.coltura})'
                                : u.coltura,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: widget.isReadOnly
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedUecIds.add(u.id);
                                      if (_selectedUecIds.length == 1 &&
                                          hasResponse) {
                                        final r = responses.firstWhere(
                                            (res) => res.uecId == u.id);
                                        _loadSingleResponse(r);
                                      }
                                    } else {
                                      _selectedUecIds.remove(u.id);
                                    }
                                  });
                                  _save();
                                },
                          selectedColor: Theme.of(context).primaryColor,
                          backgroundColor: hasResponse
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          side: BorderSide(
                            color: hasResponse
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (widget.item.noteNorma.isNotEmpty ||
                        widget.item.tipologiaControllo.isNotEmpty ||
                        widget.item.frequenzaAssociato.isNotEmpty ||
                        widget.item.colGText.isNotEmpty ||
                        widget.item.frequenzaSingolo.isNotEmpty ||
                        widget.item.gravitaUecText.isNotEmpty ||
                        widget.item.gravitaOperatoreText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MetadataSection(item: widget.item),
                    ],
                const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ConfDropdown(
                          value: _conf,
                          onChanged: widget.isReadOnly
                              ? null
                              : (v) {
                                  setState(() {
                                    _conf = v;
                                    if (_conf != Conformita.ko) _livelloKo = null;
                                    if (widget.item.code == '0.1' &&
                                        _conf == Conformita.ko) {
                                      _livelloKo = 3;
                                    }
                                  });
                                  _save();
                                },
                        ),
                        if (_conf == Conformita.ko)
                          _LivelloKoDropdown(
                            value: _livelloKo,
                            onChanged: widget.isReadOnly
                                ? null
                                : (v) {
                                    setState(() => _livelloKo = v);
                                    _save();
                                  },
                          ),
                        if (widget.item.hasEsclusioneLotto &&
                            _conf == Conformita.ko)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NC GRAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        _ScoreDropdown(
                          label: 'Punteggio UEC/Lotto',
                          value: _pUec,
                          onChanged: widget.isReadOnly
                              ? null
                              : (v) {
                                  setState(() => _pUec = v);
                                  _save();
                                },
                        ),
                        _ScoreDropdown(
                          label: 'Punteggio Operatore',
                          value: _pOp,
                          onChanged: widget.isReadOnly
                              ? null
                              : (v) {
                                  setState(() => _pOp = v);
                                  _save();
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final formFields = [
                          Expanded(
                            child: TextFormField(
                              controller: _rilievo,
                              onChanged: _onTextChanged,
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              readOnly: widget.isReadOnly,
                              enabled: !widget.isReadOnly,
                              decoration: InputDecoration(
                                labelText:
                                    'Descrizione',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2D6A4F),
                                    width: 2,
                                  ),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (constraints.maxWidth > 600)
                            const SizedBox(width: 16),
                          if (constraints.maxWidth <= 600)
                            const SizedBox(height: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _note,
                              onChanged: _onTextChanged,
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              readOnly: widget.isReadOnly,
                              enabled: !widget.isReadOnly,
                              decoration: InputDecoration(
                                labelText:
                                    'Azione correttiva ( a cura dell\'operatore)',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2D6A4F),
                                    width: 2,
                                  ),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ];

                        if (constraints.maxWidth > 600) {
                          return Row(children: formFields);
                        } else {
                          return Column(children: formFields);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Errore risposta: $e'),
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Errore UEC: $e'),
        ),
      ),
    );
  }
}

class _ConfDropdown extends StatelessWidget {
  const _ConfDropdown({required this.value, required this.onChanged});
  final Conformita value;
  final ValueChanged<Conformita>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Conformità:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        DropdownButton<Conformita>(
          value: value,
          items: const [
            DropdownMenuItem(value: Conformita.ok, child: Text('OK')),
            DropdownMenuItem(value: Conformita.na, child: Text('NA')),
            DropdownMenuItem(value: Conformita.ko, child: Text('KO')),
          ],
          onChanged: (v) {
            if (v != null) onChanged?.call(v);
          },
        ),
      ],
    );
  }
}

class _LivelloKoDropdown extends StatelessWidget {
  const _LivelloKoDropdown({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Livello KO:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          value: value,
          items: const [
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 2, child: Text('2')),
            DropdownMenuItem(value: 3, child: Text('3')),
          ],
          hint: const Text('Seleziona'),
          onChanged: (v) => onChanged?.call(v),
        ),
      ],
    );
  }
}

class _AttachmentBadge extends ConsumerWidget {
  const _AttachmentBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(attachmentsCountByCodeProvider(code));

    return countAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return InkWell(
          onTap: () => _showAttachmentsDialog(context, ref, code),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showAttachmentsDialog(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Allegati Requisito $code'),
          content: SizedBox(
            width: 400,
            child: Consumer(
              builder: (ctx, ref, _) {
                final attsAsync = ref.watch(attachmentsByCodeProvider(code));
                return attsAsync.when(
                  data: (list) {
                    if (list.isEmpty) return const Text('Nessun allegato.');
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final att = list[i];
                        final isImg = _isImage(
                          att.filePath,
                        ); // Bisognerà importare o duplicare l'helper
                        return ListTile(
                          leading: isImg
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(att.filePath),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.insert_drive_file),
                          title: Text(
                            att.caption.isNotEmpty
                                ? att.caption
                                : 'Senza didascalia',
                          ),
                          subtitle: Text(
                            att.filePath.split('/').last,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Errore: $e'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext);
  }
}

class _ScoreDropdown extends StatelessWidget {
  const _ScoreDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          value: value,
          hint: const Text('—'),
          items: const [
            DropdownMenuItem(value: null, child: Text('—')),
            DropdownMenuItem(value: 0, child: Text('0')),
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 2, child: Text('2')),
            DropdownMenuItem(value: 3, child: Text('3')),
          ],
          onChanged: (v) => onChanged?.call(v),
        ),
      ],
    );
  }
}

String _cleanText(String? text) {
  if (text == null || text.isEmpty) return '';
  return text.trim().replaceAll(RegExp(r'\s+'), ' ');
}

class _MetadataSection extends StatelessWidget {
  final ChecklistItem item;
  const _MetadataSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.noteNorma.isNotEmpty)
          _MetadataItem(
            label: 'Note',
            content: item.noteNorma,
            icon: Icons.info_outline,
            backgroundColor: Colors.amber.shade50.withValues(alpha: 0.5),
            borderColor: Colors.amber.shade200,
            iconColor: Colors.amber.shade800,
          ),
        if (item.tipologiaControllo.isNotEmpty)
          _MetadataItem(
            label: 'Gravità NC (UEC/Lotto)',
            content: item.tipologiaControllo,
            icon: Icons.warning_amber_rounded,
            backgroundColor: Colors.blue.shade50.withValues(alpha: 0.5),
            borderColor: Colors.blue.shade200,
            iconColor: Colors.blue.shade700,
            isGravity: true,
          ),
        if (item.frequenzaAssociato.isNotEmpty)
          _MetadataItem(
            label: 'Gravità NC (Operatore)',
            content: item.frequenzaAssociato,
            icon: Icons.warning_amber_rounded,
            backgroundColor: Colors.blue.shade50.withValues(alpha: 0.5),
            borderColor: Colors.blue.shade200,
            iconColor: Colors.blue.shade700,
            isGravity: true,
          ),
        if (item.colGText.isNotEmpty)
          _MetadataItem(
            label: 'Riferimento',
            content: item.colGText,
            icon: Icons.menu_book_outlined,
            backgroundColor: Colors.grey.shade50,
            borderColor: Colors.grey.shade300,
            iconColor: Colors.grey.shade700,
          ),
        if (item.frequenzaSingolo.isNotEmpty)
          _MetadataItem(
            label: 'Frequenza',
            content: item.frequenzaSingolo,
            icon: Icons.calendar_today_outlined,
            backgroundColor: Colors.grey.shade50,
            borderColor: Colors.grey.shade300,
            iconColor: Colors.grey.shade700,
          ),
      ],
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final String label;
  final String content;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final bool isGravity;

  const _MetadataItem({
    required this.label,
    required this.content,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.isGravity = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedContent = _cleanText(content);
    if (cleanedContent.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                _renderContent(context, cleanedContent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderContent(BuildContext context, String cleanedContent) {
    if (isGravity && RegExp(r'\d\s*-\s*').hasMatch(cleanedContent)) {
      final items = cleanedContent.split(RegExp(r'\s+(?=\d\s*-\s*)'));
      if (items.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            final trimmed = item.trim();
            final match = RegExp(r'^(\d)\s*-\s*(.*)$').firstMatch(trimmed);
            if (match != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.4,
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: '${match.group(1)} - ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: match.group(2)),
                    ],
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                trimmed,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            );
          }).toList(),
        );
      }
    }

    return Text(
      cleanedContent,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade800,
        height: 1.4,
      ),
    );
  }
}
