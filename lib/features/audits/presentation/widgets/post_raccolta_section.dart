import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/db_providers.dart';
import '../../../../core/widgets/help_tooltip.dart';
import '../../../../core/constants/help_texts.dart';

class PostHarvestPhaseData {
  String fase;
  bool inProprio;
  bool terzista;
  String prodotto;
  bool? conformitaSqnpi;
  bool? tracciabile;
  String note;

  PostHarvestPhaseData({
    required this.fase,
    this.inProprio = false,
    this.terzista = false,
    this.prodotto = '',
    this.conformitaSqnpi,
    this.tracciabile,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'fase': fase,
    'inProprio': inProprio,
    'terzista': terzista,
    'prodotto': prodotto,
    'conformitaSqnpi': conformitaSqnpi,
    'tracciabile': tracciabile,
    'note': note,
  };

  factory PostHarvestPhaseData.fromJson(Map<String, dynamic> json) =>
      PostHarvestPhaseData(
        fase: json['fase'] ?? '',
        inProprio: json['inProprio'] ?? false,
        terzista: json['terzista'] ?? false,
        prodotto: json['prodotto'] ?? '',
        conformitaSqnpi: json['conformitaSqnpi'],
        tracciabile: json['tracciabile'],
        note: json['note'] ?? '',
      );
}

class PostRaccoltaSection extends ConsumerStatefulWidget {
  final String visitId;
  final bool isReadOnly;

  const PostRaccoltaSection({
    super.key,
    required this.visitId,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<PostRaccoltaSection> createState() =>
      _PostRaccoltaSectionState();
}

class _PostRaccoltaSectionState extends ConsumerState<PostRaccoltaSection> {
  bool _isLoading = true;
  PostHarvestRecord? _record;

  List<PostHarvestPhaseData> phases = [];

  final _mbVerifiedProductsController = TextEditingController();
  final _mbInputDataController = TextEditingController();
  final _mbInputDocsController = TextEditingController();
  final _mbOutputDataController = TextEditingController();
  final _mbOutputDocsController = TextEditingController();
  final _mbCommentController = TextEditingController();

  final _traceabilityVerifiedProductsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mbVerifiedProductsController.dispose();
    _mbInputDataController.dispose();
    _mbInputDocsController.dispose();
    _mbOutputDataController.dispose();
    _mbOutputDocsController.dispose();
    _mbCommentController.dispose();
    _traceabilityVerifiedProductsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = ref.read(appDatabaseProvider);
    final record = await (db.select(
      db.postHarvestRecords,
    )..where((t) => t.visitId.equals(widget.visitId))).getSingleOrNull();

    if (record != null) {
      _record = record;
      try {
        final List<dynamic> jsonList = jsonDecode(record.phases);
        phases = jsonList.map((e) => PostHarvestPhaseData.fromJson(e)).toList();
      } catch (_) {
        phases = [];
      }
      _mbVerifiedProductsController.text = record.mbVerifiedProducts;
      _mbInputDataController.text = record.mbInputData;
      _mbInputDocsController.text = record.mbInputDocs;
      _mbOutputDataController.text = record.mbOutputData;
      _mbOutputDocsController.text = record.mbOutputDocs;
      _mbCommentController.text = record.mbComment;
      _traceabilityVerifiedProductsController.text =
          record.traceabilityVerifiedProducts;
    }

    if (phases.isEmpty) {
      // Initialize with 1 empty row by default
      phases = [PostHarvestPhaseData(fase: '')];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    if (widget.isReadOnly) return;
    final db = ref.read(appDatabaseProvider);

    final jsonPhases = jsonEncode(phases.map((e) => e.toJson()).toList());

    final companion = PostHarvestRecordsCompanion.insert(
      id: _record?.id ?? 'PH-${widget.visitId}',
      visitId: widget.visitId,
      phases: drift.Value(jsonPhases),
      mbVerifiedProducts: drift.Value(_mbVerifiedProductsController.text),
      mbInputData: drift.Value(_mbInputDataController.text),
      mbInputDocs: drift.Value(_mbInputDocsController.text),
      mbOutputData: drift.Value(_mbOutputDataController.text),
      mbOutputDocs: drift.Value(_mbOutputDocsController.text),
      mbComment: drift.Value(_mbCommentController.text),
      traceabilityVerifiedProducts: drift.Value(
        _traceabilityVerifiedProductsController.text,
      ),
      updatedAt: DateTime.now(),
    );

    await db.into(db.postHarvestRecords).insertOnConflictUpdate(companion);

    // Refresh record reference
    final record = await (db.select(
      db.postHarvestRecords,
    )..where((t) => t.visitId.equals(widget.visitId))).getSingleOrNull();
    _record = record;
  }

  Widget _buildYesNoGroup(
    String label,
    bool? value,
    ValueChanged<bool?> onChanged,
  ) {
    final helpText = HelpTexts.get(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (helpText != null) ...[
              const SizedBox(width: 4),
              HelpTooltip(text: helpText, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Checkbox(
              value: value == true,
              onChanged: widget.isReadOnly ? null : (_) => onChanged(true),
            ),
            const Text('Sì', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Checkbox(
              value: value == false,
              onChanged: widget.isReadOnly ? null : (_) => onChanged(false),
            ),
            const Text('No', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostHarvestGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          Icons.inventory_2_outlined,
          'FASE DI POST RACCOLTA: Quadro di verifica',
          subtitle:
              '(pre-pulitura, cernita, trasporto ai centri di lavorazione, conservazione, condizionamento, confezionamento, trasformazione, commercializzazione con marchio freschi/ non trasformati e trasformati)',
        ),
        const SizedBox(height: 12),
        ...phases.asMap().entries.map((entry) {
          final int idx = entry.key;
          final phase = entry.value;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: Colors.teal.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DETTAGLI FASE ${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Fase post raccolta applicabile',
                                suffixIcon: HelpTexts.get('Fase post raccolta applicabile') != null 
                                  ? HelpTooltip(text: HelpTexts.get('Fase post raccolta applicabile')!) 
                                  : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              initialValue: phase.fase,
                              onChanged: (val) {
                                phase.fase = val;
                                _saveData();
                              },
                              readOnly: widget.isReadOnly,
                            ),
                          ),
                          if (!widget.isReadOnly && phases.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  phases.removeAt(idx);
                                });
                                _saveData();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: phase.inProprio,
                                  onChanged: widget.isReadOnly
                                      ? null
                                      : (v) {
                                          setState(() {
                                            phase.inProprio = v ?? false;
                                            if (phase.inProprio) {
                                              phase.terzista = false;
                                            }
                                          });
                                          _saveData();
                                        },
                                ),
                                const Text(
                                  'in proprio',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: phase.terzista,
                                  onChanged: widget.isReadOnly
                                      ? null
                                      : (v) {
                                          setState(() {
                                            phase.terzista = v ?? false;
                                            if (phase.terzista) {
                                              phase.inProprio = false;
                                            } else {
                                              phase.note = '';
                                            }
                                          });
                                          _saveData();
                                        },
                                ),
                                const Text(
                                  'terzista (certificato SQNPI)',
                                  style: TextStyle(fontSize: 12),
                                ),
                                if (phase.terzista) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Certificato SQNPI del terzista',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      initialValue: phase.note,
                                      onChanged: (val) {
                                        phase.note = val;
                                        _saveData();
                                      },
                                      readOnly: widget.isReadOnly,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Prodotto',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: phase.prodotto,
                        onChanged: (val) {
                          phase.prodotto = val;
                          _saveData();
                        },
                        readOnly: widget.isReadOnly,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildYesNoGroup(
                            'Conformità con standard SQNPI',
                            phase.conformitaSqnpi,
                            (val) {
                              setState(() => phase.conformitaSqnpi = val);
                              _saveData();
                            },
                          ),
                          _buildYesNoGroup(
                            'Il prodotto verificato è identificato e tracciabile',
                            phase.tracciabile,
                            (val) {
                              setState(() => phase.tracciabile = val);
                              _saveData();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (!widget.isReadOnly)
          TextButton.icon(
            onPressed: () {
              setState(() {
                phases.add(PostHarvestPhaseData(fase: ''));
              });
              _saveData();
            },
            icon: const Icon(Icons.add, color: Colors.teal),
            label: const Text(
              'Aggiungi riga',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildMassBalance() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            Icons.scale_outlined,
            'BILANCIO DI MASSA prodotto post raccolta (vino/olio... altro)',
            subtitle: '(Rif. Check-list punto 16.3)',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _mbVerifiedProductsController,
                  decoration: InputDecoration(
                    labelText: 'Prodotti verificati',
                    suffixIcon: HelpTexts.get('Prodotti verificati') != null
                      ? HelpTooltip(text: HelpTexts.get('Prodotti verificati')!)
                      : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  readOnly: widget.isReadOnly,
                  onChanged: (_) => _saveData(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mbInputDataController,
                        decoration: InputDecoration(
                          labelText: 'Dati in ingresso',
                          suffixIcon: HelpTexts.get('Dati in ingresso') != null
                            ? HelpTooltip(text: HelpTexts.get('Dati in ingresso')!)
                            : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        readOnly: widget.isReadOnly,
                        maxLines: 2,
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _mbInputDocsController,
                        decoration: InputDecoration(
                          labelText: 'Documenti di riferimento',
                          suffixIcon: HelpTexts.get('Documenti di riferimento') != null
                            ? HelpTooltip(text: HelpTexts.get('Documenti di riferimento')!)
                            : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        readOnly: widget.isReadOnly,
                        maxLines: 2,
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mbOutputDataController,
                        decoration: InputDecoration(
                          labelText: 'Dati in uscita',
                          suffixIcon: HelpTexts.get('Dati in uscita') != null
                            ? HelpTooltip(text: HelpTexts.get('Dati in uscita')!)
                            : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        readOnly: widget.isReadOnly,
                        maxLines: 2,
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _mbOutputDocsController,
                        decoration: InputDecoration(
                          labelText: 'Documenti di riferimento',
                          suffixIcon: HelpTexts.get('Documenti di riferimento') != null
                            ? HelpTooltip(text: HelpTexts.get('Documenti di riferimento')!)
                            : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        readOnly: widget.isReadOnly,
                        maxLines: 2,
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mbCommentController,
                  decoration: const InputDecoration(
                    labelText: 'Commento',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  readOnly: widget.isReadOnly,
                  maxLines: 2,
                  onChanged: (_) => _saveData(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceability() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            Icons.track_changes_outlined,
            'PROVA DI RINTRACCIABILITA\' (... (rev.08) fase di post raccolta)',
            subtitle:
                '(Rif. Check-list punto 16.1) – verifica registrazioni sul SI del SQNPI al fine di garantire la rintracciabilità dei lotti (rev.08)',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _traceabilityVerifiedProductsController,
                  decoration: InputDecoration(
                    labelText: 'Prodotti verificati',
                    suffixIcon: HelpTexts.get('Prova di rintracciabilità') != null
                      ? HelpTooltip(text: HelpTexts.get('Prova di rintracciabilità')!)
                      : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  readOnly: widget.isReadOnly,
                  onChanged: (_) => _saveData(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPostHarvestGrid(),
          const SizedBox(height: 24),
          _buildMassBalance(),
          const SizedBox(height: 24),
          _buildTraceability(),
          // Padding per la tastiera
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
