import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';
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

final responsesByVisitAndItemProvider =
    StreamProvider.family<
      List<ChecklistResponse>,
      ({String visitId, String itemCode})
    >((ref, p) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchResponsesByVisitAndItem(p.visitId, p.itemCode);
    });

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

final allResponsesByUecProvider =
    StreamProvider.family<List<ChecklistResponse>, String>((ref, uecId) {
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

final isUecChecklistCompleteProvider =
    StreamProvider.family<bool, ({String visitId, String uecId})>((
      ref,
      p,
    ) async* {
      final visitAsync = ref.watch(visitProvider(p.visitId));
      final fasiAsync = ref.watch(fasiProvider);
      final responsesAsync = ref.watch(allResponsesByUecProvider(p.uecId));

      if (visitAsync.isLoading ||
          fasiAsync.isLoading ||
          responsesAsync.isLoading) {
        yield false;
        return;
      }

      final visit = visitAsync.value;
      final visitType = visit?.visitType ?? 'ACA';
      final allFasi = fasiAsync.value ?? [];
      final responses = responsesAsync.value ?? [];

      final filteredFasi = allFasi
          .where((f) => isPhaseVisible(f, visitType))
          .toList();
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
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Svuota Checklist',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sei sicuro di voler eliminare TUTTI gli esiti salvati in questa checklist? L\'operazione non è reversibile.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    height: 1.4,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Svuota Tutto',
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
                    'Prima di compilare la checklist, crea almeno una UEC in “Colture/ Prodotto in domanda e UEC”.',
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checklist SQNPI',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 800
                                    ? 20
                                    : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B4332),
                              ),
                            ),
                            Text(
                              'Lista di controllo per la verifica',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isReadOnly &&
                          MediaQuery.of(context).size.width > 600)
                        ElevatedButton.icon(
                          onPressed: () => _clearAllResponses(
                            context,
                            ref,
                          ), // Changed to existing method
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Pulisci tutto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!widget.isReadOnly &&
                      MediaQuery.of(context).size.width <= 600) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _clearAllResponses(
                          context,
                          ref,
                        ), // Changed to existing method
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Pulisci tutto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 200,
                              maxWidth: constraints.maxWidth,
                            ),
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

                                if (filteredFasi.isEmpty) {
                                  filteredFasi.addAll(fasi);
                                }

                                if (filteredFasi.isEmpty) {
                                  return const Text(
                                    'Nessuna fase trovata nel database.',
                                  );
                                }

                                final activeFase =
                                    (_selectedFase != null &&
                                        filteredFasi.contains(_selectedFase))
                                    ? _selectedFase!
                                    : filteredFasi.first;

                                if (activeFase != _selectedFase) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(
                                        () => _selectedFase = activeFase,
                                      );
                                    }
                                  });
                                }

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Fase:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              loading: () => Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: const LinearProgressIndicator(),
                              ),
                              error: (e, _) => Text('Errore fasi: $e'),
                            ),
                          ),
                          _ScoreBadges(visitId: widget.visitId),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: (_selectedFase == null)
                        ? const Center(child: Text('Seleziona una fase.'))
                        : _ChecklistList(
                            key: ValueKey(
                              'reset-$_resetCounter-$_selectedFase',
                            ),
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
    final summaryAsync = ref.watch(visitOutcomeSummaryProvider(visitId));

    return summaryAsync.when(
      data: (summary) {
        final warnOp =
            summary.sumOperatoreTotale >= VisitOutcomeSummary.sogliaOperatore;
        final warnUec = summary.sumUecTotale >= VisitOutcomeSummary.sogliaUec;

        return Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            // Punteggio Operatore
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Somma punteggi KO Operatore: ${summary.sumOperatoreTotale}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warnOp ? Colors.red : const Color(0xFF1B4332),
                  ),
                ),
                if (warnOp) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                ],
              ],
            ),
            // Punteggio UEC/LOTTO
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Somma punteggi KO UEC/Lotto: ${summary.sumUecTotale}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warnUec ? Colors.red : const Color(0xFF1B4332),
                  ),
                ),
                if (warnUec) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                ],
              ],
            ),
          ],
        );
      },
      loading: () =>
          const SizedBox(width: 200, child: LinearProgressIndicator()),
      error: (e, _) => Text(
        'Errore caricamento punteggi: $e',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
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
  final Set<String> _selectedUecIds = {};
  bool _loaded = false;
  bool _saving = false;
  Conformita _sharedConf = Conformita.ok;

  @override
  void dispose() {
    super.dispose();
  }

  void _loadFromResponses(
    List<ChecklistResponse> responses,
    List<VisitUec> allUecs,
  ) {
    if (_loaded) return;
    _loaded = true;

    if (responses.isEmpty) {
      if (allUecs.isNotEmpty) {
        _selectedUecIds.add(allUecs.first.id);
      }
      return;
    }

    for (final r in responses) {
      _selectedUecIds.add(r.uecId);
    }

    if (responses.isNotEmpty) {
      setState(() {
        _sharedConf = Conformita.values[responses.first.conformita];
      });
    }
  }

  void _onSharedConfChanged(Conformita v) {
    setState(() => _sharedConf = v);
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
                  child: Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red.shade700,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Conferma Eliminazione',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Vuoi eliminare definitivamente gli esiti salvati per le ',
                      ),
                      TextSpan(
                        text: '${_selectedUecIds.length} colture',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Elimina',
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
      if (mounted) {
        setState(() {
          _selectedUecIds.clear();
          _loaded = false;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for global reset signal
    ref.listen(checklistResetProvider, (prev, next) {
      if (next > 0) {
        setState(() {
          _selectedUecIds.clear();
          _loaded = false;
        });
      }
    });

    final respAsync = ref.watch(
      responsesByVisitAndItemProvider((
        visitId: widget.visitId,
        itemCode: widget.item.code,
      )),
    );
    final uecsAsync = ref.watch(uecsByVisitIdProvider(widget.visitId));

    return uecsAsync.when(
      data: (allUecs) => respAsync.when(
        data: (responses) {
          _loadFromResponses(responses, allUecs);

          final codeTrimmed = widget.item.code.trim();
          final isHeaderOnly =
              (!codeTrimmed.contains('.') ||
                  RegExp(r'\.0$').hasMatch(codeTrimmed) ||
                  RegExp(r'\.(?!\d)').hasMatch(codeTrimmed)) &&
              codeTrimmed != '14.0';

          String title = _cleanText(widget.item.obbligo);
          String displayCode = widget.item.displayCode;

          if (isHeaderOnly) {
            final numericCode = widget.item.displayCode;
            String cleanTitle = title
                .replaceAll(
                  RegExp(
                    '^Requisito\\s*$numericCode\\.?',
                    caseSensitive: false,
                  ),
                  '',
                )
                .trim();
            cleanTitle = cleanTitle
                .replaceAll(
                  RegExp('^$numericCode\\.?', caseSensitive: false),
                  '',
                )
                .trim();
            if (cleanTitle.startsWith('—')) {
              cleanTitle = cleanTitle.substring(1).trim();
            }
            title = cleanTitle.isEmpty
                ? numericCode
                : '$numericCode $cleanTitle';
          } else {
            displayCode = widget.item.indicatorType.isNotEmpty
                ? '${widget.item.displayCode} — ${widget.item.indicatorType}'
                : widget.item.displayCode;
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
                color: isHeaderOnly
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
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
                  if (!isHeaderOnly) ...[
                    const SizedBox(height: 8),
                    Text(
                      _cleanText(widget.item.obbligo),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _ConformitySelector(
                        value: _sharedConf,
                        onChanged: widget.isReadOnly
                            ? null
                            : _onSharedConfChanged,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Applica a:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        if (_selectedUecIds.isNotEmpty &&
                            !widget.isReadOnly) ...[
                          const Spacer(),
                          InkWell(
                            onTap: _deleteSelected,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_sweep_outlined,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pulisci esiti',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                        final hasResponse = responses.any(
                          (r) => r.uecId == u.id,
                        );

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
                                    } else {
                                      _selectedUecIds.remove(u.id);
                                    }
                                  });
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
                    if (!isHeaderOnly && _selectedUecIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._selectedUecIds.map((uecId) {
                        final uec = allUecs.firstWhere((u) => u.id == uecId);
                        final response = responses
                            .cast<ChecklistResponse?>()
                            .firstWhere(
                              (r) => r?.uecId == uecId,
                              orElse: () => null,
                            );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ChecklistOutcomeBlock(
                            key: ValueKey(
                              'outcome_\${uecId}_\${widget.item.code}_\${_sharedConf.index}',
                            ),
                            uec: uec,
                            item: widget.item,
                            visitId: widget.visitId,
                            isReadOnly: widget.isReadOnly,
                            initialResponse: response,
                            conformita: _sharedConf,
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 12),
              Text(
                'Caricamento esiti...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        error: (e, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Errore risposta: $e'),
          ),
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 12),
            Text(
              'Caricamento colture...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
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

class _ConformitySelector extends StatelessWidget {
  const _ConformitySelector({required this.value, required this.onChanged});
  final Conformita value;
  final ValueChanged<Conformita>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(context, 'OK', Conformita.ok, Colors.green.shade600),
          _buildButton(context, 'NA', Conformita.na, Colors.blueGrey.shade600),
          _buildButton(context, 'KO', Conformita.ko, Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    Conformita target,
    Color activeColor,
  ) {
    final isSelected = value == target;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                      fontFamily: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.fontFamily,
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
      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
    );
  }
}

class _ChecklistOutcomeBlock extends ConsumerStatefulWidget {
  const _ChecklistOutcomeBlock({
    super.key,
    required this.uec,
    required this.item,
    required this.visitId,
    required this.isReadOnly,
    required this.conformita,
    this.initialResponse,
  });

  final VisitUec uec;
  final ChecklistItem item;
  final String visitId;
  final bool isReadOnly;
  final Conformita conformita;
  final ChecklistResponse? initialResponse;

  @override
  ConsumerState<_ChecklistOutcomeBlock> createState() =>
      _ChecklistOutcomeBlockState();
}

class _ChecklistOutcomeBlockState
    extends ConsumerState<_ChecklistOutcomeBlock> {
  int? _pUec;
  int? _pOp;
  final _rilievo = TextEditingController();
  final _azione = TextEditingController();
  final _note = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final r = widget.initialResponse;
    if (r != null) {
      _pUec = r.punteggioUec;
      _pOp = r.punteggioOperatore;
      _rilievo.text = r.rilievoNc;
      _azione.text = (r as dynamic).azioneCorrettiva ?? '';
      _note.text = r.note;
    } else {
      if (widget.item.code == '0.1') _pUec = 3;
    }
  }

  @override
  void didUpdateWidget(_ChecklistOutcomeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conformita != widget.conformita) {
      if (widget.conformita != Conformita.ko) {
        _pUec = null;
        _pOp = null;
        _rilievo.clear();
        _azione.clear();
      } else {
        // Se torniamo su KO, riapplichiamo i default per i punti speciali
        if (widget.item.code.trim() == '0.1') _pUec = 3;
      }
      _save();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rilievo.dispose();
    _azione.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(auditsRepositoryProvider);
    await repo.saveChecklistResponsesForUecs(
      uecIds: [widget.uec.id],
      itemCode: widget.item.code,
      conformita: widget.conformita,
      livelloKo: widget.conformita == Conformita.ko ? (_pUec ?? _pOp) : null,
      punteggioUec: widget.conformita == Conformita.ko ? _pUec : null,
      punteggioOperatore: widget.conformita == Conformita.ko ? _pOp : null,
      rilievoNc: widget.conformita == Conformita.ko ? _rilievo.text.trim() : '',
      azioneCorrettiva: widget.conformita == Conformita.ko
          ? _azione.text.trim()
          : '',
      note: _note.text.trim(),
    );

    if (widget.conformita == Conformita.ko) {
      final logger = ref.read(activityLoggerProvider);
      final auth = ref.read(authControllerProvider);
      await logger.log(
        action: 'CREATE_NON_CONFORMITY',
        description:
            'Rilevata NC su requisito \${widget.item.code} per UEC: \${widget.uec.id}',
        actor: auth.username ?? 'Ispettore',
      );
    }
  }

  void _onTextChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _save);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Esito per: ${widget.uec.nAggregato.isNotEmpty ? widget.uec.nAggregato : widget.uec.coltura}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (widget.conformita == Conformita.ko) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!{
                  '0.5',
                  '0.6',
                  '0.13',
                  '1.10',
                  '1.11',
                  '3.1',
                  '3.2',
                  '10.5.1',
                  '10.5.2',
                  '11.3',
                  '15.6',
                  '15.7',
                  '15.8',
                  '15.9',
                  '15.10',
                  '15.11',
                  '15.12',
                  '15.13',
                  '15.14',
                  '15.15',
                  '17.6',
                  '17.9',
                }.contains(widget.item.code.trim()))
                  _ScoreDropdown(
                    label: 'Punteggio KO UEC/Lotto',
                    value: _pUec,
                    onChanged: widget.isReadOnly
                        ? null
                        : (v) {
                            setState(() => _pUec = v);
                            _save();
                          },
                  ),
                if (!{
                  '0.1',
                  '0.2',
                  '0.3',
                  '0.4',
                  '0.9',
                  '0.10',
                  '0.11',
                  '1.2.1',
                  '1.3',
                  '1.4',
                  '1.6',
                  '1.7',
                  '1.8',
                  '1.9',
                  '2.1',
                  '2.2',
                  '4.2',
                  '4.3',
                  '4.5',
                  '4.5.1',
                  '4.5.2',
                  '5.1',
                  '5.2',
                  '5.3',
                  '5.4',
                  '6.1',
                  '6.2',
                  '6.3',
                  '6.4',
                  '7.1',
                  '8.1.1',
                  '8.1.2',
                  '8.2.3',
                  '8.2.4',
                  '8.2.5',
                  '8.2.6',
                  '8.3',
                  '8.4',
                  '9.2',
                  '10.2',
                  '10.3',
                  '10.4',
                  '11.1',
                  '11.2',
                  '12.1',
                  '12.3',
                  '13.1',
                  '13.2',
                  '16.2',
                  '17.1',
                  '17.3',
                  '17.7',
                }.contains(widget.item.code.trim()))
                  _ScoreDropdown(
                    label: 'Punteggio KO Operatore',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rilievo,
                    onChanged: _onTextChanged,
                    minLines: 1,
                    maxLines: null,
                    readOnly: widget.isReadOnly,
                    decoration: InputDecoration(
                      labelText: 'Descrizione / Rilievi',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _azione,
                    onChanged: _onTextChanged,
                    minLines: 1,
                    maxLines: null,
                    readOnly: widget.isReadOnly,
                    decoration: InputDecoration(
                      labelText: 'Azione correttiva',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _note,
            onChanged: _onTextChanged,
            minLines: 1,
            maxLines: null,
            readOnly: widget.isReadOnly,
            decoration: InputDecoration(
              labelText: 'Note',
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
