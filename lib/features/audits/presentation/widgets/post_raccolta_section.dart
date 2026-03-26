import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/db_providers.dart';
import '../../../../core/widgets/help_tooltip.dart';
import '../../../../core/constants/help_texts.dart';

final _phDocsEntrataProvider =
    StreamProvider.family<List<MassBalanceDocument>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalanceDocsByType(visitId, 'ph_entrata');
    });

final _phDocsUscitaProvider =
    StreamProvider.family<List<MassBalanceDocument>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchMassBalanceDocsByType(visitId, 'ph_uscita');
    });

class PostHarvestPhaseData {
  String fase;
  bool inProprio;
  bool terzista;
  String prodotto;
  bool? conformitaSqnpi;
  bool? tracciabile;
  String note; // used for the "always on" note (rev.08)
  String certificatoTerzista; // conditional for Terzista

  PostHarvestPhaseData({
    required this.fase,
    this.inProprio = false,
    this.terzista = false,
    this.prodotto = '',
    this.conformitaSqnpi,
    this.tracciabile,
    this.note = '',
    this.certificatoTerzista = '',
  });

  Map<String, dynamic> toJson() => {
    'fase': fase,
    'inProprio': inProprio,
    'terzista': terzista,
    'prodotto': prodotto,
    'conformitaSqnpi': conformitaSqnpi,
    'tracciabile': tracciabile,
    'note': note,
    'certificatoTerzista': certificatoTerzista,
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
        certificatoTerzista:
            json['certificatoTerzista'] ?? json['noteTracciabile'] ?? '',
      );
}

class PostHarvestMassBalanceData {
  String verifiedProducts;
  String inputData;
  String inputDocs;
  String outputData;
  String outputDocs;
  String comment;

  PostHarvestMassBalanceData({
    this.verifiedProducts = '',
    this.inputData = '',
    this.inputDocs = '',
    this.outputData = '',
    this.outputDocs = '',
    this.comment = '',
  });

  Map<String, dynamic> toJson() => {
    'verifiedProducts': verifiedProducts,
    'inputData': inputData,
    'inputDocs': inputDocs,
    'outputData': outputData,
    'outputDocs': outputDocs,
    'comment': comment,
  };

  factory PostHarvestMassBalanceData.fromJson(Map<String, dynamic> json) =>
      PostHarvestMassBalanceData(
        verifiedProducts: json['verifiedProducts'] ?? '',
        inputData: json['inputData'] ?? '',
        inputDocs: json['inputDocs'] ?? '',
        outputData: json['outputData'] ?? '',
        outputDocs: json['outputDocs'] ?? '',
        comment: json['comment'] ?? '',
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
  List<PostHarvestMassBalanceData> mbBalances = [];

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

      try {
        final List<dynamic> balancesList = jsonDecode(record.mbBalances);
        mbBalances = balancesList
            .map((e) => PostHarvestMassBalanceData.fromJson(e))
            .toList();
      } catch (_) {
        mbBalances = [];
      }
    }

    if (phases.isEmpty) {
      phases = [PostHarvestPhaseData(fase: '')];
    }
    if (mbBalances.isEmpty) {
      mbBalances = [PostHarvestMassBalanceData()];
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
      mbBalances: drift.Value(
        jsonEncode(mbBalances.map((e) => e.toJson()).toList()),
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

  void _addMassBalance() {
    if (widget.isReadOnly) return;
    setState(() {
      mbBalances.add(PostHarvestMassBalanceData());
    });
    _saveData();
  }

  void _removeMassBalance(int index) async {
    if (widget.isReadOnly) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Elimina Bilancio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Sei sicuro di voler eliminare questo bilancio di massa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        mbBalances.removeAt(index);
      });
      _saveData();
    }
  }

  Widget _buildPostHarvestGrid(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'FASE DI POST RACCOLTA',
          subtitle: 'Quadro di verifica e dettagli delle fasi',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 24),
        ...phases.asMap().entries.map((entry) {
          final int idx = entry.key;
          final phase = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _CardGroup(
              title: 'DETTAGLI FASE ${idx + 1}',
              subtitle: 'Informazioni sulla fase post raccolta',
              trailing: !widget.isReadOnly && phases.length > 1
                  ? IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          phases.removeAt(idx);
                        });
                        _saveData();
                      },
                    )
                  : null,
              child: Column(
                children: [
                  // FASE + PRODOTTO (2 columns on desktop)
                  if (isMobile) ...[
                    _ModernTextField(
                      label: 'Fase post raccolta applicabile',
                      initialValue: phase.fase,
                      icon: Icons.layers_outlined,
                      isReadOnly: widget.isReadOnly,
                      helpText: HelpTexts.get('Fase post raccolta applicabile'),
                      onChanged: (val) {
                        phase.fase = val;
                        _saveData();
                      },
                    ),
                    const SizedBox(height: 16),
                    _ModernTextField(
                      label: 'Prodotto',
                      initialValue: phase.prodotto,
                      icon: Icons.shopping_bag_outlined,
                      isReadOnly: widget.isReadOnly,
                      onChanged: (val) {
                        phase.prodotto = val;
                        _saveData();
                      },
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ModernTextField(
                            label: 'Fase post raccolta applicabile',
                            initialValue: phase.fase,
                            icon: Icons.layers_outlined,
                            isReadOnly: widget.isReadOnly,
                            helpText: HelpTexts.get(
                              'Fase post raccolta applicabile',
                            ),
                            onChanged: (val) {
                              phase.fase = val;
                              _saveData();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModernTextField(
                            label: 'Prodotto',
                            initialValue: phase.prodotto,
                            icon: Icons.shopping_bag_outlined,
                            isReadOnly: widget.isReadOnly,
                            onChanged: (val) {
                              phase.prodotto = val;
                              _saveData();
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // MODALITÀ (Simplified, side-by-side chips instead of card-in-card)
                  Row(
                    crossAxisAlignment: isMobile
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODALITÀ DI GESTIONE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ChoiceChip(
                                  label: 'In proprio',
                                  selected: phase.inProprio,
                                  color: Colors.teal.shade600,
                                  onSelected: widget.isReadOnly
                                      ? null
                                      : (_) {
                                          setState(() {
                                            phase.inProprio = true;
                                            phase.terzista = false;
                                            phase.certificatoTerzista = '';
                                          });
                                          _saveData();
                                        },
                                ),
                                _ChoiceChip(
                                  label: 'Terzista',
                                  selected: phase.terzista,
                                  color: Colors.teal.shade600,
                                  onSelected: widget.isReadOnly
                                      ? null
                                      : (_) {
                                          setState(() {
                                            phase.terzista = true;
                                            phase.inProprio = false;
                                          });
                                          _saveData();
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile && phase.terzista) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModernTextField(
                            label: 'Certificato SQNPI del terzista',
                            initialValue: phase.certificatoTerzista,
                            icon: Icons.verified_user_outlined,
                            isReadOnly: widget.isReadOnly,
                            onChanged: (val) {
                              phase.certificatoTerzista = val;
                              _saveData();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isMobile && phase.terzista) ...[
                    const SizedBox(height: 16),
                    _ModernTextField(
                      label: 'Certificato SQNPI del terzista',
                      initialValue: phase.certificatoTerzista,
                      icon: Icons.verified_user_outlined,
                      isReadOnly: widget.isReadOnly,
                      onChanged: (val) {
                        phase.certificatoTerzista = val;
                        _saveData();
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(height: 1, color: Color(0xFFECEFF1)),
                  const SizedBox(height: 32),

                  // VERIFICHE (Sì/No standard chips)
                  if (isMobile) ...[
                    _YesNoGroup(
                      'Conformità con standard SQNPI',
                      phase.conformitaSqnpi,
                      (val) {
                        setState(() => phase.conformitaSqnpi = val);
                        _saveData();
                      },
                      isReadOnly: widget.isReadOnly,
                    ),
                    const SizedBox(height: 24),
                    _YesNoGroup(
                      'Il prodotto verificato è identificabile e tracciabile',
                      phase.tracciabile,
                      (val) {
                        setState(() => phase.tracciabile = val);
                        _saveData();
                      },
                      isReadOnly: widget.isReadOnly,
                      subtitle:
                          '(Rif. fase processo rintracciabile p.to 16 CL)',
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _YesNoGroup(
                            'Conformità con standard SQNPI',
                            phase.conformitaSqnpi,
                            (val) {
                              setState(() => phase.conformitaSqnpi = val);
                              _saveData();
                            },
                            isReadOnly: widget.isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _YesNoGroup(
                            'Il prodotto verificato è identificabile e tracciabile',
                            phase.tracciabile,
                            (val) {
                              setState(() => phase.tracciabile = val);
                              _saveData();
                            },
                            isReadOnly: widget.isReadOnly,
                            subtitle:
                                '(Rif. fase processo rintracciabile p.to 16 CL)',
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  _ModernTextField(
                    label: 'Note (rev.08)',
                    initialValue: phase.note,
                    icon: Icons.info_outline,
                    isReadOnly: widget.isReadOnly,
                    helpText:
                        '(se una fase del processo è affidato a terzi verificare che sia certificato SQNPI - (rev.08))',
                    helpAsSubtitle: true,
                    maxLines: 2,
                    onChanged: (val) {
                      phase.note = val;
                      _saveData();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        if (!widget.isReadOnly)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  phases.add(PostHarvestPhaseData(fase: ''));
                });
                _saveData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade100, width: 1.5),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'AGGIUNGI ALTRA FASE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMassBalance(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'PROVA BILANCIO DI MASSA',
          subtitle: 'Vino, Olio DOP/IGP o altro prodotto (rev. 08)',
          icon: Icons.scale_outlined,
        ),
        const SizedBox(height: 24),
        ...mbBalances.asMap().entries.map((entry) {
          final index = entry.key;
          final balance = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _CardGroup(
              title: 'BILANCIO #${index + 1}',
              subtitle: 'Specifiche del bilancio per vino, olio o altro',
              trailing: !widget.isReadOnly && mbBalances.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeMassBalance(index),
                    )
                  : null,
              child: Column(
                children: [
                  _ModernTextField(
                    label: 'Prodotti verificati',
                    initialValue: balance.verifiedProducts,
                    icon: Icons.inventory_2_outlined,
                    isReadOnly: widget.isReadOnly,
                    maxLines: 2,
                    helpText: HelpTexts.get('Prodotti verificati'),
                    helpAsSubtitle: true,
                    onChanged: (val) {
                      balance.verifiedProducts = val;
                      _saveData();
                    },
                  ),
                  const SizedBox(height: 24),
                  if (isMobile) ...[
                    _ModernTextField(
                      label: 'Dati in ingresso',
                      initialValue: balance.inputData,
                      icon: Icons.login_rounded,
                      isReadOnly: widget.isReadOnly,
                      maxLines: 4,
                      helpText: HelpTexts.get('Dati in ingresso'),
                      onChanged: (val) {
                        balance.inputData = val;
                        _saveData();
                      },
                    ),
                    const SizedBox(height: 16),
                    _ModernTextField(
                      label: 'Documenti (Ingresso)',
                      initialValue: balance.inputDocs,
                      icon: Icons.receipt_long_outlined,
                      isReadOnly: widget.isReadOnly,
                      maxLines: 4,
                      onChanged: (val) {
                        balance.inputDocs = val;
                        _saveData();
                      },
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ModernTextField(
                            label: 'Dati in ingresso',
                            initialValue: balance.inputData,
                            icon: Icons.login_rounded,
                            isReadOnly: widget.isReadOnly,
                            maxLines: 4,
                            helpText: HelpTexts.get('Dati in ingresso'),
                            onChanged: (val) {
                              balance.inputData = val;
                              _saveData();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModernTextField(
                            label: 'Documenti (Ingresso)',
                            initialValue: balance.inputDocs,
                            icon: Icons.receipt_long_outlined,
                            isReadOnly: widget.isReadOnly,
                            maxLines: 4,
                            onChanged: (val) {
                              balance.inputDocs = val;
                              _saveData();
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (isMobile) ...[
                    _ModernTextField(
                      label: 'Dati in uscita',
                      initialValue: balance.outputData,
                      icon: Icons.logout_rounded,
                      isReadOnly: widget.isReadOnly,
                      maxLines: 4,
                      helpText: HelpTexts.get('Dati in uscita'),
                      onChanged: (val) {
                        balance.outputData = val;
                        _saveData();
                      },
                    ),
                    const SizedBox(height: 16),
                    _ModernTextField(
                      label: 'Documenti (Uscita)',
                      initialValue: balance.outputDocs,
                      icon: Icons.fact_check_outlined,
                      isReadOnly: widget.isReadOnly,
                      maxLines: 4,
                      onChanged: (val) {
                        balance.outputDocs = val;
                        _saveData();
                      },
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ModernTextField(
                            label: 'Dati in uscita',
                            initialValue: balance.outputData,
                            icon: Icons.logout_rounded,
                            isReadOnly: widget.isReadOnly,
                            maxLines: 4,
                            helpText: HelpTexts.get('Dati in uscita'),
                            onChanged: (val) {
                              balance.outputData = val;
                              _saveData();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModernTextField(
                            label: 'Documenti (Uscita)',
                            initialValue: balance.outputDocs,
                            icon: Icons.fact_check_outlined,
                            isReadOnly: widget.isReadOnly,
                            maxLines: 4,
                            onChanged: (val) {
                              balance.outputDocs = val;
                              _saveData();
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  _ModernTextField(
                    label: 'Commento',
                    initialValue: balance.comment,
                    icon: Icons.comment_outlined,
                    isReadOnly: widget.isReadOnly,
                    maxLines: 3,
                    helpText: HelpTexts.get('Commento'),
                    onChanged: (val) {
                      balance.comment = val;
                      _saveData();
                    },
                  ),
                  const SizedBox(height: 32),
                  if (!widget.isReadOnly)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: _saveData,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SALVA BILANCIO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        // Add button styled like in main section
        if (!widget.isReadOnly)
          Center(
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                onTap: _addMassBalance,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF1B5E20),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AGGIUNGI ALTRO BILANCIO',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _CardGroup(
          title: 'ALLEGATI AGGIUNTIVI',
          subtitle:
              'Carica documenti originali per ingresso e uscita (DDT, fatture...)',
          child: Column(
            children: [
              _buildDocSection(
                title: 'Documenti ingresso',
                subtitle: 'Fatture, bolle e altri doc di entrata',
                docType: 'ph_entrata',
                icon: Icons.receipt_long_outlined,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              _buildDocSection(
                title: 'Documenti uscita',
                subtitle: 'Quaderno campagna, DDT e altri doc di uscita',
                docType: 'ph_uscita',
                icon: Icons.receipt_long_outlined,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraceability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'PROVA DI RINTRACCIABILITÀ',
          subtitle: 'Rif. Check-list punto 16.1',
          icon: Icons.track_changes_outlined,
        ),
        const SizedBox(height: 24),
        _CardGroup(
          title: 'DETTAGLI RINTRACCIABILITÀ',
          subtitle:
              'Verifica registrazioni sul SI del SQNPI al fine di garantire la rintracciabilità dei lotti (rev.08)',
          child: _ModernTextFieldWithController(
            label: 'Prodotti verificati',
            controller: _traceabilityVerifiedProductsController,
            icon: Icons.inventory_2_outlined,
            isReadOnly: widget.isReadOnly,
            maxLines: 4,
            helpText: HelpTexts.get('Prova di rintracciabilità'),
            helpAsSubtitle: true,
            onChanged: _saveData,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDocument(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      dialogTitle: docType == 'ph_entrata'
          ? 'Seleziona documenti di ENTRATA (fatture, bolle...)'
          : 'Seleziona documenti di USCITA (quaderno campagna, DDT...)',
    );

    if (result == null || result.files.isEmpty) return;

    final db = ref.read(appDatabaseProvider);

    for (final file in result.files) {
      if (file.path == null) continue;

      final appDir = await getApplicationSupportDirectory();
      final destDir = Directory(
        '${appDir.path}/sqnpi_audit_manager/ph_docs/${widget.visitId}',
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
            '${result.files.length} documento/i allegato/i come ${docType == "ph_entrata" ? "ENTRATA" : "USCITA"}',
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
      '${appDir.path}/sqnpi_audit_manager/ph_docs/${widget.visitId}',
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
            'Foto allegata come ${docType == "ph_entrata" ? "ENTRATA" : "USCITA"}',
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
    final docsProvider = docType == 'ph_entrata'
        ? _phDocsEntrataProvider
        : _phDocsUscitaProvider;
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
                _ActionChip(
                  label: 'CARICA FILE',
                  icon: Icons.upload_file_rounded,
                  onPressed: () => _pickDocument(docType),
                  color: color,
                ),
                _ActionChip(
                  label: 'SCATTA FOTO',
                  icon: Icons.camera_alt_rounded,
                  onPressed: () => _pickImageDocument(docType),
                  color: color,
                ),
              ],
            ),
          const SizedBox(height: 16),
          docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Errore caricamento doc: $err'),
            data: (docs) {
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: Colors.grey.shade300,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nessun documento allegato',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: docs.map((doc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _fileIconForName(doc.fileName),
                          color: Colors.blueGrey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: InkWell(
                            onTap: () => OpenFilex.open(doc.filePath),
                            child: Text(
                              doc.fileName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263238),
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (!widget.isReadOnly)
                          IconButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: const Text(
                                    'Elimina Documento',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  content: Text(
                                    'Vuoi eliminare "${doc.fileName}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('ANNULLA'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('ELIMINA'),
                                    ),
                                  ],
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
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPostHarvestGrid(isMobile),
          const SizedBox(height: 24),
          _buildMassBalance(isMobile),
          const SizedBox(height: 24),
          _buildTraceability(),
          // Padding per la tastiera
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade700.withValues(alpha: 0.2),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.blueGrey.shade600,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _CardGroup({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (subtitle case final s?)
                      Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
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
                blurRadius: 15,
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

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final bool isReadOnly;
  final int maxLines;
  final String? helpText;
  final bool helpAsSubtitle;

  const _ModernTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.icon,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.helpText,
    this.helpAsSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: Colors.teal.shade700),
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
            if (helpText != null) ...[
              const SizedBox(width: 4),
              HelpTooltip(text: helpText!, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF37474F)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
            ),
            hoverColor: Colors.teal.shade50.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _YesNoGroup extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool isReadOnly;
  final String? subtitle;

  const _YesNoGroup(
    this.label,
    this.value,
    this.onChanged, {
    this.isReadOnly = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ChoiceChip(
              label: 'Sì',
              selected: value == true,
              color: Colors.green,
              onSelected: isReadOnly ? null : (_) => onChanged(true),
            ),
            _ChoiceChip(
              label: 'No',
              selected: value == false,
              color: Colors.red,
              onSelected: isReadOnly ? null : (_) => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final ValueChanged<bool>? onSelected;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.color,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected != null ? () => onSelected!(true) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ModernTextFieldWithController extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isReadOnly;
  final int maxLines;
  final String? helpText;
  final bool helpAsSubtitle;
  final VoidCallback? onChanged;

  const _ModernTextFieldWithController({
    required this.label,
    required this.controller,
    required this.icon,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.helpText,
    this.helpAsSubtitle = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: Colors.teal.shade700),
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
            if (helpText != null && !helpAsSubtitle) ...[
              const SizedBox(width: 4),
              HelpTooltip(text: helpText!, size: 14),
            ],
          ],
        ),
        if (helpText != null && helpAsSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            helpText!,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey.shade600,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged?.call(),
          readOnly: isReadOnly,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF37474F)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
            ),
            hoverColor: Colors.teal.shade50.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
