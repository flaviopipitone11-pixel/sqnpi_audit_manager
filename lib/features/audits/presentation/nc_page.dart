import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/widgets/radio_group.dart';

final nonConformitaByVisitProvider =
    StreamProvider.family<
      List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>,
      String
    >((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchNonConformitaByVisit(visitId);
    });

final visitClosingProvider = StreamProvider.family<VisitClosing?, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchClosingByVisitId(visitId);
});

class NcPage extends ConsumerWidget {
  const NcPage({super.key, required this.visitId, this.isReadOnly = false});
  final String visitId;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ncAsync = ref.watch(nonConformitaByVisitProvider(visitId));
    final closingAsync = ref.watch(visitClosingProvider(visitId));

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Non Conformità (NC)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Riepilogo delle non conformità rilevate durante la visita.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ncAsync.when(
                        data: (ncs) {
                          if (ncs.isEmpty) {
                            return _EmptyNcPlaceholder();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [...ncs.map((nc) => _NcCard(nc: nc))],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Errore: $e')),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),
                      closingAsync.when(
                        data: (closing) => _AdministrativeSummary(
                          visitId: visitId,
                          closing: closing,
                          isReadOnly: isReadOnly,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text('Errore: $e')),
                      ),
                      const SizedBox(height: 100), // Space for scrolling
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNcPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna Non Conformità rilevata!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Compila la checklist per registrare eventuali NC.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _NcCard extends StatelessWidget {
  final ({ChecklistResponse response, ChecklistItem item, VisitUec uec}) nc;

  const _NcCard({required this.nc});

  @override
  Widget build(BuildContext context) {
    final item = nc.item;
    final resp = nc.response;
    final uec = nc.uec;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Requisito KO',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'UEC: Agg. ${uec.nAggregato} (${uec.coltura})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${item.code} — ${item.obbligo}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.warning_amber_rounded,
              title: 'Livello KO',
              value: resp.livelloKo?.toString() ?? 'Non specificato',
            ),
            if (resp.punteggioUec != null)
              _DetailRow(
                icon: Icons.score,
                title: 'Punteggio KO UEC/Lotto',
                value: resp.punteggioUec.toString(),
              ),
            if (resp.punteggioOperatore != null)
              _DetailRow(
                icon: Icons.person_off,
                title: 'Punteggio KO Operatore',
                value: resp.punteggioOperatore.toString(),
              ),
            _DetailRow(
              icon: Icons.speaker_notes,
              title: 'Descrizione',
              value: resp.rilievoNc.isNotEmpty
                  ? resp.rilievoNc
                  : 'Nessuna descrizione inserita',
            ),
            _DetailRow(
              icon: Icons.note_alt_outlined,
              title: 'Azione correttiva',
              value: resp.note.isNotEmpty
                  ? resp.note
                  : 'Nessuna azione correttiva inserita',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdministrativeSummary extends ConsumerStatefulWidget {
  final String visitId;
  final VisitClosing? closing;
  final bool isReadOnly;

  const _AdministrativeSummary({
    required this.visitId,
    this.closing,
    required this.isReadOnly,
  });

  @override
  _AdministrativeSummaryState createState() => _AdministrativeSummaryState();
}

class _AdministrativeSummaryState
    extends ConsumerState<_AdministrativeSummary> {
  late TextEditingController _notesController;
  late TextEditingController _cropsController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.closing?.verificationNotes ?? '',
    );
    _cropsController = TextEditingController(
      text: widget.closing?.cap5SpecificCrops ?? '',
    );
  }

  @override
  void didUpdateWidget(_AdministrativeSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.closing?.verificationNotes !=
            oldWidget.closing?.verificationNotes &&
        !FocusScope.of(context).hasFocus) {
      _notesController.text = widget.closing?.verificationNotes ?? '';
    }
    if (widget.closing?.cap5SpecificCrops !=
            oldWidget.closing?.cap5SpecificCrops &&
        !FocusScope.of(context).hasFocus) {
      _cropsController.text = widget.closing?.cap5SpecificCrops ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cropsController.dispose();
    super.dispose();
  }

  void _saveField(String field, dynamic value) {
    if (widget.isReadOnly) return;
    final db = ref.read(appDatabaseProvider);

    final current = widget.closing;
    db.upsertClosing(
      visitId: widget.visitId,
      correctiveActions: current?.correctiveActions ?? '',
      resolutionDeadline: field == 'resolutionDeadline'
          ? value
          : current?.resolutionDeadline,
      isClosed: current?.isClosed ?? false,
      cap5Adherence: field == 'cap5Adherence' ? value : current?.cap5Adherence,
      cap5SpecificCrops: field == 'cap5SpecificCrops'
          ? value
          : current?.cap5SpecificCrops,
      commitmentToRectify: field == 'commitmentToRectify'
          ? value
          : current?.commitmentToRectify,
      inspectionMethods: field == 'inspectionMethods'
          ? value
          : current?.inspectionMethods,
      representativePresent: field == 'representativePresent'
          ? value
          : current?.representativePresent,
      isOutcomeFormalized: field == 'isOutcomeFormalized'
          ? value
          : current?.isOutcomeFormalized,
      verificationNotes: field == 'verificationNotes'
          ? value
          : current?.verificationNotes,
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final now = DateTime.now();
    DateTime tempDate =
        (widget.closing?.resolutionDeadline != null &&
            widget.closing!.resolutionDeadline!.isAfter(now))
        ? widget.closing!.resolutionDeadline!
        : now;

    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scegli Data Risoluzione',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: const Color(0xFF2D6A4F),
                      onPrimary: Colors.white,
                      onSurface: Colors.grey.shade800,
                      surface: Colors.white,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2D6A4F),
                      ),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: tempDate.isBefore(now) ? now : tempDate,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 7)),
                    onDateChanged: (date) {
                      tempDate = date;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Conferma Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedDate != null) {
      _saveField('resolutionDeadline', selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closing = widget.closing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Integrazione Amministrativa (M904 Rev. 08)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 24),

        AdministrativeSection(
          title:
              'Rispetto del Cap. 5 Procedura di adesione, gestione e controllo SQNPI: *',
          child: Column(
            children: [
              CustomRadioGroup<int>(
                groupValue: closing?.cap5Adherence ?? 0,
                onChanged: (v) => _saveField('cap5Adherence', v),
                child: Column(
                  children: [
                    const CustomRadioOption(
                      label: 'Sì per tutte le colture verificate',
                      value: 1,
                    ),
                    const CustomRadioOption(
                      label: 'No per le seguenti colture:',
                      value: 2,
                    ),
                  ],
                ),
              ),
              if ((closing?.cap5Adherence ?? 0) == 2)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 8),
                  child: TextField(
                    controller: _cropsController,
                    decoration: const InputDecoration(
                      hintText: 'Specificare colture...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _saveField('cap5SpecificCrops', v),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        AdministrativeSection(
          title:
              'L\'azienda si impegna a rettificare la domanda per coreeggere eventuali incoerenze tra domanda,fascicolo',
          child: Column(
            children: [
              CustomRadioGroup<int>(
                groupValue: closing?.commitmentToRectify ?? 0,
                onChanged: (v) => _saveField('commitmentToRectify', v),
                child: Column(
                  children: [
                    const CustomRadioOption(label: 'N/A', value: 0),
                    const CustomRadioOption(
                      label: 'Sì entro il (massimo 7 giorni):',
                      value: 1,
                    ),
                    if ((closing?.commitmentToRectify ?? 0) == 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: InkWell(
                          onTap: widget.isReadOnly
                              ? null
                              : () => _showCustomDatePicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2D6A4F,
                              ).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF2D6A4F,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Color(0xFF2D6A4F),
                                ),
                                const SizedBox(width: 12),
                                Builder(
                                  builder: (context) {
                                    final deadline =
                                        closing?.resolutionDeadline;
                                    return Text(
                                      deadline != null
                                          ? '${deadline.day}/${deadline.month}/${deadline.year}'
                                          : 'Scegli data entro 7 giorni',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: deadline != null
                                            ? const Color(0xFF2D6A4F)
                                            : Colors.grey.shade600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const CustomRadioOption(label: 'No', value: 2),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        AdministrativeSection(
          title: 'La presente visita ispettiva è stata eseguita mediante: *',
          child: _MetodiIspezione(
            selectedJson: closing?.inspectionMethods ?? '[]',
            onChanged: (v) => _saveField('inspectionMethods', v),
            isReadOnly: widget.isReadOnly,
          ),
        ),

        const SizedBox(height: 24),
        AdministrativeSection(
          title: 'Presenza del titolare o suo rappresentante *',
          child: CustomRadioGroup<int>(
            groupValue: closing?.representativePresent ?? 0,
            onChanged: (v) => _saveField('representativePresent', v),
            child: const Column(
              children: [
                CustomRadioOption(label: 'Sì', value: 1),
                CustomRadioOption(label: 'No', value: 2),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        CheckboxListTile(
          title: const Text(
            'L\'esito della verifica è stato formalizzato alla presenza del titolare/rappresentante legale dell\'Organizzazione (o suo delegato) che sottoscrive il presente report di verifica ispettiva',
          ),
          value: closing?.isOutcomeFormalized ?? false,
          onChanged: widget.isReadOnly
              ? null
              : (v) => _saveField('isOutcomeFormalized', v),
          controlAffinity: ListTileControlAffinity.leading,
        ),

        const SizedBox(height: 24),
        const Text(
          'Note di verifica (di approfondimento/spiegazione) su quanto rilevato nel corso dell\'ispezione',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 5,
          enabled: !widget.isReadOnly,
          decoration: const InputDecoration(
            hintText: 'Inserire note di verifica...',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _saveField('verificationNotes', v),
        ),
      ],
    );
  }
}

class AdministrativeSection extends StatelessWidget {
  final String title;
  final Widget child;

  const AdministrativeSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// RadioOption is now imported from shared widgets.

class _MetodiIspezione extends StatelessWidget {
  final String selectedJson;
  final ValueChanged<String> onChanged;
  final bool isReadOnly;

  const _MetodiIspezione({
    required this.selectedJson,
    required this.onChanged,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      'Interviste al personale aziendale sul luogo di lavoro durante la produzione',
      'Osservazione dei siti, dei processi e dei siti dell\'organizzazione ',
      'Visione di documentazione, procedure e registrazioni',
    ];
    return Column(
      children: methods.map((m) {
        final isSelected = selectedJson.contains(m);
        return CheckboxListTile(
          title: Text(m),
          value: isSelected,
          onChanged: isReadOnly
              ? null
              : (v) {
                  List<String> current;
                  try {
                    final decoded = jsonDecode(selectedJson);
                    if (decoded is List) {
                      current = decoded.map((e) => e.toString()).toList();
                    } else {
                      current = [];
                    }
                  } catch (_) {
                    current = [];
                  }

                  if (v == true) {
                    if (!current.contains(m)) {
                      current.add(m);
                    }
                  } else {
                    current.remove(m);
                  }
                  onChanged(jsonEncode(current));
                },
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
