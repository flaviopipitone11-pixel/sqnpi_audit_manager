import 'package:sqnpi_audit_manager/core/utils/file_storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';
import '../application/checklist_item_helpers.dart';
import '../data/audits_repository.dart';
import '../../admin/application/activity_logger.dart';
import '../../auth/presentation/auth_controller.dart';

final checklistResetProvider = StateProvider<int>((ref) => 0);
final checklistFocusProvider = StateProvider<String?>((ref) => null);

const _operatorOnlyCodes = {
  '14.0',
  '14.1',
  '14.2',
  '14.4',
  '0.5',
  '0.6',
  '0.8',
  '0.12',
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
  '17.10',
};

const _dualAttributionCodes = {'16.2'};
const _operatorUecIdPrefix = 'OP-';

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
          .where((f) => ChecklistItemHelpers.isPhaseVisible(f, visitType))
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
  final TextEditingController _searchController = TextEditingController();
  String? _highlightedCode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appDatabaseProvider).ensureRequirement106Exists();
      // Forziamo il refresh della checklist
      ref.invalidate(checklistItemsByFaseProvider);
      ref.read(checklistResetProvider.notifier).state++;
    });
  }

  void _listenToFocus() {
    ref.listen<String?>(checklistFocusProvider, (previous, next) {
      if (next != null) {
        _searchItem(next);
        // Resettiamo il focus dopo l'uso
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(checklistFocusProvider.notifier).state = null;
        });
      }
    });
  }

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

  Future<void> _searchItem(String code) async {
    final query = code.trim();
    if (query.isEmpty) {
      setState(() => _highlightedCode = null);
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final phase = await db.getPhaseForChecklistCode(query);

    if (phase != null && mounted) {
      setState(() {
        _selectedFase = phase;
        _highlightedCode = query;
      });
      // Il widget list provvederà a scorrere automaticamente verso questo item
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Punto "$query" non trovato nella checklist.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _listenToFocus();
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

              return fasiAsync.when(
                data: (fasi) {
                  if (fasi.isEmpty) {
                    return const Center(
                      child: Text('Checklist non importata.'),
                    );
                  }

                  final visit = visitAsync.value;
                  final visitType = visit?.visitType ?? 'ACA';

                  final filteredFasi = fasi
                      .where(
                        (f) =>
                            ChecklistItemHelpers.isPhaseVisible(f, visitType),
                      )
                      .toList();

                  if (filteredFasi.isEmpty) {
                    filteredFasi.addAll(fasi);
                  }

                  final activeFase =
                      (_selectedFase != null &&
                          filteredFasi.contains(_selectedFase))
                      ? _selectedFase!
                      : filteredFasi.first;

                  if (activeFase != _selectedFase) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedFase = activeFase);
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER ROW (Titolo + Ricerca + Pulisci)
                      LayoutBuilder(
                        builder: (context, headerConstraints) {
                          final isCompact = headerConstraints.maxWidth < 650;

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Checklist SQNPI',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4332),
                                      ),
                                    ),
                                    if (!widget.isReadOnly)
                                      IconButton(
                                        onPressed: () =>
                                            _clearAllResponses(context, ref),
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Pulisci tutto',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cerca punto (es. 1.2)',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _highlightedCode = null);
                                      },
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: _searchItem,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Checklist SQNPI',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width >
                                                800
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
                              const SizedBox(width: 16),
                              SizedBox(
                                width: isCompact ? null : 350,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cerca punto (es. 1.2)',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _highlightedCode = null);
                                      },
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: _searchItem,
                                ),
                              ),
                              if (!widget.isReadOnly &&
                                  MediaQuery.of(context).size.width > 700) ...[
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _clearAllResponses(context, ref),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
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
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // SCORE BADGES
                      _ScoreBadges(visitId: widget.visitId),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // MAIN CONTENT (Sidebar + List)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final useSidebar = constraints.maxWidth > 900;

                            if (useSidebar) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ChecklistSidebar(
                                    fasi: filteredFasi,
                                    selectedFase: activeFase,
                                    onFaseSelected: (v) =>
                                        setState(() => _selectedFase = v),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _ChecklistList(
                                      key: ValueKey(
                                        'reset-$_resetCounter-$activeFase',
                                      ),
                                      visitId: widget.visitId,
                                      fase: activeFase,
                                      isReadOnly: widget.isReadOnly,
                                      highlightedCode: _highlightedCode,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _ChecklistChips(
                                    fasi: filteredFasi,
                                    selectedFase: activeFase,
                                    onFaseSelected: (v) =>
                                        setState(() => _selectedFase = v),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: _ChecklistList(
                                      key: ValueKey(
                                        'reset-$_resetCounter-$activeFase',
                                      ),
                                      visitId: widget.visitId,
                                      fase: activeFase,
                                      isReadOnly: widget.isReadOnly,
                                      highlightedCode: _highlightedCode,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Errore fasi: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore UEC: $e')),
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
  _ChecklistList({
    super.key,
    required this.visitId,
    required this.fase,
    required this.isReadOnly,
    this.highlightedCode,
  });

  final String visitId;
  final String fase;
  final bool isReadOnly;
  final String? highlightedCode;

  final GlobalKey _targetKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsByFaseProvider(fase));

    return itemsAsync.when(
      data: (items) {
        final filteredItems = items.where((item) {
          final code = item.code.trim();
          final displayCode = item.displayCode.trim();

          // Protezione esplicita per 4.5.1, 4.5.2, 8.1.1, 8.1.2, 8.2.3, 8.2.4, 8.2.5, 8.2.6, 10.5.1 e 10.5.2: non devono mai essere filtrati
          if (displayCode == '4.5.1' ||
              displayCode == '4.5.2' ||
              code == '4.5.1' ||
              code == '4.5.2' ||
              displayCode == '8.1.1' ||
              displayCode == '8.1.2' ||
              code == '8.1.1' ||
              code == '8.1.2' ||
              displayCode == '8.2.3' ||
              displayCode == '8.2.4' ||
              displayCode == '8.2.5' ||
              displayCode == '8.2.6' ||
              code == '8.2.3' ||
              code == '8.2.4' ||
              code == '8.2.5' ||
              code == '8.2.6' ||
              displayCode == '10.5.1' ||
              displayCode == '10.5.2' ||
              displayCode == '10.6' ||
              code == '10.5.1' ||
              code == '10.5.2' ||
              code == '10.6') {
            return true;
          }

          return code != '1.2' &&
              code != '1.5' &&
              displayCode != '4.5' &&
              code != '4.5' &&
              displayCode != '8.1' &&
              code != '8.1' &&
              displayCode != '8.2' &&
              code != '8.2' &&
              displayCode != '10.5' &&
              code != '10.5' &&
              code != '17.10';
        }).toList();

        if (highlightedCode != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_targetKey.currentContext != null) {
              Scrollable.ensureVisible(
                _targetKey.currentContext!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        return SingleChildScrollView(
          child: Column(
            children: filteredItems.map((item) {
              final isTarget = item.code.trim() == highlightedCode?.trim();
              return _ChecklistItemCard(
                key: isTarget ? _targetKey : null,
                visitId: visitId,
                item: item,
                isReadOnly: isReadOnly,
                isHighlighted: isTarget,
              );
            }).toList(),
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
    super.key,
    required this.visitId,
    required this.item,
    required this.isReadOnly,
    this.isHighlighted = false,
  });
  final String visitId;
  final ChecklistItem item;
  final bool isReadOnly;
  final bool isHighlighted;

  @override
  ConsumerState<_ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends ConsumerState<_ChecklistItemCard> {
  final Set<String> _selectedUecIds = {};
  bool _loaded = false;
  bool _saving = false;
  Conformita _sharedConf = Conformita.na;

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

    final isOpOnly = _operatorOnlyCodes.contains(widget.item.code.trim());

    if (isOpOnly) {
      if (allUecs.isNotEmpty) {
        _selectedUecIds.add(allUecs.first.id);
      }
      if (responses.isNotEmpty) {
        setState(() {
          _sharedConf = Conformita.values[responses.first.conformita];
        });
      }
      return;
    }

    if (responses.isEmpty) {
      if (allUecs.isNotEmpty) {
        if (_sharedConf == Conformita.ok || _sharedConf == Conformita.na) {
          for (final u in allUecs) {
            _selectedUecIds.add(u.id);
          }
          if (_dualAttributionCodes.contains(widget.item.code.trim())) {
            _selectedUecIds.add('$_operatorUecIdPrefix${widget.visitId}');
          }
        } else {
          _selectedUecIds.add(allUecs.first.id);
        }
      }
      return;
    }

    for (final r in responses) {
      _selectedUecIds.add(r.uecId);
    }

    if (responses.isNotEmpty) {
      final loadedConf = Conformita.values[responses.first.conformita];
      setState(() {
        _sharedConf = loadedConf;
      });
      if (loadedConf == Conformita.ok || loadedConf == Conformita.na) {
        for (final u in allUecs) {
          _selectedUecIds.add(u.id);
        }
        if (_dualAttributionCodes.contains(widget.item.code.trim())) {
          _selectedUecIds.add('$_operatorUecIdPrefix${widget.visitId}');
        }
      }
    }
  }

  void _onSharedConfChanged(Conformita v, List<VisitUec> allUecs) {
    setState(() {
      _sharedConf = v;
      if (v == Conformita.ok || v == Conformita.na) {
        // Se OK o NA, selezioniamo automaticamente tutte le colture
        for (final u in allUecs) {
          _selectedUecIds.add(u.id);
        }
        // Se il codice prevede doppia attribuzione, selezioniamo anche l'operatore
        if (_dualAttributionCodes.contains(widget.item.code.trim())) {
          _selectedUecIds.add('$_operatorUecIdPrefix${widget.visitId}');
        }
      }
    });
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
      data: (uecsFromDb) {
        final allUecs = uecsFromDb
            .where((u) => u.coltura.trim().toUpperCase() != 'OPERATORE')
            .toList();
        return respAsync.when(
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
              String indicatorType = widget.item.indicatorType;
              if (widget.item.code.trim() == '13.1' ||
                  widget.item.displayCode == '13.1' ||
                  widget.item.code.trim() == '13.2' ||
                  widget.item.displayCode == '13.2') {
                indicatorType = 'CD e CI';
              }
              displayCode = indicatorType.isNotEmpty
                  ? '${widget.item.displayCode} — $indicatorType'
                  : widget.item.displayCode;
              title = displayCode;
            }

            title = title.replaceAll('Raccoltai', 'Raccolta');

            final isDual = _dualAttributionCodes.contains(
              widget.item.code.trim(),
            );
            final Set<String> effectiveSelectedUecIds;
            if (_sharedConf != Conformita.ko) {
              effectiveSelectedUecIds = {
                ...allUecs.map((u) => u.id),
                if (isDual) '$_operatorUecIdPrefix${widget.visitId}',
              };
            } else {
              effectiveSelectedUecIds = _selectedUecIds;
            }

            return Card(
              elevation: widget.isHighlighted ? 4 : 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: widget.isHighlighted
                  ? Colors.green.shade50
                  : (isHeaderOnly
                        ? Colors.blue.shade50.withValues(alpha: 0.3)
                        : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.isHighlighted
                      ? Colors.green.shade400
                      : (isHeaderOnly
                            ? Colors.blue.shade100
                            : Colors.grey.shade200),
                  width: widget.isHighlighted ? 2 : 1,
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
                        (widget.item.code.trim() == '0.6' ||
                                widget.item.code.trim() == '1.1' ||
                                widget.item.code.trim() == '1.2.1' ||
                                widget.item.code.trim() == '1.2.2' ||
                                widget.item.code.trim() == '1.3' ||
                                widget.item.code.trim() == '1.4' ||
                                widget.item.code.trim() == '1.6' ||
                                widget.item.code.trim() == '1.7' ||
                                widget.item.code.trim() == '1.8' ||
                                widget.item.code.trim() == '1.9' ||
                                widget.item.code.trim() == '1.10' ||
                                widget.item.code.trim() == '1.11' ||
                                widget.item.code.trim() == '2.1' ||
                                widget.item.code.trim() == '2.2' ||
                                widget.item.code.trim() == '3.1' ||
                                widget.item.code.trim() == '3.2' ||
                                widget.item.code.trim() == '4.2' ||
                                widget.item.code.trim() == '4.3' ||
                                widget.item.code.trim().contains('4.5.1') ||
                                widget.item.displayCode.startsWith('4.5.1') ||
                                widget.item.code.trim().contains('4.5.2') ||
                                widget.item.displayCode.startsWith('4.5.2') ||
                                widget.item.displayCode.startsWith('4.6') ||
                                widget.item.code.trim() == '5.1' ||
                                widget.item.displayCode.startsWith('5.1') ||
                                widget.item.code.trim() == '5.2' ||
                                widget.item.displayCode.startsWith('5.2') ||
                                widget.item.code.trim() == '5.3' ||
                                widget.item.displayCode.startsWith('5.3') ||
                                widget.item.code.trim() == '5.4' ||
                                widget.item.displayCode.startsWith('5.4') ||
                                widget.item.code.trim() == '6.1' ||
                                widget.item.displayCode.startsWith('6.1') ||
                                widget.item.code.trim() == '6.2' ||
                                widget.item.displayCode.startsWith('6.2') ||
                                widget.item.code.trim() == '6.3' ||
                                widget.item.displayCode.startsWith('6.3') ||
                                widget.item.code.trim() == '6.4' ||
                                widget.item.displayCode.startsWith('6.4') ||
                                widget.item.code.trim() == '7.1' ||
                                widget.item.displayCode.startsWith('7.1') ||
                                widget.item.code.trim() == '8.1.1' ||
                                widget.item.displayCode.startsWith('8.1.1') ||
                                widget.item.code.trim() == '8.1.2' ||
                                widget.item.displayCode.startsWith('8.1.2') ||
                                widget.item.code.trim() == '8.2.3' ||
                                widget.item.displayCode.startsWith('8.2.3') ||
                                widget.item.code.trim() == '8.2.4' ||
                                widget.item.displayCode.startsWith('8.2.4') ||
                                widget.item.code.trim() == '8.2.5' ||
                                widget.item.displayCode.startsWith('8.2.5') ||
                                widget.item.code.trim() == '8.2.6' ||
                                widget.item.displayCode.startsWith('8.2.6') ||
                                widget.item.code.trim() == '8.3' ||
                                widget.item.displayCode.startsWith('8.3') ||
                                widget.item.code.trim() == '8.4' ||
                                widget.item.displayCode.startsWith('8.4') ||
                                widget.item.code.trim() == '9.2' ||
                                widget.item.displayCode.startsWith('9.2') ||
                                widget.item.code.trim() == '10.1' ||
                                widget.item.displayCode.startsWith('10.1') ||
                                widget.item.code.trim() == '10.2' ||
                                widget.item.displayCode.startsWith('10.2') ||
                                widget.item.code.trim() == '10.3' ||
                                widget.item.displayCode.startsWith('10.3') ||
                                widget.item.code.trim() == '10.4' ||
                                widget.item.displayCode.startsWith('10.4') ||
                                widget.item.code.trim() == '10.5.1' ||
                                widget.item.displayCode.startsWith('10.5.1') ||
                                widget.item.code.trim() == '10.5.2' ||
                                widget.item.displayCode.startsWith('10.5.2') ||
                                widget.item.code.trim() == '10.6' ||
                                widget.item.displayCode.startsWith('10.6') ||
                                widget.item.code.trim() == '11.1' ||
                                widget.item.displayCode.startsWith('11.1') ||
                                widget.item.code.trim() == '11.2' ||
                                widget.item.displayCode.startsWith('11.2') ||
                                widget.item.code.trim() == '11.3' ||
                                widget.item.displayCode.startsWith('11.3') ||
                                widget.item.code.trim() == '12.1' ||
                                widget.item.displayCode.startsWith('12.1') ||
                                widget.item.code.trim() == '12.2' ||
                                widget.item.displayCode.startsWith('12.2') ||
                                widget.item.code.trim() == '12.3' ||
                                widget.item.displayCode.startsWith('12.3') ||
                                widget.item.code.trim() == '13.1' ||
                                widget.item.displayCode.startsWith('13.1') ||
                                widget.item.code.trim() == '13.2' ||
                                widget.item.displayCode.startsWith('13.2') ||
                                widget.item.code.trim() == '14.0' ||
                                widget.item.displayCode.startsWith('14.0') ||
                                widget.item.code.trim() == '14.1' ||
                                widget.item.displayCode.startsWith('14.1') ||
                                widget.item.code.trim() == '14.2' ||
                                widget.item.displayCode.startsWith('14.2') ||
                                widget.item.code.trim() == '14.4' ||
                                widget.item.displayCode.startsWith('14.4') ||
                                widget.item.code.trim() == '15.1' ||
                                widget.item.displayCode.startsWith('15.1') ||
                                widget.item.code.trim() == '15.2' ||
                                widget.item.displayCode.startsWith('15.2') ||
                                widget.item.code.trim() == '15.3' ||
                                widget.item.displayCode.startsWith('15.3') ||
                                widget.item.code.trim() == '15.4' ||
                                widget.item.displayCode.startsWith('15.4') ||
                                widget.item.code.trim() == '15.5' ||
                                widget.item.displayCode.startsWith('15.5') ||
                                widget.item.code.trim() == '15.6' ||
                                widget.item.displayCode.startsWith('15.6') ||
                                widget.item.code.trim() == '15.7' ||
                                widget.item.displayCode.startsWith('15.7') ||
                                widget.item.code.trim() == '15.8' ||
                                widget.item.displayCode.startsWith('15.8') ||
                                widget.item.code.trim() == '15.9' ||
                                widget.item.displayCode.startsWith('15.9') ||
                                widget.item.code.trim() == '15.10' ||
                                widget.item.displayCode.startsWith('15.10') ||
                                widget.item.code.trim() == '15.11' ||
                                widget.item.displayCode.startsWith('15.11') ||
                                widget.item.code.trim() == '15.12' ||
                                widget.item.displayCode.startsWith('15.12') ||
                                widget.item.code.trim() == '15.13' ||
                                widget.item.displayCode.startsWith('15.13') ||
                                widget.item.code.trim() == '15.14' ||
                                widget.item.displayCode.startsWith('15.14') ||
                                widget.item.code.trim() == '15.15' ||
                                widget.item.displayCode.startsWith('15.15') ||
                                widget.item.code.trim() == '16.2' ||
                                widget.item.displayCode.startsWith('16.2') ||
                                widget.item.code.trim() == '16.3' ||
                                widget.item.displayCode.startsWith('16.3') ||
                                widget.item.displayCode.startsWith('16.4'))
                            ? ''
                            : (widget.item.code.trim() == '17.10' ||
                                  widget.item.displayCode.startsWith('17.10'))
                            ? 'ASSOLVIMENTO DEGLI OBBLIGHI CONTRATTUALI FASE POST RACCOLTA'
                            : (widget.item.code.trim() == '17.1' ||
                                  widget.item.displayCode.startsWith('17.1'))
                            ? 'Uso del marchio su prodotto certificato SQNPI'
                            : (widget.item.code.trim() == '17.9' ||
                                  widget.item.displayCode.startsWith('17.9'))
                            ? 'OSSERVATORIO SQNPI - (fase di post raccolta)'
                            : (widget.item.code.trim() == '8.2.3' ||
                                  widget.item.displayCode.startsWith('8.2.3') ||
                                  widget.item.code.trim() == '8.2.6' ||
                                  widget.item.displayCode.startsWith('8.2.6') ||
                                  widget.item.code.trim() == '8.3' ||
                                  widget.item.displayCode.startsWith('8.3') ||
                                  widget.item.code.trim() == '10.4' ||
                                  widget.item.displayCode.startsWith('10.4') ||
                                  widget.item.code.trim() == '11.1' ||
                                  widget.item.displayCode.startsWith('11.1') ||
                                  widget.item.displayCode.startsWith('14.0') ||
                                  widget.item.code.trim().startsWith('14.1') ||
                                  widget.item.displayCode.startsWith('14.1') ||
                                  widget.item.code.trim().startsWith('14.2') ||
                                  widget.item.displayCode.startsWith('14.2') ||
                                  widget.item.code.trim().startsWith('14.4') ||
                                  widget.item.displayCode.startsWith('14.4'))
                            ? ''
                            : (widget.item.code.trim().contains('4.5.1') ||
                                  widget.item.code.trim().contains('4.5.2') ||
                                  widget.item.displayCode.startsWith('4.5.1') ||
                                  widget.item.displayCode.startsWith('4.5.2'))
                            ? 'Il materiale di propagazione deve essere sano e garantito dal punto di vista genetico e deve essere in grado di offrire garanzie fitosanitarie e di qualità agronomica\n\n${_cleanText(widget.item.obbligo)}'
                            : (widget.item.code.trim().contains('8.1.1') ||
                                  widget.item.code.trim().contains('8.1.2') ||
                                  widget.item.displayCode.startsWith('8.1.1') ||
                                  widget.item.displayCode.startsWith('8.1.2'))
                            ? '*Negli appezzamenti con pendenza media superiore al 30%*\n\n${_cleanText(widget.item.obbligo)}'
                            : (widget.item.code.trim().contains('8.2.3') ||
                                  widget.item.code.trim().contains('8.2.4') ||
                                  widget.item.code.trim().contains('8.2.5') ||
                                  widget.item.code.trim().contains('8.2.6') ||
                                  widget.item.displayCode.startsWith('8.2.3') ||
                                  widget.item.displayCode.startsWith('8.2.4') ||
                                  widget.item.displayCode.startsWith('8.2.5') ||
                                  widget.item.displayCode.startsWith('8.2.6'))
                            ? 'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%\n\n${_cleanText(widget.item.obbligo)}'
                            : (widget.item.code.trim().contains('10.5.1') ||
                                  widget.item.code.trim().contains('10.5.2') ||
                                  widget.item.displayCode.startsWith(
                                    '10.5.1',
                                  ) ||
                                  widget.item.displayCode.startsWith('10.5.2'))
                            ? 'Esecuzione di analisi del suolo (effettuazione di un\'analisi almeno per ciascuna area omogenea dal punto di vista pedologico ed agronomico) prima della stesura del piano di fertilizzazione o utilizzo delle schede a dose standard\n\n${_cleanText(widget.item.obbligo)}'
                            : (widget.item.code.trim() == '13.1' ||
                                  widget.item.displayCode == '13.1')
                            ? 'Se disciplinati dalla Regione o P.A. verificare il rispetto dei parametri per inizio raccolta'
                            : (widget.item.code.trim() == '13.2' ||
                                  widget.item.displayCode == '13.2')
                            ? 'Se disciplinati dalla Regione o P.A. verificare il rispetto delle modalità di raccolta e conferimento ai centri di stoccaggio / lavorazione'
                            : (widget.item.code.trim() == '0.10' ||
                                  widget.item.code.trim() == '0.11')
                            ? _cleanText(widget.item.obbligo).replaceFirst(
                                'superfici catastali',
                                'superfici aziendali',
                              )
                            : (widget.item.code.trim() == '6.1')
                            ? "coinvolgimento intera superficie aziendale o parte di essa: devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)"
                            : (widget.item.code.trim() == '6.2')
                            ? "coinvolgimento superfici aziendali dedicate a specifiche colture :devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)"
                            : _cleanText(widget.item.obbligo),
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
                              : (v) => _onSharedConfChanged(v, allUecs),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_operatorOnlyCodes.contains(
                            widget.item.code.trim(),
                          ))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B4332,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OPERATORE',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4332),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else ...[
                            const Text(
                              'Applica a:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (effectiveSelectedUecIds.isNotEmpty &&
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (!_operatorOnlyCodes.contains(widget.item.code.trim()))
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_dualAttributionCodes.contains(
                              widget.item.code.trim(),
                            ))
                              FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: const Text(
                                  'OPERATORE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: _selectedUecIds.contains(
                                  '$_operatorUecIdPrefix${widget.visitId}',
                                ),
                                onSelected:
                                    (widget.isReadOnly ||
                                        _sharedConf != Conformita.ko)
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          final opId =
                                              '$_operatorUecIdPrefix${widget.visitId}';
                                          if (selected) {
                                            _selectedUecIds.add(opId);
                                          } else {
                                            _selectedUecIds.remove(opId);
                                          }
                                        });
                                      },
                                selectedColor: const Color(0xFF1B4332),
                                labelStyle: TextStyle(
                                  color:
                                      effectiveSelectedUecIds.contains(
                                        '$_operatorUecIdPrefix${widget.visitId}',
                                      )
                                      ? Colors.white
                                      : const Color(0xFF1B4332),
                                ),
                                backgroundColor: const Color(
                                  0xFF1B4332,
                                ).withValues(alpha: 0.05),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF1B4332,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                            ...allUecs.map((u) {
                              final isSelected = effectiveSelectedUecIds
                                  .contains(u.id);
                              final hasResponse = responses.any(
                                (r) => r.uecId == u.id,
                              );

                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  u.nAggregato.isNotEmpty
                                      ? '${u.coltura} (${u.nAggregato})'
                                      : u.coltura,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected:
                                    (widget.isReadOnly ||
                                        _sharedConf != Conformita.ko)
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
                            }),
                          ],
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
                          widget.item.gravitaOperatoreText.isNotEmpty ||
                          widget.item.code.trim() == '10.6' ||
                          widget.item.code.trim() == '11.1' ||
                          widget.item.code.trim() == '11.2' ||
                          widget.item.code.trim() == '11.3' ||
                          widget.item.code.trim() == '12.1' ||
                          widget.item.code.trim() == '12.2' ||
                          widget.item.code.trim() == '12.3' ||
                          widget.item.code.trim() == '13.1' ||
                          widget.item.code.trim() == '13.2' ||
                          widget.item.code.trim() == '14.0' ||
                          widget.item.code.trim() == '14.1' ||
                          widget.item.code.trim() == '14.2' ||
                          widget.item.code.trim() == '14.4' ||
                          widget.item.code.trim() == '15.1' ||
                          widget.item.code.trim() == '15.4' ||
                          widget.item.code.trim() == '15.5' ||
                          widget.item.code.trim() == '15.6' ||
                          widget.item.code.trim() == '15.7' ||
                          widget.item.code.trim() == '15.8' ||
                          widget.item.code.trim() == '15.9' ||
                          widget.item.code.trim() == '15.10' ||
                          widget.item.code.trim() == '15.11' ||
                          widget.item.code.trim() == '15.12' ||
                          widget.item.code.trim() == '15.13' ||
                          widget.item.code.trim() == '15.14' ||
                          widget.item.code.trim() == '15.15' ||
                          widget.item.code.trim() == '16.1' ||
                          widget.item.code.trim() == '16.2' ||
                          widget.item.code.trim() == '16.3' ||
                          widget.item.code.trim() == '16.4' ||
                          widget.item.code.trim() == '17.1' ||
                          widget.item.code.trim() == '17.2' ||
                          widget.item.code.trim() == '17.3' ||
                          widget.item.code.trim() == '17.4' ||
                          widget.item.code.trim() == '17.7' ||
                          widget.item.code.trim() == '17.8' ||
                          widget.item.code.trim() == '17.10') ...[
                        const SizedBox(height: 12),
                        _MetadataSection(item: widget.item),
                      ],
                      if (!isHeaderOnly &&
                          effectiveSelectedUecIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        if (_sharedConf != Conformita.ko) ...[
                          Builder(
                            builder: (context) {
                              final List<VisitUec> selectedUecs = [];
                              for (final uecId in effectiveSelectedUecIds) {
                                if (uecId.startsWith(_operatorUecIdPrefix)) {
                                  selectedUecs.add(
                                    VisitUec(
                                      id: uecId,
                                      visitId: widget.visitId,
                                      coltura: 'OPERATORE',
                                      descrizione:
                                          'Attribuito all\'intera Azienda/OA',
                                      nAggregato: '',
                                      sqnpiConsistency: '',
                                      sqnpiCompliance: '',
                                      isTraceable: false,
                                      hasClaims: false,
                                      isFieldProcessVerified: false,
                                      hasSampling: false,
                                      note: '',
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                } else {
                                  final u = allUecs
                                      .cast<VisitUec?>()
                                      .firstWhere(
                                        (u) => u?.id == uecId,
                                        orElse: () => null,
                                      );
                                  if (u != null) selectedUecs.add(u);
                                }
                              }

                              final response = responses
                                  .cast<ChecklistResponse?>()
                                  .firstWhere(
                                    (r) => effectiveSelectedUecIds.contains(
                                      r?.uecId,
                                    ),
                                    orElse: () => null,
                                  );

                              return _ChecklistOutcomeBlock(
                                key: ValueKey(
                                  'outcome_grouped_${widget.item.code}_${_sharedConf.index}',
                                ),
                                uecs: selectedUecs,
                                item: widget.item,
                                visitId: widget.visitId,
                                isReadOnly: widget.isReadOnly,
                                initialResponse: response,
                                conformita: _sharedConf,
                              );
                            },
                          ),
                        ] else ...[
                          ..._selectedUecIds.map((uecId) {
                            final VisitUec uec;
                            if (uecId.startsWith(_operatorUecIdPrefix)) {
                              uec = VisitUec(
                                id: uecId,
                                visitId: widget.visitId,
                                coltura: 'OPERATORE',
                                descrizione:
                                    'Attribuito all\'intera Azienda/OA',
                                nAggregato: '',
                                sqnpiConsistency: '',
                                sqnpiCompliance: '',
                                isTraceable: false,
                                hasClaims: false,
                                isFieldProcessVerified: false,
                                hasSampling: false,
                                note: '',
                                updatedAt: DateTime.now(),
                              );
                            } else {
                              uec = allUecs.firstWhere((u) => u.id == uecId);
                            }
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
                                  'outcome_${uecId}_${widget.item.code}_${_sharedConf.index}',
                                ),
                                uecs: [uec],
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
                                  child: _PersistentImage(
                                    filePath: att.filePath,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(4),
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
    this.items,
  });
  final String label;
  final int? value;
  final ValueChanged<int?>? onChanged;
  final List<DropdownMenuItem<int?>>? items;

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
          items:
              items ??
              const [
                DropdownMenuItem(value: null, child: Text('—')),
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
    const obblighiColors = (
      bg: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0),
      text: Color(0xFF047857),
    );
    const derogheColors = (
      bg: Color(0xFFEEF2FF),
      border: Color(0xFFC7D2FE),
      text: Color(0xFF4338CA),
    );
    const noteColors = (
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      text: Color(0xFFB45309),
    );
    const gravitaUecColors = (
      bg: Color(0xFFEFF6FF),
      border: Color(0xFFBFDBFE),
      text: Color(0xFF1D4ED8),
    );
    const gravitaOpColors = (
      bg: Color(0xFFFAF5FF),
      border: Color(0xFFE9D5FF),
      text: Color(0xFF7E22CE),
    );
    const freqSingoloColors = (
      bg: Color(0xFFF8FAFC),
      border: Color(0xFFE2E8F0),
      text: Color(0xFF334155),
    );
    const freqAssociatoColors = (
      bg: Color(0xFFF0FDFA),
      border: Color(0xFFCCFBF1),
      text: Color(0xFF0F766E),
    );
    const odcColors = (
      bg: Color(0xFFF0F9FF),
      border: Color(0xFFBAE6FD),
      text: Color(0xFF0369A1),
    );
    const sospensioneColors = (
      bg: Color(0xFFFFF1F2),
      border: Color(0xFFFECDD3),
      text: Color(0xFFBE123C),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.code.trim() == '0.6')
          _MetadataItem(
            label: 'Obblighi',
            content: 'Registrazioni di magazzino',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '0.8')
          _MetadataItem(
            label: 'Obblighi',
            content: 'Rispetto termini di presentazione della domanda',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '0.9')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Comunicazione eventuali variazioni, cessione particelle, cambio destinazione colture, **entro 30gg**',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '0.10' || item.displayCode == '0.11')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Garantire coerenza della consistenza aziendale e del piano colturale rispetto a quanto riportato nella domanda.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '0.12')
          _MetadataItem(
            label: 'Obblighi',
            content: "Pagamento dei corrispettivi dovuti all'OdC",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '0.13')
          _MetadataItem(
            label: 'Obblighi',
            content:
                "Pubblicizzare l'indirizzo dell'Osservatorio SQNPI e le modalità di segnalazione. Per gli OA mediante l'utilizzo del proprio sito web; per le aziende singole sito web o almeno un cartello presso il centro aziendale",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.1')
          _MetadataItem(
            label: 'Obblighi',
            content:
                "1. uso di soli prodotti, autorizzati\n2. rispetto delle prescrizioni di utilizzo previste nell’etichetta del prodotto impiegato, in particolare:\na. non superare la dose massima ettaro indicata per applicazione;\nb. su colture ammesse;\nc. sui terreni indicati (ove previsto);\nd. in corrispondenza delle fasi fenologiche indicate;\ne. contro le avversità previste;\nf. nel rispetto dei tempi di carenza;\ng. intervallo tra due trattamenti con il medesimo\nh. non superare la dose massima riferita a più annualità",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.2.1')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Utilizzo di formulati ammessi per lo specifico tipo di impiego nelle norme di coltura dei disciplinari (se rilevato dal registro trattamenti o durante l\'ispezione)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.2.2')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Utilizzo di formulati ammessi per lo specifico tipo di impiego nelle norme di coltura dei disciplinari (se rilevato con analisi multiresiduo)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.3')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto del numero di interventi previsti per sostanza o gruppi di sostanze attive',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.4')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto delle dosi e delle modalità di applicazione riportate nelle norme di coltura dei disciplinari',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.6')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto delle soglie di intervento e di altri criteri di intervento vincolanti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.7')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto del numero complessivo di interventi per singola avversità',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.8')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Installazione delle trappole e degli altri sistemi di monitoraggio vincolanti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.9')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto dei limiti dei **volumi di irrorazione** previsti dai DPI',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.10')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Controllo funzionale e regolazione strumentale macchine irroratrici anche per prestazione di contoterzisti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '1.11')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Verificare possesso certificato di abilitazione all’acquisto e all’utilizzo o prestazione di contoterzisti abilitati.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '2.1')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Le caratteristiche pedoclimatiche dell’area di coltivazione devono essere prese in considerazione in riferimento delle esigenze delle colture',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '2.2')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'La scelta dovrà essere particolarmente accurata in caso di nuova introduzione della coltura e/o varietà nell’ambiente di coltivazione',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '3.1')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Messa in pratica di tecniche ed interventi volti a rafforzare la biodiversità',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '3.2')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Divieto di utilizzare PF e concimi nelle aree naturali presenti in azienda (indicate in domanda) quali siepi, boschetti e filari alberati',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '4.2')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Varietà, ecotipi, “piante intere” e portinnesti devono essere scelti in funzione delle specifiche condizioni pedoclimatiche di coltivazione',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '4.3')
          _MetadataItem(
            label: 'Obblighi',
            content: 'Se il disciplinare indica liste varietali',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),

        if (item.code.trim() == '16.4' || item.displayCode.startsWith('16.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'L\'operatore deve dimostrare di aver separato in tutte le fasi il prodotto in maniera da escludere ogni possibile inquinamento con lotti di prodotto non gestiti in ambito SQNPI.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '16.3' || item.displayCode.startsWith('16.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'In caso di preparatori/ trasformatori verifica del bilancio di massa (entrata, resa, uscita, giacenza) e delle sua congruità.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '16.2' || item.displayCode.startsWith('16.2'))
          _MetadataItem(
            label: 'Obblighi',
            content: 'Completezza delle registrazioni',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.15' || item.displayCode.startsWith('15.15'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'predisporre un piano aziendale all’interno del quale prevedere le modalità e tempi di realizzazione degli impegni aziendali relativi a:\n• formazione a tutto il personale sul tema della sicurezza sul lavoro;\n• formazione sul tema della sostenibilità delle produzioni almeno al personale tecnico assunto a tempo indeterminato',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.14' || item.displayCode.startsWith('15.14'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'effettuare la valutazione dei rischi tramite:\n• Adozione del documento sulla valutazione dei rischi sul posto di lavoro (DVR)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.13' || item.displayCode.startsWith('15.13'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'iscriversi alla rete del lavoro agricolo di qualità istituito presso l’INPS oppure\n• dimostrare di essere in regola con il versamento dei contributi (ovvero esibire copia del DURC in corso di validità)\n• dimostrare di non aver riportato condanne amministrative o penali per violazioni della normativa in materia di lavoro e legislazione sociale (riscontrabile dal certificato del casellario giudiziale);',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.12' || item.displayCode.startsWith('15.12'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'redigere un elenco aggiornato dei lavoratori impiegati, ivi compresi i parasubordinati, con indicazione del tipo di contratto applicato, della provenienza del lavoratore, genere, età, durata del rapporto di lavoro.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.11' || item.displayCode.startsWith('15.11'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'predisporre un piano triennale di intervento che miri ad adottare i contenitori piu\' idonei, a ridurre gli imballaggi e a favorire la scelta di quelli riutilizzabili o prodotti con materiale riciclato',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.10' || item.displayCode.startsWith('15.10'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'monitorare il consumo di energia e predisporre un piano triennale di miglioramento della gestione delle risorse energetiche con interventi finalizzati alla riduzione del consumo e alla produzione di energia da fonti rinnovabili. In alternativa deve far ricorso a forniture di energia prodotta da fonti rinnovabili certificate',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.9' || item.displayCode.startsWith('15.9'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'predisporre un piano triennale di miglioramento della gestione della risorsa idrica che prevede interventi per la riduzione del consumo ed il recupero delle acque reflue e di quelle meteoriche da trattare e destinare ad esempio a: • Pulizia aree interne e piazzali; • Irrigazione aree verdi adiacenti alle strutture interessate; • Scarichi di servizi igienici. Il piano triennale è sottoposto a riesame annuale.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.8' || item.displayCode.startsWith('15.8'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'registrare il consumo di acqua dolce prelevata da corpo idrico superficiale o di falda ed utilizzata nell’impianto di trasformazione e/o condizionamento;',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.7' || item.displayCode.startsWith('15.7'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'monitorare e gestire gli scarti ed i sottoprodotti della lavorazione: • registrare gli scarti e i sottoprodotti (quantità e tipologia) • predisporre un piano triennale di miglioramento della gestione per la riduzione dei quantitativi prodotti e/o per un minor impatto ambientale degli stessi; • effettuare un riesame annuale del piano',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.6' || item.displayCode.startsWith('15.6'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'monitorare e gestire la produzione dei reflui dell’impianto di trasformazione e/o conservazione e/o condizionamento: • registrare i reflui (quantità e tipologia) • predisporre un piano triennale di miglioramento della gestione per la riduzione dei quantitativi prodotti e/o per un minor impatto ambientale degli stessi; • effettuare un riesame annuale del piano',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.5' || item.displayCode.startsWith('15.5'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto del requisito minimo di qualità del prodotto trasformato riportato al punto 10.3.7 della Norma.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.4' || item.displayCode.startsWith('15.4'))
          _MetadataItem(
            label: 'Obblighi',
            content: 'Rispetto dei requisiti igienico sanitari RMA',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.3' || item.displayCode.startsWith('15.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto dei requisiti minimi di qualità intrinseca. Conformità.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.2' || item.displayCode.startsWith('15.2'))
          _MetadataItem(
            label: 'Obblighi',
            content: 'Rispetto norme di commercializzazione CE',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '15.1' ||
            (item.displayCode.startsWith('15.1') &&
                !item.displayCode.startsWith('15.10') &&
                !item.displayCode.startsWith('15.11') &&
                !item.displayCode.startsWith('15.12') &&
                !item.displayCode.startsWith('15.13') &&
                !item.displayCode.startsWith('15.14') &&
                !item.displayCode.startsWith('15.15')))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'rispetto normativa di settore post raccolta (normativa cogente) trattamenti non consentiti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '14.4' || item.displayCode.startsWith('14.4'))
          _MetadataItem(
            label: 'Obblighi',
            content: 'Adeguata gestione delle NC da parte dell\'OA',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '14.2' || item.displayCode.startsWith('14.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Esclusione unità elementari di coltivazione UEC non conformi in base a esito analisi in autocontrollo eseguite direttamente dall\'OA',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '14.1' || item.displayCode.startsWith('14.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Eseguire analisi multiresiduali in autocontrollo: ■ 25% - fino a 1000 aziende aderenti; ■ √n - per la quota eccedente le prime 1000 aziende aderenti.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '14.0' || item.displayCode.startsWith('14.0'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Verifica documentale in autocontrollo sul 100% delle aziende aderenti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '13.2' || item.displayCode.startsWith('13.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Se disciplinati dalla Regione o P.A. verificare il rispetto delle modalità di raccolta e conferimento ai centri di stoccaggio / lavorazione',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '13.1' || item.displayCode.startsWith('13.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Se disciplinati dalla Regione o P.A. verificare il rispetto dei parametri per inizio raccolta',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '12.3' || item.displayCode.startsWith('12.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Altri obblighi specifici colturali tra cui quelli disposti per funghi (es. obblighi previsti per la gestione/coltivazione/raccolta fungaia)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '12.2' || item.displayCode.startsWith('12.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Riscaldamento colture protette:** utilizzare sistemi di riscaldamento che impiegano fonti rinnovabili (geotermia, energia solare, cogenerazione e reti di teleriscaldamento ed eolico). Sono ammessi i combustibili di origine vegetale (tra cui ad esempio pigne, pinoli, altri scarti di lavorazione del legno) e tutti i combustibili a basso impatto ambientale. Sono temporaneamente ammessi i combustibili fossili.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '12.1' || item.displayCode.startsWith('12.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Colture fuori suolo:** ammesse solo se non a ciclo aperto completa riciclabilità dei substrati e riutilizzazione agronomica delle acque reflue',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '11.3' || item.displayCode.startsWith('11.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Dati relativi alla qualità delle acque e alle caratteristiche delle sorgenti e delle modalità di attingimento (se richiesti dai DPI regionali).',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '11.1' || item.displayCode.startsWith('11.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'obbligo di rispettare il volume massimo di adacquamento stagionale e per intervento irriguo definiti nei disciplinari di produzione integrata',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.6' || item.displayCode.startsWith('10.6'))
          _MetadataItem(
            label: 'Obblighi',
            content: item.obbligo,
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '11.2' || item.displayCode.startsWith('11.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Non ricorrere all\'irrigazione per scorrimento fatti salvi i casi previsti al capitolo 14 delle LGNTA.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.5.2' ||
            item.displayCode.startsWith('10.5.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Esecuzione di analisi del suolo** (effettuazione di un\'analisi almeno per ciascuna area omogenea dal punto di vista pedologico ed agronomico) **prima della stesura del piano di fertilizzazione o utilizzo delle schede a dose standard**\n\n **colture arboree all\'impianto** o, nel caso di impianti già in essere, **all\'inizio del periodo di adesione alla produzione integrata**',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.5.1' ||
            item.displayCode.startsWith('10.5.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Esecuzione di analisi del suolo** (effettuazione di un\'analisi almeno per ciascuna area omogenea dal punto di vista pedologico ed agronomico) **prima della stesura del piano di fertilizzazione o utilizzo delle schede a dose standard**\n\n **colture erbacee almeno ogni 5 anni**',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.4' || item.displayCode.startsWith('10.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto delle norme di frazionamento e di epoca di distribuzione',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.3' || item.displayCode.startsWith('10.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Nelle zone vulnerabili ai nitrati:** obbligatorio anche il rispetto dei quantitativi max annui stabiliti in applicazione della Direttiva 91/676/CEE',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.2' || item.displayCode.startsWith('10.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto dei massimali stabiliti con piano fertilizzazione o scheda dose standard.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '10.1' || item.displayCode.startsWith('10.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Stesura del piano di fertilizzazione aziendale, per la determinazione dei quantitativi max dei macro elementi nutritivi distribuibili annualmente per coltura o per ciclo colturale o in alternativa adozione del metodo della "dose standard".',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '9.2' || item.displayCode.startsWith('9.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                "**Colture arboree:** obblighi relativi a gestione dell'albero e fruttificazione",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '8.4' || item.displayCode.startsWith('8.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Rispetto ulteriori disposizioni relative alla gestione del suolo e pratiche agronomiche per il controllo delle infestanti',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '8.3' || item.displayCode.startsWith('8.3'))
          Column(
            children: [
              _MetadataItem(
                label: 'Obblighi',
                content:
                    '<u>**Colture arboree negli appezzamenti con pendenza media < 10%:**</u> è obbligatorio l’inerbimento dell’interfila nel periodo autunno-invernale. Le operazioni di semina ed inerramento del sovescio sono consentite',
                icon: Icons.assignment_outlined,
                backgroundColor: obblighiColors.bg,
                borderColor: obblighiColors.border,
                iconColor: obblighiColors.text,
              ),
              _MetadataItem(
                label: 'Deroghe',
                content:
                    "L'impegno dell'inerbimento non si applica nei primi 2 anni di impianto della coltura arborea. Dove vige il vincolo dell'inerbimento nell'interfila sono ammessi quegli interventi localizzati di interramento dei concimi sulla fila, individuati dalle regioni e province autonome come i meno impattanti.",
                icon: Icons.assignment_outlined,
                backgroundColor: derogheColors.bg,
                borderColor: derogheColors.border,
                iconColor: derogheColors.text,
              ),
            ],
          ),
        if (item.code.trim() == '8.2.6' || item.displayCode.startsWith('8.2.6'))
          Column(
            children: [
              _MetadataItem(
                label: 'Obblighi',
                content:
                    '<u>**Negli appezzamenti con pendenza media compresa tra il 10% e il 30%:**</u>\n\n**Colture arboree:** obbligatorio l’inerbimento nell’interfila (anche come vegetazione spontanea gestita con sfalci). Le operazioni di semina ed interramento del sovescio sono ammissibili ma il sovescio andrà eseguito a filari alterni. Nei primi due anni di impianto della coltura l\'impegno dell\'inerbimento si puo\' applicare anche a filari alterni.',
                icon: Icons.assignment_outlined,
                backgroundColor: obblighiColors.bg,
                borderColor: obblighiColors.border,
                iconColor: obblighiColors.text,
              ),
              _MetadataItem(
                label: 'Deroghe',
                content:
                    'In areali contraddistinti da scarsa piovosità nel periodo vegetativo, su terreni a tessitura argillosa, argillosa-limosa, argillosa-sabbiosa, franco-limosa-argillosa, franco-argillosa e franco-sabbiosa-argillosa (classificazione USDA) il vincolo non si applica. In tal caso nel periodo primaverile-estivo, in alternativa all\'inerbimento, sono consentite lavorazioni a filari alterni con lo scopo di arieggiare/decompattare il terreno fino ad un massimo di 30 cm di profondità.',
                icon: Icons.assignment_outlined,
                backgroundColor: derogheColors.bg,
                borderColor: derogheColors.border,
                iconColor: derogheColors.text,
              ),
            ],
          ),
        if (item.code.trim() == '8.2.5' || item.displayCode.startsWith('8.2.5'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                "<u>**Negli appezzamenti con pendenza media compresa tra il 10% e il 30%:**</u>\n\nIn alternativa al punto del PCN 8.2.4, in situazioni geo-pedologiche particolari e di frammentazione fondiaria, prevedere sistemi alternativi di protezione del suolo dall'erosione",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '8.2.4' || item.displayCode.startsWith('8.2.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '<u>**Negli appezzamenti con pendenza media compresa tra il 10% e il 30%:**</u>\n\n **Colture erbacee:** obbligatoria la realizzazione di solchi acquai temporanei al max ogni 60 m (oppure vedere alternativa al punto del PCN 8.2.5)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '8.2.3' || item.displayCode.startsWith('8.2.3'))
          Column(
            children: [
              _MetadataItem(
                label: 'Obblighi',
                content:
                    '<u>**Negli appezzamenti con pendenza media compresa tra il 10% e il 30%:**</u>\n\nconsentite lavorazioni ad una profondità max di 30 cm',
                icon: Icons.assignment_outlined,
                backgroundColor: obblighiColors.bg,
                borderColor: obblighiColors.border,
                iconColor: obblighiColors.text,
              ),
              _MetadataItem(
                label: 'Deroghe',
                content:
                    'Eccezione per la ripuntatura per la quale è ammessa una profondità massima di 50 cm',
                icon: Icons.assignment_outlined,
                backgroundColor: derogheColors.bg,
                borderColor: derogheColors.border,
                iconColor: derogheColors.text,
              ),
            ],
          ),
        if (item.code.trim() == '8.1.2' || item.displayCode.startsWith('8.1.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                "<u>**Negli appezzamenti con pendenza media superiore al 30%:**</u>\n\n **colture arboree:** è obbligatorio l'inerbimento nell'interfila anche come vegetazione spontanea gestita con sfalci. All’impianto sono ammesse solo le lavorazioni puntuali (lavorazioni utili per la sola messa a dimora delle piante) o altre finalizzate alla sola asportazione dei residui dell’impianto arboreo precedente. Nei primi due anni di impianto della coltura l’impegno dell’inerbimento si puo' applicare anche a filari alterni",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '8.1.1' || item.displayCode.startsWith('8.1.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                '<u>**Negli appezzamenti con pendenza media superiore al 30%:**</u>\n\n **colture erbacee:** sono consentite solo tecniche di minima lavorazione, la semina su sodo e la scarificatura/ripuntatura',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '7.1' || item.displayCode.startsWith('7.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Colture annuali e perenni: Rispettare le densità di semina e impianto laddove posti dei vincoli nei DPI',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '6.4' || item.displayCode.startsWith('6.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Ulteriori norme specifiche per reimpianto di **colture arboree**:',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '6.3' || item.displayCode.startsWith('6.3'))
          _MetadataItem(
            label: 'Obblighi',
            content: 'Ulteriori limitazioni negli avvicendamenti colturali',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '6.2' || item.displayCode.startsWith('6.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                "coinvolgimento superfici aziendali dedicate a specifiche colture :devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '6.1' || item.displayCode.startsWith('6.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                "coinvolgimento intera superficie aziendale o parte di essa: devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)",
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '5.4' || item.displayCode.startsWith('5.4'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'I lavori devono contribuire a mantenere la struttura, favorendo un’elevata biodiversità della microflora e della microfauna del suolo ed una riduzione dei fenomeni di compattamento, consentendo l’allontanamento delle acque meteoriche in eccesso',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '5.3' || item.displayCode.startsWith('5.3'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'I lavori vanno definiti in funzione della tipologia del suolo, delle colture interessate, della giacitura, dei rischi di erosione e delle condizioni climatiche',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '5.2' || item.displayCode.startsWith('5.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'I lavori di sistemazione e preparazione del suolo all’impianto e alla semina devono essere eseguiti con gli obiettivi di salvaguardare e migliorare la fertilità del suolo evitando fenomeni erosivi e di degrado',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '5.1' || item.displayCode.startsWith('5.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Gli eventuali interventi di correzione e di fertilizzazione di fondo devono essere eseguiti nel rispetto dei principi stabiliti al capitolo della fertilizzazione',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '4.6' || item.displayCode.startsWith('4.6'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'L’autoproduzione del materiale di propagazione è vietata ad eccezione dei casi previsti al punto 5 delle LGNTA',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          )
        else if (item.code.trim().contains('4.5.2') ||
            item.displayCode.startsWith('4.5.2'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Il materiale di propagazione deve essere sano e garantito dal punto di vista genetico e deve essere in grado di offrire garanzie fitosanitarie e di qualità agronomica.\n <u>**colture arboree:**</u> se disponibile, si deve ricorrere a materiale di categoria “certificato”. In assenza dovrà essere impiegato materiale di categoria CAC oppure materiale prodotto secondo norme tecniche più restrittive definite a livello regionale',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          )
        else if (item.code.trim().contains('4.5.1') ||
            item.displayCode.startsWith('4.5.1'))
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Il materiale di propagazione deve essere sano e garantito dal punto di vista genetico e deve essere in grado di offrire garanzie fitosanitarie e di qualità agronomica.\n\n<u>**colture ortive:**</u> si deve ricorrere a materiale di categoria “Qualità CE” per le piantine e categoria certificata CE per le sementi. <u>**Colture erbacee:**</u> si deve ricorrere a semente certificata',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '16.1' || item.displayCode == '16.1')
          _MetadataItem(
            label: 'Obblighi',
            content:
                '**Archiviazione documentazione a supporto delle registrazioni sul SI SQNPI atte a garantire la rintracciabilità dei lotti** (estremi documenti fiscali e non, di evidenza oggettiva, data e quantitativo venduto, identificativo del lotto o dell\'unità elementare, vendita con relativa quantità **ed anagrafica acquirente**)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.1' || item.code.trim() == '17.2')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Garantire che il prodotto contrassegnato dal marchio provenga da lotti certificati',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.3' || item.code.trim() == '17.4')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Riproduzione fedele del logo in conformità a quello ufficiale (riportato al punto 17.8)',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.6')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Presenza di lotti certificati nell\'anno corrente e/o nell\'annualità precedente per l\'utilizzo del marchio su documenti relativi ad aziende in regime SQNPI',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.7' || item.code.trim() == '17.8')
          _MetadataItem(
            label: 'Obblighi',
            content: 'Rispetto del regolamento d\'uso del marchio',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.9')
          _MetadataItem(
            label: 'Obblighi',
            content:
                'Pubblicizzare l’indirizzo dell’Osservatorio SQNPI e le modalità di segnalazione. Per gli OA mediante l’utilizzo del proprio sito web; per le aziende singole sito web o almeno un cartello presso il centro aziendale.',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.code.trim() == '17.10')
          _MetadataItem(
            label: 'Obblighi',
            content: 'Pagamento dei corrispettivi dovuti all\'OdC',
            icon: Icons.assignment_outlined,
            backgroundColor: obblighiColors.bg,
            borderColor: obblighiColors.border,
            iconColor: obblighiColors.text,
          ),
        if (item.noteNorma.isNotEmpty ||
            item.code.trim() == '13.1' ||
            item.code.trim() == '13.2')
          _MetadataItem(
            label: 'Note',
            content: item.code.trim() == '13.1'
                ? 'Scheda di raccolta con registrazione parametri previsti dal DPI. Estrazione a campione delle schede da verificare in funzione delle colture praticate. Verifica analitica in campo in caso di visita in fase di raccolta. **Per le aziende oggetto di verifica: almeno 2 schede di cui una del prodotto più rappresentativo in termini di superficie**'
                : item.code.trim() == '13.2'
                ? 'Descrizione delle modalità di raccolta e conferimento in manuale di autocontrollo o altro documento. Verifica in sede di visita ispettiva. Verifica visiva del prodotto al centro di stoccaggio ove possibile.'
                : (item.code.trim() == '0.1' &&
                      item.noteNorma.startsWith(
                        'Registrazione trattamenti fitosanitari',
                      ))
                ? item.noteNorma.replaceFirst(
                    'Registrazione trattamenti fitosanitari',
                    '**Registrazione trattamenti fitosanitari**',
                  )
                : (item.code.trim() == '0.2' &&
                      item.noteNorma.startsWith(
                        'Registrazione fertilizzazione',
                      ))
                ? item.noteNorma.replaceFirst(
                    'Registrazione fertilizzazione',
                    '**Registrazione fertilizzazione**',
                  )
                : (item.code.trim() == '0.3')
                ? item.noteNorma.replaceFirstMapped(
                    RegExp(
                      r'(Registrazione irrigazione.*?disciplinari)',
                      caseSensitive: false,
                    ),
                    (match) => '**${match.group(1)}**',
                  )
                : (item.code.trim() == '0.4')
                ? '${item.noteNorma.replaceFirst(RegExp(r'Registrazione operazioni colturali', caseSensitive: false), '**Registrazione operazioni colturali**')}\n\nLa verifica delle registrazioni sul registro aziendale SQNPI elettronico, entro i termini stabiliti dalla norma, si intende soddisfatta anche a fronte di evidenze desumibili da registri cartacei o e-mail.Il ritardo o la registrazione incompleta/imprecisa si riferiscono ad uno o piu\'interventi. Per il materiale di moltiplicazione le verifiche in merito al requisito di eventuali certificazioni  previste dalla norma, riscontrano la presenza degli  appositi cartellini o certificati.'
                : (item.code.trim() == '0.10' || item.code.trim() == '0.11')
                ? "Eventuali incongruenze vanno gestite mediante AC finalizzate ad aggiornare la domanda. Nel caso in cui la formalizzazione dell'A.C possa compromettere la tempistica per il rilascio della certificazione o conformità ACA, l'ODC procede con l'allocazione delle parcelle interessate in uno o più aggregati- UEC aggiuntivi e l'attribuzione della relativa N.C. ** Nel caso di piano colturale difforme si sottolinea l’importanza di accertare la natura avvicendante o intercalare della coltura, da gestire come riportato al punto 5 della Norma.**"
                : (item.code.trim() == '0.13')
                ? '  La relativa non conformità viene attribuita nella seguente maniera:\n- operatore interessato alla fase di campo : si attribuisce il valore correlato alla fase di campo\n- operatore post raccolta: si attribuisce il valore correlato alla fase di raccolta/ post raccolta\n- operatore interessato a tutte le fasi del processo, di campo e di raccolta/post raccolta: si attribuisce il valore correlato alla fase di post raccolta\n(Vedere anche punto 17.9 del PCN)'
                : (item.code.trim() == '15.3')
                ? 'Verifica analisi'
                : item.noteNorma,
            icon: Icons.info_outline,
            backgroundColor: noteColors.bg,
            borderColor: noteColors.border,
            iconColor: noteColors.text,
          ),
        if (item.code.trim() == '16.2' || item.displayCode.startsWith('16.2'))
          Column(
            children: [
              _MetadataItem(
                label: 'ESCL../SOSP... UEC/LOTTO',
                content:
                    'Regola generale post raccolta (capitolo 8.3.3 ):\n\nSe il numero di lotti non conformi è ≤ 10% del campione si procede con l\'esclusione del/dei lotto/i non conformi;\n\nSe il numero di lotti non conformi è >10% fino al 25% si procede con l\'esclusione del/dei lotto/i non conformi e con un rafforzamento del controllo dell\'azienda o della OA da ripetere entro 6 mesi dall\'ultima verifica (in questo caso qualora dalla verifica non emergano non conformità l\'ODC può valutare se farla valere anche per la verifica annuale prevista).',
                icon: Icons.calendar_today_outlined,
                backgroundColor: sospensioneColors.bg,
                borderColor: sospensioneColors.border,
                iconColor: sospensioneColors.text,
              ),
              _MetadataItem(
                label: 'ESCL../SOSP... OPERATORE',
                content:
                    'Regola generale post raccolta (capitolo 8.3.3 ):\n\nL’operatore singolo o l’OA vengono sospesi dal SQNPI se si verifica almeno una delle seguenti condizioni:\n\n- la sommatoria delle NC attribuite all’operatore supera i 9 punti\n\n- il numero di lotti del campione non conformi è superiore al 25%\n\nIn caso di recidiva nell’arco di 3 anni delle elencate fattispecie di sospensione si ha l’esclusione dell’operatore dal SQNPI',
                icon: Icons.calendar_today_outlined,
                backgroundColor: sospensioneColors.bg,
                borderColor: sospensioneColors.border,
                iconColor: sospensioneColors.text,
              ),
            ],
          ),
        if (item.code.trim() == '14.0' ||
            item.displayCode.startsWith('14.0') ||
            item.code.trim() == '14.1' ||
            item.displayCode.startsWith('14.1') ||
            item.code.trim() == '14.2' ||
            item.displayCode.startsWith('14.2') ||
            item.code.trim() == '14.4' ||
            item.displayCode.startsWith('14.4'))
          _MetadataItem(
            label: 'ESCL../SOSP..',
            content: "Sì (da attribuire all'OA)",
            icon: Icons.calendar_today_outlined,
            backgroundColor: sospensioneColors.bg,
            borderColor: sospensioneColors.border,
            iconColor: sospensioneColors.text,
          ),
        if (item.code.trim() == '17.10' || item.code.trim() == '0.12')
          _MetadataItem(
            label: 'ESCL../SOSP..',
            content: 'Sospensione',
            icon: Icons.calendar_today_outlined,
            backgroundColor: sospensioneColors.bg,
            borderColor: sospensioneColors.border,
            iconColor: sospensioneColors.text,
          ),
        if (item.code.trim() == '0.2')
          _MetadataItem(
            label: 'ESCL../SOSP..',
            content:
                "'SI' (esclusione lotto) in caso di assenza completa delle registrazioni",
            icon: Icons.calendar_today_outlined,
            backgroundColor: sospensioneColors.bg,
            borderColor: sospensioneColors.border,
            iconColor: sospensioneColors.text,
          ),
        if (item.code.trim() == '0.8')
          _MetadataItem(
            label: 'ESCL../SOSP..',
            content:
                'Sospensione operatore ai fini della certificazione (marchio) - Sospensione operatore ai fini della conformità ACA (per ACA relativa alla SRA01 solo nel caso di domanda di adesione - primo anno di impegno).',
            icon: Icons.calendar_today_outlined,
            backgroundColor: sospensioneColors.bg,
            borderColor: sospensioneColors.border,
            iconColor: sospensioneColors.text,
          ),
        if (item.tipologiaControllo.isNotEmpty)
          _MetadataItem(
            label: 'Gravità NC (UEC/Lotto)',
            content: (item.code.trim() == '13.1' || item.code.trim() == '13.2')
                ? '2'
                : (item.code.trim() == '6.2' ||
                      item.displayCode.startsWith('6.2'))
                ? "1 se è nell'intervallo 3% -10% della SAU aziendale dedicata alla specifica coltura sulla quale non vengono rispettate le norme ; 2 se nell'intervallo 10%-30%; 3 se > 30%."
                : item.tipologiaControllo,
            icon: Icons.warning_amber_rounded,
            backgroundColor: gravitaUecColors.bg,
            borderColor: gravitaUecColors.border,
            iconColor: gravitaUecColors.text,
            isGravity: true,
          ),
        if (item.frequenzaAssociato.isNotEmpty)
          _MetadataItem(
            label: 'Gravità NC (Operatore)',
            content: item.frequenzaAssociato,
            icon: Icons.warning_amber_rounded,
            backgroundColor: gravitaOpColors.bg,
            borderColor: gravitaOpColors.border,
            iconColor: gravitaOpColors.text,
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
        if (item.frequenzaSingolo.isNotEmpty &&
            item.code.trim() != '16.2' &&
            !item.displayCode.startsWith('16.2'))
          _MetadataItem(
            label: 'ESCL../SOSP..',
            content:
                ({
                      '16.1',
                      '16.3',
                      '16.4',
                      '17.2',
                      '17.4',
                      '17.8',
                    }.contains(item.code.trim()) ||
                    {
                      '16.1',
                      '16.3',
                      '16.4',
                      '17.2',
                      '17.4',
                      '17.8',
                    }.contains(item.displayCode))
                ? 'Regola generale post raccolta (capitolo 8.3.3 ): \nSe il numero di lotti non conformi è ≤ 10% del campione si procede con l\'esclusione del/dei lotto/i non conformi; \n\nSe il numero di lotti non conformi è >10% fino al 25% si procede con l\'esclusione del/dei lotto/i non conformi e con un rafforzamento del controllo dell\'azienda o della OA da ripetere entro 6 mesi dall\'ultima verifica (in questo caso qualora dalla verifica non emergano non conformità l\'ODC può valutare se farla valere anche per la verifica annuale prevista).'
                : item.frequenzaSingolo,
            icon: Icons.calendar_today_outlined,
            backgroundColor: sospensioneColors.bg,
            borderColor: sospensioneColors.border,
            iconColor: sospensioneColors.text,
          ),
        if (item.code.trim() != '0.12' &&
            item.code.trim() != '0.13' &&
            item.code.trim() != '10.4' &&
            !item.displayCode.startsWith('10.4') &&
            !item.displayCode.startsWith('14.0') &&
            item.code.trim() != '14.1' &&
            !item.displayCode.startsWith('14.1') &&
            item.code.trim() != '14.2' &&
            !item.displayCode.startsWith('14.2') &&
            item.code.trim() != '14.4' &&
            !item.displayCode.startsWith('14.4') &&
            item.code.trim() != '17.10' &&
            item.code.trim() != '0.8' &&
            item.code.trim() != '0.9' &&
            item.code.trim() != '0.10' &&
            item.code.trim() != '0.11' &&
            item.code.trim() != '10.6' &&
            !item.displayCode.startsWith('10.6'))
          _MetadataItem(
            label: 'Frequenza Operatore Singolo',
            content:
                (item.code.trim() == '16.2' ||
                    item.displayCode.startsWith('16.2') ||
                    item.code.trim() == '16.3' ||
                    item.displayCode.startsWith('16.3') ||
                    {
                      '17.1',
                      '17.2',
                      '17.3',
                      '17.4',
                      '17.7',
                      '17.8',
                    }.contains(item.code.trim()))
                ? ' 100% operatori (verifica lotti in stoccaggio, da 1 a 10 lotti n. 1 lotto da verificare, da 11 a 50 n. 2 lotti da verificare, da 51 a 100 n. 3 lotti da verificare, da 101 a 500 n. 4 lotti, da 501 a 5000 n. 5 lotti da verificare, da 5001 a 50000 n. 6 lotti, oltre 50000 n. 7 lotti)'
                : '100%',
            icon: Icons.repeat_one_outlined,
            backgroundColor: freqSingoloColors.bg,
            borderColor: freqSingoloColors.border,
            iconColor: freqSingoloColors.text,
          ),
        if (item.code.trim() != '0.12' &&
            item.code.trim() != '0.13' &&
            item.code.trim() != '10.4' &&
            !item.displayCode.startsWith('10.4') &&
            item.code.trim() != '14.0' &&
            !item.displayCode.startsWith('14.0') &&
            item.code.trim() != '16.2' &&
            !item.displayCode.startsWith('16.2') &&
            item.code.trim() != '16.3' &&
            !item.displayCode.startsWith('16.3') &&
            item.code.trim() != '10.6' &&
            !item.displayCode.startsWith('10.6') &&
            item.code.trim() != '17.10')
          _MetadataItem(
            label: 'Frequenza Operatore associato',
            content:
                (item.code.trim() == '0.8' ||
                    item.code.trim() == '0.9' ||
                    item.code.trim() == '14.2')
                ? '100%'
                : ({
                    '17.1',
                    '17.2',
                    '17.3',
                    '17.4',
                    '17.7',
                    '17.8',
                  }.contains(item.code.trim()))
                ? '100% operatori del campione (verifica lotti in stoccaggio, da 1 a 10 lotti n. 1 lotto da verificare, da 11 a 50 n. 2 lotti da verificare, da 51 a 100 n. 3 lotti da verificare, da 101 a 500 n. 4 lotti, da 501 a 5000 n. 5 lotti da verificare, da 5001 a 50000 n. 6 lotti, oltre 50000 n. 7 lotti)'
                : '√n',
            icon: Icons.groups_outlined,
            backgroundColor: freqAssociatoColors.bg,
            borderColor: freqAssociatoColors.border,
            iconColor: freqAssociatoColors.text,
          ),

        if (item.code.trim() == '0.1' ||
            item.code.trim() == '0.2' ||
            item.code.trim() == '0.3' ||
            item.code.trim() == '0.4' ||
            item.code.trim() == '0.5' ||
            item.code.trim() == '0.6' ||
            item.code.trim() == '0.8' ||
            item.code.trim() == '0.9' ||
            item.code.trim() == '0.10' ||
            item.code.trim() == '0.11' ||
            item.code.trim() == '0.12' ||
            item.code.trim() == '0.13' ||
            item.code.trim() == '1.1' ||
            item.code.trim() == '1.2.1' ||
            item.code.trim() == '1.2.2' ||
            item.code.trim() == '1.3' ||
            item.code.trim() == '1.4' ||
            item.code.trim() == '1.6' ||
            item.code.trim() == '1.7' ||
            item.code.trim() == '1.8' ||
            item.code.trim() == '1.9' ||
            item.code.trim() == '1.10' ||
            item.code.trim() == '1.11' ||
            item.code.trim() == '3.1' ||
            item.code.trim() == '3.2' ||
            item.code.trim() == '4.2' ||
            item.code.trim() == '4.3' ||
            item.displayCode.startsWith('4.5.1') ||
            item.displayCode.startsWith('4.5.2') ||
            item.displayCode.startsWith('4.6') ||
            item.displayCode.startsWith('5.1') ||
            item.displayCode.startsWith('5.2') ||
            item.displayCode.startsWith('5.3') ||
            item.displayCode.startsWith('5.4') ||
            item.displayCode.startsWith('6.1') ||
            item.displayCode.startsWith('6.2') ||
            item.displayCode.startsWith('6.3') ||
            item.displayCode.startsWith('6.4') ||
            item.displayCode.startsWith('7.1') ||
            item.displayCode.startsWith('8.1.1') ||
            item.displayCode.startsWith('8.1.2') ||
            item.displayCode.startsWith('8.2.3') ||
            item.displayCode.startsWith('8.2.4') ||
            item.displayCode.startsWith('8.2.5') ||
            item.displayCode.startsWith('8.2.6') ||
            item.displayCode.startsWith('8.3') ||
            item.displayCode.startsWith('8.4') ||
            item.displayCode.startsWith('9.2') ||
            item.displayCode.startsWith('10.1') ||
            item.displayCode.startsWith('10.2') ||
            item.displayCode.startsWith('10.3') ||
            item.displayCode.startsWith('10.4') ||
            item.displayCode.startsWith('10.5.1') ||
            item.displayCode.startsWith('10.5.2') ||
            item.displayCode.startsWith('11.1') ||
            item.displayCode.startsWith('11.2') ||
            item.displayCode.startsWith('11.3') ||
            item.displayCode.startsWith('12.1') ||
            item.displayCode.startsWith('12.2') ||
            item.displayCode.startsWith('12.3') ||
            item.displayCode.startsWith('13.1') ||
            item.displayCode.startsWith('13.2') ||
            item.displayCode.startsWith('14.0') ||
            item.displayCode.startsWith('14.1') ||
            item.displayCode.startsWith('14.2') ||
            item.displayCode.startsWith('14.4') ||
            item.displayCode.startsWith('15.1') ||
            item.displayCode.startsWith('15.4') ||
            item.displayCode.startsWith('15.5') ||
            item.displayCode.startsWith('15.6') ||
            item.displayCode.startsWith('15.7') ||
            item.displayCode.startsWith('15.8') ||
            item.displayCode.startsWith('15.9') ||
            item.displayCode.startsWith('15.10') ||
            item.displayCode.startsWith('15.11') ||
            item.displayCode.startsWith('15.12') ||
            item.displayCode.startsWith('15.13') ||
            item.displayCode.startsWith('15.14') ||
            item.displayCode.startsWith('15.15') ||
            item.displayCode.startsWith('16.1') ||
            item.displayCode.startsWith('16.2') ||
            item.displayCode.startsWith('16.3') ||
            item.displayCode.startsWith('16.4') ||
            item.displayCode.startsWith('17.1') ||
            item.displayCode.startsWith('17.2') ||
            item.displayCode.startsWith('17.3') ||
            item.displayCode.startsWith('17.4') ||
            item.displayCode.startsWith('17.7') ||
            item.displayCode.startsWith('17.8') ||
            item.displayCode.startsWith('17.10'))
          _MetadataItem(
            label: 'Indicazioni OdC',
            content: item.code.trim() == '0.3'
                ? 'verificare presenza delle registrazioni e riportare ultima fertilizzazione registrata'
                : item.code.trim() == '0.4'
                ? 'verificare presenza delle registrazioni e riportare ultima operazione colturale registrata'
                : item.code.trim() == '0.5'
                ? 'verificare presenza e corretta conservazione'
                : item.code.trim() == '0.6'
                ? 'verificare presenza delle registrazioni e riportare ultima registrazione di magazzino effettuata'
                : item.code.trim() == '0.8'
                ? "Sono ammessi ritardi solo per problemi tecnici indipendenti dalla volonta' del richiedente  (cap.5)"
                : item.code.trim() == '0.9'
                ? 'verificare eventuali variazioni intervenute dopo il rilascio della domanda di adesione (cessione/inserimento terreni, modifiche dei processi…)'
                : item.code.trim() == '0.10'
                ? 'per le colture Avvicendate non è NC ma serve aggiornamento del fascicolo aziendale e raccolta evidenza.'
                : item.code.trim() == '0.11'
                ? "verificare se in domanda di adesione sono presenti terreni non condotti dall'azienda o con colture non riscontrate in azienda."
                : item.code.trim() == '0.12'
                ? 'verificare in Biosfera pagamento quote anni precedenti o quota fissa se prevista'
                : item.code.trim() == '0.13'
                ? 'verificare presenza del cartello Osservatorio SQNPI (secondo il modello pubblicato in SIAN) presso il centro aziendale in posizione visibile a terzi, eventuale pubblicità sul sito web…'
                : item.code.trim() == '1.1'
                ? "riportare evidenza di almeno 1 trattamento per coltura presente in domanda (Coltura, superficie, data trattamento, prodotto utilizzato, avversita', dose impiegata  (non dose/ha) )"
                : (item.code.trim() == '1.2.1' ||
                      item.code.trim() == '1.3' ||
                      item.code.trim() == '1.6' ||
                      item.code.trim() == '1.7')
                ? 'riportare esempio quale evidenza di verifica'
                : item.code.trim() == '1.2.2'
                ? 'In caso di prelievo campione la conformità al requisito sarà valitata da Bios sede centrale al ricevimento del RDP'
                : item.code.trim() == '1.4'
                ? 'Effettuare bilancio di massa su almeno due sostanze attive considerando anche le scorte di magazzino ( è possibile utilizzare sezione bilancio di massa presente in M904)'
                : item.code.trim() == '1.8'
                ? "verificare le modalità di monitoraggio adottate dall'operatore e riportarle"
                : item.code.trim() == '1.9'
                ? 'verificare il rispetto dei volumi di acqua/ha utilizzati per i trattamenti. Riportare esempio'
                : item.code.trim() == '1.10'
                ? 'Verificare la presenza del Certificato attestante il Controllo funzionale e la Regolazione strumentale  (macchina/attrezzatura, n°cert, validità dal_ al_ ) degli atomizzatori/botti/barre in uso. -  riportare evidenza'
                : item.code.trim() == '1.11'
                ? 'Indicare il/i soggetto/i in possesso del Patentino Fitosanitario e riportare estremi del docum. ( valido dal_ al_ )'
                : item.code.trim() == '3.1'
                ? "verificare e descrivere gli interventi effettuati dall'operatore per rafforzare la biodiversità"
                : item.code.trim() == '3.2'
                ? 'verificare le registrazioni (acquisto/utilizzo prodotti su tali aree se del caso con BM)'
                : item.code.trim() == '4.2'
                ? 'riportare esempio varietà utilizzate'
                : item.code.trim() == '4.3'
                ? 'verificare DPI se prevede "liste varietali"'
                : (item.code.trim() == '4.5.2' ||
                      item.displayCode.startsWith('4.5.2'))
                ? "verificare documenti fiscali e i certificati relativi a nuovi impianti effettuati"
                : (item.code.trim() == '4.5.1' ||
                      item.displayCode.startsWith('4.5.1'))
                ? "verificare documenti fiscali e i certificati relativi all'acquisto di semente e piantine orticole"
                : (item.code.trim() == '4.6' ||
                      item.displayCode.startsWith('4.6'))
                ? "verificare se l'operatore ricorre all'autoproduzione"
                : (item.displayCode.startsWith('5.1') ||
                      item.displayCode.startsWith('5.2') ||
                      item.displayCode.startsWith('5.3') ||
                      item.displayCode.startsWith('5.4'))
                ? 'Commento'
                : (item.displayCode.startsWith('6.1') ||
                      item.displayCode.startsWith('6.2'))
                ? 'verificare regola rotazione prevista dalle Norme Tecniche del DPI regionale. Riportare esempio di rotazione applicata (considerare almento 4 anni se applicabile)'
                : (item.displayCode.startsWith('6.3') ||
                      item.displayCode.startsWith('8.4'))
                ? 'verificare se DPI prevede ulteriori disposizioni'
                : item.displayCode.startsWith('6.4')
                ? 'verificare se DPI prevede ulteriori disposizioni in merito a REIMPIANTO colture Arboree'
                : item.displayCode.startsWith('7.1')
                ? 'verificare se DPI prevede vincoli specifici per semina, trapianto e impianto. Se sì riportare evidenza controllo'
                : (item.displayCode.startsWith('8.1.1') ||
                      item.displayCode.startsWith('8.2.3'))
                ? "riportare tecniche di lavorazione adottate dall'operatore"
                : (item.displayCode.startsWith('8.1.2') ||
                      item.displayCode.startsWith('8.2.6') ||
                      item.displayCode.startsWith('8.3'))
                ? "riportare tecniche di lavorazione adottate dall'operatore (es. rispetto inerbimento o altre lavorazioni previste da DPI)"
                : item.displayCode.startsWith('8.2.4')
                ? "riportare sistemi di protezione del suolo dall'erosione adottati dall'operatore"
                : item.displayCode.startsWith('8.2.5')
                ? "riportare eventuali sistemi di protezione del suolo dall'erosione alternativi adottati dall'operatore"
                : item.displayCode.startsWith('9.2')
                ? "tecniche adottate dall'operatore, ricorso a fitoregolatori ammessi (riportare evidenza)"
                : (item.displayCode == '10.1' ||
                      item.displayCode.startsWith('10.1.'))
                ? 'Riportare evidenza di verifica quali riferimenti al piano di concimazione o alle schede dosi standard impiegate. Devono essere presenti in azienda assieme alle analisi del suolo'
                : (item.displayCode == '10.2' ||
                      item.displayCode.startsWith('10.2.'))
                ? 'Effettuare bilancio di massa concimazioni. Verifica incrociata con scheda magazzino fertilizzanti, quaderno di campagna'
                : (item.displayCode == '10.3' ||
                      item.displayCode.startsWith('10.3.'))
                ? 'Se fertilizzazione organica, verificare rispetto limiti 170 kg N/ha annui. Fare bilancio di massa.'
                : (item.displayCode == '10.4' ||
                      item.displayCode.startsWith('10.4.'))
                ? 'verificare registro fertilizzazione e riportare esempio'
                : (item.displayCode == '10.5.1' ||
                      item.displayCode.startsWith('10.5.1.') ||
                      item.displayCode == '10.5.2' ||
                      item.displayCode.startsWith('10.5.2.'))
                ? 'Fornire evidenza analisi suolo per aree omogenee (estremi del Rdp, validità, area omogenea di riferimento ) o riferimenti a carte dei suoli'
                : (item.displayCode == '11.1' ||
                      item.displayCode.startsWith('11.1.'))
                ? 'verifica registro irrigazioni: riportare esempio volumi di irrigazione impiegati e loro rispetto ai massimali previsti da DPI'
                : (item.displayCode == '11.2' ||
                      item.displayCode.startsWith('11.2.'))
                ? 'riportare il metodo di irrigazione adottato dall\'operatore'
                : (item.displayCode == '11.3' ||
                      item.displayCode.startsWith('11.3.'))
                ? 'se richiesti da DPI : analisi delle acque'
                : (item.displayCode == '12.1' ||
                      item.displayCode.startsWith('12.1.'))
                ? 'per le colture fuori suolo: riportare evidenze come da campo NOTE'
                : (item.displayCode == '12.2' ||
                      item.displayCode.startsWith('12.2.'))
                ? 'per le colture in serra riportare evidenze come campo NOTE'
                : (item.displayCode == '12.3' ||
                      item.displayCode.startsWith('12.3.'))
                ? 'per fungaie verificare se ulteriori vincoli da DPI'
                : (item.displayCode == '13.1' ||
                      item.displayCode.startsWith('13.1.'))
                ? 'Se previsti da DPI: per le aziende oggetto di verifica: almeno 2 schede di cui una del prodotto più rappresentativo in termini di superficie (vedi campo NOTE)'
                : (item.displayCode == '13.2' ||
                      item.displayCode.startsWith('13.2.'))
                ? 'Se previsti da DPI:riportare evidenza controlli come campo NOTE'
                : (item.displayCode == '14.0' ||
                      item.displayCode.startsWith('14.0.'))
                ? 'riportare evidenza dell\'autocontrollo effettuato (registrazioni autocontrollo del…, n° soci.)'
                : (item.displayCode == '14.1' ||
                      item.displayCode.startsWith('14.1.'))
                ? 'riportare n° di analisi effettuate in autocontrollo in relazione al campione previsto'
                : (item.displayCode == '14.2' ||
                      item.displayCode.startsWith('14.2.'))
                ? 'riportare evidenza di gestione lotti Non conformi a seguito di analisi'
                : (item.displayCode == '14.4' ||
                      item.displayCode.startsWith('14.4.'))
                ? 'riportare evidenza di gestione Non conformità a seguito di autocontrollo'
                : (item.displayCode == '15.1' ||
                      item.displayCode.startsWith('15.1.'))
                ? 'riportare esempio di trattamento post raccolta effettuato dall\'operatore'
                : (item.displayCode == '15.4' ||
                      item.displayCode.startsWith('15.4.'))
                ? 'rispetto RMA'
                : (item.displayCode == '15.5' ||
                      item.displayCode.startsWith('15.5.'))
                ? 'Per prodotti trasformati : 95 % delle materie prime devono essere SQNPI, nel 5%rientrano  ingredienti non reperibili SQ sul mercato e il saccarosio.'
                : (item.displayCode == '15.6' ||
                      item.displayCode.startsWith('15.6.') ||
                      item.displayCode == '15.7' ||
                      item.displayCode.startsWith('15.7.'))
                ? 'Riportare estremi del piano triennale ed evidenza aggiornamento.  - descrizione dei singoli punti oggetto di controllo'
                : (item.displayCode == '15.8' ||
                      item.displayCode.startsWith('15.8.'))
                ? 'verifica registrazione consumi: riportare evidenza di verifica.'
                : (item.displayCode == '15.9' ||
                      item.displayCode.startsWith('15.9.') ||
                      item.displayCode == '15.10' ||
                      item.displayCode.startsWith('15.10.') ||
                      item.displayCode == '15.11' ||
                      item.displayCode.startsWith('15.11.'))
                ? 'Riportare estremi del piano triennale ed evidenza aggiornamento.  - descrizione misure adottate'
                : (item.displayCode == '15.12' ||
                      item.displayCode.startsWith('15.12.'))
                ? 'commento obbligatorio'
                : (item.displayCode == '15.13' ||
                      item.displayCode.startsWith('15.13.'))
                ? 'commento obbligatorio:    attenzione, certificato del casellario giudiziale obbligatorio (vedi campo NOTE)'
                : (item.displayCode == '15.14' ||
                      item.displayCode.startsWith('15.14.'))
                ? 'commento obbligatorio - riportare estremi doc'
                : (item.displayCode == '15.15' ||
                      item.displayCode.startsWith('15.15.'))
                ? 'commento obbligatorio: riportare informazioni relative agli ultimi corsi effettuati'
                : (item.displayCode == '16.1' ||
                      item.displayCode.startsWith('16.1.'))
                ? 'Obbligatorio: Fornire evidenza caricamento dati sul SI per un lotto a scelta (per settore vitivinicolo e olivicolo vedi campo NOTE)'
                : (item.displayCode == '16.2' ||
                      item.displayCode.startsWith('16.2.'))
                ? 'prova di rintracciabilità (registri, documenti fiscali) su almeno un lotto di prodotto'
                : (item.displayCode == '16.3' ||
                      item.displayCode.startsWith('16.3.'))
                ? 'effettuare Bilancio di massa di un lotto di prodotto secondo quanto previsto da  (vedi campo OBBLIGHI)'
                : (item.displayCode == '16.4' ||
                      item.displayCode.startsWith('16.4.'))
                ? 'commento obbligatorio'
                : ({
                        '17.1',
                        '17.2',
                        '17.3',
                        '17.4',
                        '17.7',
                        '17.8',
                      }.contains(item.code.trim()) ||
                      {
                        '17.1',
                        '17.2',
                        '17.3',
                        '17.4',
                        '17.7',
                        '17.8',
                      }.contains(item.displayCode))
                ? 'Evidenza verifica n° di lotti secondo quanto previsto da (vedi campo FREQUENZA OPERATORE SINGOLO)'
                : (item.displayCode == '17.10' ||
                      item.displayCode.startsWith('17.10.'))
                ? 'verificare in Biosfera pagamento quote anni precedenti o quota fissa se prevista'
                : 'verificare presenza delle registrazioni e riportare ultimo trattamento registrato',
            icon: Icons.fact_check_outlined,
            backgroundColor: odcColors.bg,
            borderColor: odcColors.border,
            iconColor: odcColors.text,
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
    // Se il testo contiene a capo, lo gestiamo come un elenco puntato
    if (cleanedContent.contains('\n')) {
      final lines = cleanedContent
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (lines.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            // Se la riga inizia già con un marcatore (numero, lettera, trattino), non aggiungiamo il bullet
            final hasMarker = RegExp(
              r'^(\d+\.|[a-z]\.|[•\-\*])\s+',
            ).hasMatch(line);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasMarker) ...[
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (hasMarker) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
    }

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

    if (cleanedContent.contains('**') || cleanedContent.contains('<u>')) {
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            height: 1.4,
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),
          children: _parseStyledText(cleanedContent),
        ),
      );
    }

    return Text(
      cleanedContent,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
    );
  }

  List<TextSpan> _parseStyledText(String text) {
    List<TextSpan> spans = [];

    // Regex per trovare **bold** o <u>underline</u>
    final regex = RegExp(r'(\*\*.*?\*\*|<u>.*?</u>)');
    int lastMatchEnd = 0;

    final matches = regex.allMatches(text);

    for (final match in matches) {
      // Testo normale prima del match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        // Grassetto (ricorsivo per gestire eventuali <u> all'interno)
        final innerText = matchText.substring(2, matchText.length - 2);
        spans.add(
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.bold),
            children: _parseStyledText(innerText),
          ),
        );
      } else if (matchText.startsWith('<u>') && matchText.endsWith('</u>')) {
        // Sottolineato (ricorsivo per gestire eventuali ** all'interno)
        final innerText = matchText.substring(3, matchText.length - 4);
        spans.add(
          TextSpan(
            style: const TextStyle(decoration: TextDecoration.underline),
            children: _parseStyledText(innerText),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Testo rimanente
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }
}

class _ChecklistOutcomeBlock extends ConsumerStatefulWidget {
  const _ChecklistOutcomeBlock({
    super.key,
    required this.uecs,
    required this.item,
    required this.visitId,
    required this.isReadOnly,
    required this.conformita,
    this.initialResponse,
  });

  final List<VisitUec> uecs;
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
    final uecIds = widget.uecs.map((u) => u.id).toList();

    await repo.saveChecklistResponsesForUecs(
      uecIds: uecIds,
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
      for (final uec in widget.uecs) {
        await logger.log(
          action: 'CREATE_NON_CONFORMITY',
          description:
              'Rilevata NC su requisito ${widget.item.code} per UEC: ${uec.id}',
          actor: auth.username ?? 'Ispettore',
        );
      }
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
                widget.uecs.length > 1
                    ? 'Esito per: TUTTE LE COLTURE SELEZIONATE (${widget.uecs.length})'
                    : (_operatorOnlyCodes.contains(widget.item.code.trim()) ||
                          widget.uecs.first.id.startsWith(_operatorUecIdPrefix))
                    ? 'Esito per Operatore'
                    : 'Esito per: ${widget.uecs.first.nAggregato.isNotEmpty ? '${widget.uecs.first.coltura} (${widget.uecs.first.nAggregato})' : widget.uecs.first.coltura}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
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
                      '0.8',
                      '0.12',
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
                      '17.10',
                      '14.0',
                      '14.1',
                      '14.2',
                      '16.2',
                    }.contains(widget.item.code.trim()) ||
                    (widget.item.code.trim() == '16.2' &&
                        !widget.uecs.first.id.startsWith(_operatorUecIdPrefix)))
                  _ScoreDropdown(
                    label: 'Punteggio KO UEC/Lotto',
                    value: _pUec,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      if (widget.item.code.trim() == '0.11' ||
                          widget.item.code.trim() == '10.3' ||
                          widget.item.code.trim() == '10.6' ||
                          widget.item.code.trim() == '11.2' ||
                          widget.item.displayCode.contains('4.5.2')) ...[
                        const DropdownMenuItem(value: 3, child: Text('3')),
                      ] else if (widget.item.code.trim() == '1.2.1' ||
                          widget.item.code.trim() == '1.3' ||
                          widget.item.code.trim() == '1.4' ||
                          widget.item.code.trim() == '6.4' ||
                          widget.item.code.trim() == '7.1' ||
                          widget.item.code.trim() == '8.1.1' ||
                          widget.item.code.trim() == '8.1.2' ||
                          widget.item.code.trim() == '8.2.6' ||
                          widget.item.code.trim() == '8.3' ||
                          widget.item.code.trim() == '8.4' ||
                          widget.item.code.trim() == '10.4' ||
                          widget.item.code.trim() == '12.1' ||
                          widget.item.code.trim() == '12.3' ||
                          widget.item.code.trim() == '13.1' ||
                          widget.item.code.trim() == '13.2') ...[
                        const DropdownMenuItem(value: 2, child: Text('2')),
                      ] else if (widget.item.code.trim() == '1.1' ||
                          widget.item.code.trim() == '1.2.2' ||
                          widget.item.code.trim() == '10.1' ||
                          widget.item.code.trim() == '12.2' ||
                          widget.item.code.trim() == '14.0' ||
                          widget.item.code.trim() == '14.1' ||
                          widget.item.code.trim() == '14.2' ||
                          widget.item.code.trim() == '15.1' ||
                          widget.item.code.trim() == '15.2' ||
                          widget.item.code.trim() == '15.3' ||
                          widget.item.code.trim() == '15.4' ||
                          widget.item.code.trim() == '15.5' ||
                          widget.item.code.trim() == '16.1' ||
                          widget.item.code.trim() == '16.2' ||
                          widget.item.code.trim() == '16.3' ||
                          widget.item.code.trim() == '16.4' ||
                          widget.item.code.trim() == '17.2' ||
                          widget.item.code.trim() == '17.4' ||
                          widget.item.code.trim() == '17.8')
                        ...[
                      ] else if (widget.item.code.trim() == '0.9' ||
                          widget.item.code.trim() == '0.10' ||
                          widget.item.code.trim() == '1.6' ||
                          widget.item.code.trim() == '1.7' ||
                          widget.item.code.trim() == '1.8' ||
                          widget.item.code.trim() == '1.9' ||
                          widget.item.code.trim() == '2.1' ||
                          widget.item.code.trim() == '2.2' ||
                          widget.item.code.trim() == '4.2' ||
                          widget.item.code.trim() == '4.3' ||
                          widget.item.displayCode.contains('4.5.1') ||
                          widget.item.displayCode.startsWith('4.6') ||
                          widget.item.displayCode.startsWith('5.1') ||
                          widget.item.displayCode.startsWith('5.2') ||
                          widget.item.displayCode.startsWith('5.3') ||
                          widget.item.displayCode.startsWith('5.4') ||
                          widget.item.code.trim() == '8.2.3' ||
                          widget.item.code.trim() == '8.2.4' ||
                          widget.item.code.trim() == '8.2.5' ||
                          widget.item.code.trim() == '11.1' ||
                          widget.item.displayCode.startsWith('9.2')) ...[
                        const DropdownMenuItem(value: 1, child: Text('1')),
                      ] else ...[
                        const DropdownMenuItem(value: 1, child: Text('1')),
                        const DropdownMenuItem(value: 2, child: Text('2')),
                        const DropdownMenuItem(value: 3, child: Text('3')),
                      ],
                      if (widget.item.hasEsclusioneLotto ||
                          widget.item.code.trim() == '0.1' ||
                          widget.item.code.trim() == '0.2' ||
                          widget.item.code.trim() == '0.11' ||
                          widget.item.code.trim() == '1.1' ||
                          widget.item.code.trim() == '1.2.2' ||
                          widget.item.code.trim() == '10.1' ||
                          widget.item.code.trim() == '12.2' ||
                          widget.item.code.trim() == '14.0' ||
                          widget.item.code.trim() == '14.1' ||
                          widget.item.code.trim() == '14.2' ||
                          widget.item.code.trim() == '15.1' ||
                          widget.item.code.trim() == '15.2' ||
                          widget.item.code.trim() == '15.3' ||
                          widget.item.code.trim() == '15.4' ||
                          widget.item.code.trim() == '15.5' ||
                          widget.item.code.trim() == '16.1' ||
                          widget.item.code.trim() == '16.2' ||
                          widget.item.code.trim() == '16.3' ||
                          widget.item.code.trim() == '16.4' ||
                          widget.item.code.trim() == '17.2' ||
                          widget.item.code.trim() == '17.4' ||
                          widget.item.code.trim() == '17.8')
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            (widget.item.code.trim() == '14.0' ||
                                    widget.item.code.trim() == '14.1' ||
                                    widget.item.code.trim() == '14.2')
                                ? "Esclusione (da attribuire all'OA)"
                                : 'Esclusione lotto',
                          ),
                        ),
                    ],
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
                      '1.1',
                      '1.2.1',
                      '1.2.2',
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
                      '10.1',
                      '10.2',
                      '10.3',
                      '10.4',
                      '10.6',
                      '11.1',
                      '11.2',
                      '12.1',
                      '12.2',
                      '12.3',
                      '13.1',
                      '13.2',
                      '15.1',
                      '15.2',
                      '15.3',
                      '15.4',
                      '15.5',
                      '16.1',
                      '16.3',
                      '16.4',
                      '17.1',
                      '17.2',
                      '17.3',
                      '17.4',
                      '17.7',
                      '17.8',
                      '16.2',
                    }.contains(widget.item.code.trim()) ||
                    (widget.item.code.trim() == '16.2' &&
                        widget.uecs.first.id.startsWith(_operatorUecIdPrefix)))
                  _ScoreDropdown(
                    label: 'Punteggio KO Operatore',
                    value: _pOp,
                    items: widget.item.code.trim() == '0.8'
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(
                              value: 0,
                              child: Text(
                                'Sospensione operatore ai fini della certificazione (marchio)',
                              ),
                            ),
                          ]
                        : (widget.item.code.trim() == '0.12' ||
                              widget.item.code.trim() == '16.2' ||
                              widget.item.code.trim() == '17.10')
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Sospensione'),
                            ),
                          ]
                        : (widget.item.code.trim() == '0.13' ||
                              widget.item.code.trim() == '3.1' ||
                              widget.item.code.trim() == '11.3' ||
                              widget.item.code.trim() == '15.8' ||
                              widget.item.code.trim() == '15.9' ||
                              widget.item.code.trim() == '15.10' ||
                              widget.item.code.trim() == '15.11' ||
                              widget.item.code.trim() == '15.13' ||
                              widget.item.code.trim() == '17.9' ||
                              widget.item.code.trim() == '0.12')
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(value: 1, child: Text('1')),
                          ]
                        : widget.item.code.trim() == '17.6'
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(value: 3, child: Text('3')),
                          ]
                        : (widget.item.code.trim() == '3.2' ||
                              widget.item.code.trim() == '15.12' ||
                              widget.item.code.trim() == '15.14' ||
                              widget.item.code.trim() == '15.15')
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(value: 2, child: Text('2')),
                          ]
                        : (widget.item.code.trim() == '14.0' ||
                              widget.item.code.trim() == '14.1' ||
                              widget.item.code.trim() == '14.2' ||
                              widget.item.code.trim() == '14.4')
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('—'),
                            ),
                            const DropdownMenuItem(
                              value: 0,
                              child: Text("Esclusione (da attribuire all'OA)"),
                            ),
                          ]
                        : null,
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

class _ChecklistSidebar extends StatelessWidget {
  final List<String> fasi;
  final String selectedFase;
  final Function(String) onFaseSelected;

  const _ChecklistSidebar({
    required this.fasi,
    required this.selectedFase,
    required this.onFaseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: fasi.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final fase = fasi[index];
            final isSelected = fase == selectedFase;

            // Estraiamo il numero del capitolo per l'icona o lo stile
            final chapterMatch = RegExp(r'^(\d+)\.').firstMatch(fase);
            final chapterNum = chapterMatch?.group(1) ?? '';

            return Material(
              color: isSelected
                  ? const Color(0xFF1B4332).withValues(alpha: 0.05)
                  : Colors.transparent,
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? const Color(0xFF1B4332)
                      : Colors.grey.shade200,
                  child: Text(
                    chapterNum,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                title: Text(
                  fase.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1B4332)
                        : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onFaseSelected(fase),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChecklistChips extends StatelessWidget {
  final List<String> fasi;
  final String selectedFase;
  final Function(String) onFaseSelected;

  const _ChecklistChips({
    required this.fasi,
    required this.selectedFase,
    required this.onFaseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: fasi.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fase = fasi[index];
          final isSelected = fase == selectedFase;
          final chapterMatch = RegExp(r'^(\d+)\.').firstMatch(fase);
          final chapterNum = chapterMatch?.group(1) ?? '';

          return ChoiceChip(
            label: Text(
              chapterNum.isNotEmpty
                  ? '$chapterNum. ${fase.replaceFirst(RegExp(r'^\d+\.\s*'), '')}'
                  : fase,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onFaseSelected(fase);
            },
            selectedColor: const Color(0xFF1B4332),
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF1B4332)
                    : Colors.grey.shade300,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
