import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../data/audits_repository.dart';

final uecsByVisitIdProvider = StreamProvider.family<List<VisitUec>, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUecsByVisitId(visitId);
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

final responseProvider =
    StreamProvider.family<
      ChecklistResponse?,
      ({String uecId, String itemCode})
    >((ref, p) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchResponse(p.uecId, p.itemCode);
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

class ChecklistPage extends ConsumerStatefulWidget {
  const ChecklistPage({super.key, required this.visitId});
  final String visitId;

  @override
  ConsumerState<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends ConsumerState<ChecklistPage> {
  String? _selectedUecId;
  String? _selectedFase;

  @override
  Widget build(BuildContext context) {
    final uecsAsync = ref.watch(uecsByVisitIdProvider(widget.visitId));
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
                    'Prima di compilare la checklist, crea almeno una UEC in “UEC/Lotti”.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              _selectedUecId ??= uecs.first.id;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checklist SQNPI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'UEC:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedUecId,
                        items: uecs
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  u.descrizione.isNotEmpty
                                      ? '${u.descrizione} (${u.coltura})'
                                      : '${u.id} (${u.coltura})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUecId = v),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: fasiAsync.when(
                          data: (fasi) {
                            if (fasi.isEmpty) {
                              return const Text('Checklist non importata.');
                            }
                            _selectedFase ??= fasi.first;

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
                                    value: _selectedFase,
                                    items: fasi
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
                                    onChanged: (v) =>
                                        setState(() => _selectedFase = v),
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
                      const Spacer(),
                      _ScoreBadges(
                        visitId: widget.visitId,
                        uecId: _selectedUecId!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: (_selectedFase == null)
                        ? const Center(child: Text('Seleziona una fase.'))
                        : _ChecklistList(
                            fase: _selectedFase!,
                            uecId: _selectedUecId!,
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
  const _ScoreBadges({required this.visitId, required this.uecId});
  final String visitId;
  final String uecId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sumUecAsync = ref.watch(sumPunteggioUecProvider(uecId));
    final sumOpAsync = ref.watch(sumPunteggioOperatoreByVisitProvider(visitId));

    return Row(
      children: [
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
  const _ChecklistList({required this.fase, required this.uecId});
  final String fase;
  final String uecId;

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
          itemBuilder: (ctx, i) =>
              _ChecklistItemCard(uecId: uecId, item: items[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore checklist: $e')),
    );
  }
}

class _ChecklistItemCard extends ConsumerStatefulWidget {
  const _ChecklistItemCard({required this.uecId, required this.item});
  final String uecId;
  final ChecklistItem item;

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

  void _loadFromDbIfNeeded(ChecklistResponse? r) {
    if (_loaded) return;
    _loaded = true;
    if (r == null) return;

    _conf = Conformita.values[r.conformita];
    _livelloKo = r.livelloKo;
    _pUec = r.punteggioUec;
    _pOp = r.punteggioOperatore;
    _rilievo.text = r.rilievoNc;
    _note.text = r.note;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(auditsRepositoryProvider);
      await repo.saveChecklistResponse(
        uecId: widget.uecId,
        itemCode: widget.item.code,
        conformita: _conf,
        livelloKo: _conf == Conformita.ko ? _livelloKo : null,
        punteggioUec: _pUec,
        punteggioOperatore: _pOp,
        rilievoNc: _rilievo.text.trim(),
        note: _note.text.trim(),
      );
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
    final respAsync = ref.watch(
      responseProvider((uecId: widget.uecId, itemCode: widget.item.code)),
    );

    return respAsync.when(
      data: (resp) {
        _loadFromDbIfNeeded(resp);

        final title = '${widget.item.code} — ${widget.item.obbligo}';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (_saving)
                      const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    _AttachmentBadge(code: widget.item.code),
                  ],
                ),
                const SizedBox(height: 8),

                if (widget.item.noteNorma.isNotEmpty)
                  Text(
                    'Note: ${widget.item.noteNorma}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                if (widget.item.gravitaUecText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Gravità UEC/Lotto (testo): ${widget.item.gravitaUecText}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (widget.item.gravitaOperatoreText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Gravità Operatore (testo): ${widget.item.gravitaOperatoreText}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ConfDropdown(
                      value: _conf,
                      onChanged: (v) {
                        setState(() {
                          _conf = v;
                          if (_conf != Conformita.ko) _livelloKo = null;
                        });
                        _save();
                      },
                    ),
                    if (_conf == Conformita.ko)
                      _LivelloKoDropdown(
                        value: _livelloKo,
                        onChanged: (v) {
                          setState(() => _livelloKo = v);
                          _save();
                        },
                      ),
                    _ScoreDropdown(
                      label: 'Punteggio UEC/Lotto',
                      value: _pUec,
                      onChanged: (v) {
                        setState(() => _pUec = v);
                        _save();
                      },
                    ),
                    _ScoreDropdown(
                      label: 'Punteggio Operatore',
                      value: _pOp,
                      onChanged: (v) {
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
                          decoration: InputDecoration(
                            labelText:
                                'Rilievo N/C (coltura, appezzamento, dettaglio...)',
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
                      if (constraints.maxWidth > 600) const SizedBox(width: 16),
                      if (constraints.maxWidth <= 600)
                        const SizedBox(height: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _note,
                          onChanged: _onTextChanged,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: 'Note (obbligatorie se NA o richiesto)',
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
    );
  }
}

class _ConfDropdown extends StatelessWidget {
  const _ConfDropdown({required this.value, required this.onChanged});
  final Conformita value;
  final ValueChanged<Conformita> onChanged;

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
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _LivelloKoDropdown extends StatelessWidget {
  const _LivelloKoDropdown({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

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
          onChanged: (v) => onChanged(v),
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
  final ValueChanged<int?> onChanged;

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
          onChanged: (v) => onChanged(v),
        ),
      ],
    );
  }
}
