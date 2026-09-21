import 'package:flutter/material.dart';

/// Rappresenta una singola formula standard con categoria e icona tematica.
class NotePresetItem {
  final String text;
  final String category;
  final IconData icon;

  const NotePresetItem({
    required this.text,
    required this.category,
    required this.icon,
  });
}

/// Frasi predefinite e formule standard per la compilazione della checklist SQNPI.
class ChecklistNotePresets {
  ChecklistNotePresets._();

  /// Suggerimenti strutturati per note quando l'esito è "Non Applicabile" (NA)
  static const List<NotePresetItem> naItems = [
    NotePresetItem(
      text: 'Specie/coltura non soggetta al requisito di norma',
      category: 'Colture',
      icon: Icons.eco_outlined,
    ),
    NotePresetItem(
      text: 'Fase post-raccolta non presente in azienda',
      category: 'Post-raccolta',
      icon: Icons.warehouse_outlined,
    ),
    NotePresetItem(
      text: 'Nessun trattamento fitosanitario eseguito nell\'annata',
      category: 'Trattamenti',
      icon: Icons.shield_outlined,
    ),
    NotePresetItem(
      text: 'Attrezzatura non posseduta (lavorazioni delegate a contoterzista)',
      category: 'Attrezzature',
      icon: Icons.agriculture_outlined,
    ),
    NotePresetItem(
      text: 'Irrigazione non praticata nell\'annata agraria',
      category: 'Irrigazione',
      icon: Icons.water_drop_outlined,
    ),
    NotePresetItem(
      text: 'Nessun acquisto di materiale di propagazione nell\'anno',
      category: 'Acquisti',
      icon: Icons.local_florist_outlined,
    ),
    NotePresetItem(
      text: 'Azienda priva di magazzino / stoccaggio proprio',
      category: 'Magazzino',
      icon: Icons.store_mall_directory_outlined,
    ),
    NotePresetItem(
      text: 'Nessuna cessione o vendita registrata nel periodo',
      category: 'Vendite',
      icon: Icons.receipt_long_outlined,
    ),
    NotePresetItem(
      text:
          'Azienda a conduzione diretta senza dipendenti o manodopera salariata',
      category: 'Personale',
      icon: Icons.people_outline_rounded,
    ),
    NotePresetItem(
      text:
          'Diserbo chimico non praticato (solo gestione meccanica/inerbimento)',
      category: 'Trattamenti',
      icon: Icons.grass_outlined,
    ),
  ];

  /// Formule standard per Rilievi di Non Conformità (KO)
  static const List<NotePresetItem> koRilievoItems = [
    NotePresetItem(
      text:
          'Mancata registrazione delle operazioni colturali/trattamenti entro i termini previsti',
      category: 'Registri',
      icon: Icons.edit_calendar_outlined,
    ),
    NotePresetItem(
      text:
          'Assenza di attestato di controllo funzionale/taratura dell\'irroratrice in corso di validità',
      category: 'Attrezzature',
      icon: Icons.build_circle_outlined,
    ),
    NotePresetItem(
      text:
          'Fatture di acquisto o documenti di trasporto (DDT) non reperibili in sede di audit',
      category: 'Documentazione',
      icon: Icons.receipt_long_rounded,
    ),
    NotePresetItem(
      text:
          'Incompleta compilazione del registro dei trattamenti (mancano dosi/avversità/date)',
      category: 'Registri',
      icon: Icons.playlist_remove_rounded,
    ),
    NotePresetItem(
      text:
          'Trattamento fitosanitario eseguito con prodotto non ammesso dal disciplinare di produzione integrata',
      category: 'Disciplinare',
      icon: Icons.warning_amber_rounded,
    ),
    NotePresetItem(
      text:
          'Mancata corrispondenza tra superficie catastale e superficie effettivamente impegnata SQNPI',
      category: 'Superfici',
      icon: Icons.map_outlined,
    ),
    NotePresetItem(
      text:
          'Giacenze di magazzino non corrispondenti alle registrazioni di carico e scarico',
      category: 'Magazzino',
      icon: Icons.inventory_2_outlined,
    ),
    NotePresetItem(
      text:
          'Mancata conservazione dei cartellini/passaporti delle piante acquistate',
      category: 'Materiale vivaistico',
      icon: Icons.local_florist_outlined,
    ),
    NotePresetItem(
      text:
          'Superamento del numero massimo di interventi consentiti dal disciplinare per la sostanza attiva',
      category: 'Disciplinare',
      icon: Icons.pest_control_rounded,
    ),
    NotePresetItem(
      text:
          'Mancata effettuazione dell\'analisi delle acque di lavaggio/irrigazione prevista',
      category: 'Analisi',
      icon: Icons.water_drop_outlined,
    ),
  ];

  /// Formule standard per Azioni Correttive (KO)
  static const List<NotePresetItem> koAzioneItems = [
    NotePresetItem(
      text:
          'Aggiornamento tempestivo del registro dei trattamenti entro i termini concordati',
      category: 'Registri',
      icon: Icons.check_circle_outline_rounded,
    ),
    NotePresetItem(
      text:
          'Esecuzione del controllo funzionale dell\'irroratrice e trasmissione dell\'attestato all\'OdC',
      category: 'Attrezzature',
      icon: Icons.published_with_changes_rounded,
    ),
    NotePresetItem(
      text:
          'Reperimento e trasmissione della documentazione contabile mancante entro 10 giorni',
      category: 'Documentazione',
      icon: Icons.forward_to_inbox_rounded,
    ),
    NotePresetItem(
      text:
          'Riconciliazione delle giacenze di magazzino e aggiornamento delle schede di carico/scarico',
      category: 'Magazzino',
      icon: Icons.inventory_outlined,
    ),
    NotePresetItem(
      text:
          'Aggiornamento del fascicolo aziendale e adeguamento delle superfici nel piano colturale',
      category: 'Superfici',
      icon: Icons.folder_shared_outlined,
    ),
    NotePresetItem(
      text:
          'Sospensione dell\'uso di prodotti non conformi e rispetto scrupoloso dei vincoli di disciplinare',
      category: 'Disciplinare',
      icon: Icons.block_rounded,
    ),
    NotePresetItem(
      text:
          'Formalizzazione della procedura di archiviazione dei cartellini del materiale vivaistico',
      category: 'Materiale vivaistico',
      icon: Icons.archive_outlined,
    ),
  ];

  /// Elenchi stringhe per retrocompatibilità
  static List<String> get naPresets => naItems.map((e) => e.text).toList();
  static List<String> get koRilievoPresets =>
      koRilievoItems.map((e) => e.text).toList();
  static List<String> get koAzionePresets =>
      koAzioneItems.map((e) => e.text).toList();

  /// Inserisce o appende un preset al controller di testo corrente, gestendo la formattazione.
  static void applyPreset(TextEditingController controller, String preset) {
    final current = controller.text.trim();
    if (current.isEmpty) {
      controller.text = preset;
    } else {
      if (current.toLowerCase().contains(preset.toLowerCase())) {
        return;
      }
      if (current.endsWith('.') ||
          current.endsWith(';') ||
          current.endsWith('\n')) {
        controller.text = '$current\n$preset';
      } else {
        controller.text = '$current; $preset';
      }
    }
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }
}
