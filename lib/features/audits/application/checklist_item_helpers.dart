import '../../../core/storage/app_database.dart';

class ChecklistItemHelpers {
  static String? getIndicazioniOdc(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode;

    if (code == '0.1' ||
        code == '0.2' ||
        code == '0.3' ||
        code == '0.4' ||
        code == '0.5' ||
        code == '0.6' ||
        code == '0.8' ||
        code == '0.9' ||
        code == '0.10' ||
        code == '0.11' ||
        code == '0.12' ||
        code == '0.13' ||
        code == '1.1' ||
        code == '1.2.1' ||
        code == '1.2.2' ||
        code == '1.3' ||
        code == '1.4' ||
        code == '1.6' ||
        code == '1.7' ||
        code == '1.8' ||
        code == '1.9' ||
        code == '1.10' ||
        code == '1.11' ||
        code == '3.1' ||
        code == '3.2' ||
        code == '4.2' ||
        code == '4.3' ||
        displayCode.startsWith('4.5.1') ||
        displayCode.startsWith('4.5.2') ||
        displayCode.startsWith('4.6') ||
        displayCode.startsWith('5.1') ||
        displayCode.startsWith('5.2') ||
        displayCode.startsWith('5.3') ||
        displayCode.startsWith('5.4') ||
        displayCode.startsWith('6.1') ||
        displayCode.startsWith('6.2') ||
        displayCode.startsWith('6.3') ||
        displayCode.startsWith('6.4') ||
        displayCode.startsWith('7.1') ||
        displayCode.startsWith('8.1.1') ||
        displayCode.startsWith('8.1.2') ||
        displayCode.startsWith('8.2.3') ||
        displayCode.startsWith('8.2.4') ||
        displayCode.startsWith('8.2.5') ||
        displayCode.startsWith('8.2.6') ||
        displayCode.startsWith('8.3') ||
        displayCode.startsWith('8.4') ||
        displayCode.startsWith('9.2') ||
        displayCode.startsWith('10.1') ||
        displayCode.startsWith('10.2') ||
        displayCode.startsWith('10.3') ||
        displayCode.startsWith('10.4') ||
        displayCode.startsWith('10.5.1') ||
        displayCode.startsWith('10.5.2') ||
        displayCode.startsWith('11.1') ||
        displayCode.startsWith('11.2') ||
        displayCode.startsWith('11.3') ||
        displayCode.startsWith('12.1') ||
        displayCode.startsWith('12.2') ||
        displayCode.startsWith('12.3') ||
        displayCode.startsWith('13.1') ||
        displayCode.startsWith('13.2') ||
        displayCode.startsWith('14.0') ||
        displayCode.startsWith('14.1') ||
        displayCode.startsWith('14.2') ||
        displayCode.startsWith('14.4') ||
        displayCode.startsWith('15.1') ||
        displayCode.startsWith('15.4') ||
        displayCode.startsWith('15.5') ||
        displayCode.startsWith('15.6') ||
        displayCode.startsWith('15.7') ||
        displayCode.startsWith('15.8') ||
        displayCode.startsWith('15.9') ||
        displayCode.startsWith('15.10') ||
        displayCode.startsWith('15.11') ||
        displayCode.startsWith('15.12') ||
        displayCode.startsWith('15.13') ||
        displayCode.startsWith('15.14') ||
        displayCode.startsWith('15.15') ||
        displayCode.startsWith('16.1') ||
        displayCode.startsWith('16.2') ||
        displayCode.startsWith('16.3') ||
        displayCode.startsWith('16.4') ||
        displayCode.startsWith('17.1') ||
        displayCode.startsWith('17.2') ||
        displayCode.startsWith('17.3') ||
        displayCode.startsWith('17.4') ||
        displayCode.startsWith('17.7') ||
        displayCode.startsWith('17.8') ||
        displayCode.startsWith('17.10')) {
      return code == '0.3'
          ? 'verificare presenza delle registrazioni e riportare ultima fertilizzazione registrata'
          : code == '0.4'
          ? 'verificare presenza delle registrazioni e riportare ultima operazione colturale registrata'
          : code == '0.5'
          ? 'verificare presenza e corretta conservazione'
          : code == '0.6'
          ? 'verificare presenza delle registrazioni e riportare ultima registrazione di magazzino effettuata'
          : code == '0.8'
          ? "Sono ammessi ritardi solo per problemi tecnici indipendenti dalla volonta' del richiedente  (cap.5)"
          : code == '0.9'
          ? 'verificare eventuali variazioni intervenute dopo il rilascio della domanda di adesione (cessione/inserimento terreni, modifiche dei processi…)'
          : code == '0.10'
          ? 'per le colture Avvicendate non è NC ma serve aggiornamento del fascicolo aziendale e raccolta evidenza.'
          : code == '0.11'
          ? "verificare se in domanda di adesione sono presenti terreni non condotti dall'azienda o con colture non riscontrate in azienda."
          : code == '0.12'
          ? 'verificare in Biosfera pagamento quote anni precedenti o quota fissa se prevista'
          : code == '0.13'
          ? 'verificare presenza del cartello Osservatorio SQNPI (secondo il modello pubblicato in SIAN) presso il centro aziendale in posizione visibile a terzi, eventuale pubblicità sul sito web…'
          : code == '1.1'
          ? "riportare evidenza di almeno 1 trattamento per coltura presente in domanda (Coltura, superficie, data trattamento, prodotto utilizzato, avversita', dose impiegata  (non dose/ha) )"
          : (code == '1.2.1' || code == '1.3' || code == '1.6' || code == '1.7')
          ? 'riportare esempio quale evidenza di verifica'
          : code == '1.2.2'
          ? 'In caso di prelievo campione la conformità al requisito sarà valitata da Bios sede centrale al ricevimento del RDP'
          : code == '1.4'
          ? 'Effettuare bilancio di massa su almeno due sostanze attive considerando anche le scorte di magazzino ( è possibile utilizzare sezione bilancio di massa presente in M904)'
          : code == '1.8'
          ? "verificare le modalità di monitoraggio adottate dall'operatore e riportarle"
          : code == '1.9'
          ? 'verificare il rispetto dei volumi di acqua/ha utilizzati per i trattamenti. Riportare esempio'
          : code == '1.10'
          ? 'Verificare la presenza del Certificato attestante il Controllo funzionale e la Regolazione strumentale  (macchina/attrezzatura, n°cert, validità dal_ al_ ) degli atomizzatori/botti/barre in uso. -  riportare evidenza'
          : code == '1.11'
          ? 'Indicare il/i soggetto/i in possesso del Patentino Fitosanitario e riportare estremi del docum. ( valido dal_ al_ )'
          : code == '3.1'
          ? "verificare e descrivere gli interventi effettuati dall'operatore per rafforzare la biodiversità"
          : code == '3.2'
          ? 'verificare le registrazioni (acquisto/utilizzo prodotti su tali aree se del caso con BM)'
          : code == '4.2'
          ? 'riportare esempio varietà utilizzate'
          : code == '4.3'
          ? 'verificare DPI se prevede "liste varietali"'
          : (displayCode == '4.5.2' || code == '4.5.1')
          ? "verificare documenti fiscali e i certificati relativi a nuovi impianti effettuati"
          : (displayCode == '4.5.1' || code == '4.5')
          ? "verificare documenti fiscali e i certificati relativi all'acquisto di semente e piantine orticole"
          : (displayCode == '4.6' || code == '4.5.2')
          ? "verificare se l'operatore ricorre all'autoproduzione"
          : (displayCode.startsWith('5.1') ||
                displayCode.startsWith('5.2') ||
                displayCode.startsWith('5.3') ||
                displayCode.startsWith('5.4'))
          ? 'Commento'
          : (displayCode.startsWith('6.1') || displayCode.startsWith('6.2'))
          ? 'verificare regola rotazione prevista dalle Norme Tecniche del DPI regionale. Riportare esempio di rotazione applicata (considerare almento 4 anni se applicabile)'
          : (displayCode.startsWith('6.3') || displayCode.startsWith('8.4'))
          ? 'verificare se DPI prevede ulteriori disposizioni'
          : displayCode.startsWith('6.4')
          ? 'verificare se DPI prevede ulteriori disposizioni in merito a REIMPIANTO colture Arboree'
          : displayCode.startsWith('7.1')
          ? 'verificare se DPI prevede vincoli specifici per semina, trapianto e impianto. Se sì riportare evidenza controllo'
          : (displayCode.startsWith('8.1.1') || displayCode.startsWith('8.2.3'))
          ? "riportare tecniche di lavorazione adottate dall'operatore"
          : (displayCode.startsWith('8.1.2') ||
                displayCode.startsWith('8.2.6') ||
                displayCode.startsWith('8.3'))
          ? "riportare tecniche di lavorazione adottate dall'operatore (es. rispetto inerbimento o altre lavorazioni previste da DPI)"
          : displayCode.startsWith('8.2.4')
          ? "riportare sistemi di protezione del suolo dall'erosione adottati dall'operatore"
          : displayCode.startsWith('8.2.5')
          ? "riportare eventuali sistemi di protezione del suolo dall'erosione alternativi adottati dall'operatore"
          : displayCode.startsWith('9.2')
          ? "tecniche adottate dall'operatore, ricorso a fitoregolatori ammessi (riportare evidenza)"
          : (displayCode == '10.1' || displayCode.startsWith('10.1.'))
          ? 'Riportare evidenza di verifica quali riferimenti al piano di concimazione o alle schede dosi standard impiegate. Devono essere presenti in azienda assieme alle analisi del suolo'
          : (displayCode == '10.2' || displayCode.startsWith('10.2.'))
          ? 'Effettuare bilancio di massa concimazioni. Verifica incrociata con scheda magazzino fertilizzanti, quaderno di campagna'
          : (displayCode == '10.3' || displayCode.startsWith('10.3.'))
          ? 'Se fertilizzazione organica, verificare rispetto limiti 170 kg N/ha annui. Fare bilancio di massa.'
          : (displayCode == '10.4' || displayCode.startsWith('10.4.'))
          ? 'verificare registro fertilizzazione e riportare esempio'
          : (displayCode == '10.5.1' ||
                displayCode.startsWith('10.5.1.') ||
                displayCode == '10.5.2' ||
                displayCode.startsWith('10.5.2.'))
          ? 'Fornire evidenza analisi suolo per aree omogenee (estremi del Rdp, validità, area omogenea di riferimento ) o riferimenti a carte dei suoli'
          : (displayCode == '11.1' || displayCode.startsWith('11.1.'))
          ? 'verifica registro irrigazioni: riportare esempio volumi di irrigazione impiegati e loro rispetto ai massimali previsti da DPI'
          : (displayCode == '11.2' || displayCode.startsWith('11.2.'))
          ? 'riportare il metodo di irrigazione adottato dall\'operatore'
          : (displayCode == '11.3' || displayCode.startsWith('11.3.'))
          ? 'se richiesti da DPI : analisi delle acque'
          : (displayCode == '12.1' || displayCode.startsWith('12.1.'))
          ? 'per le colture fuori suolo: riportare evidenze come da campo NOTE'
          : (displayCode == '12.2' || displayCode.startsWith('12.2.'))
          ? 'per le colture in serra riportare evidenze come campo NOTE'
          : (displayCode == '12.3' || displayCode.startsWith('12.3.'))
          ? 'per fungaie verificare se ulteriori vincoli da DPI'
          : (displayCode == '13.1' || displayCode.startsWith('13.1.'))
          ? 'Se previsti da DPI: per le aziende oggetto di verifica: almeno 2 schede di cui una del prodotto più rappresentativo in termini di superficie (vedi campo NOTE)'
          : (displayCode == '13.2' || displayCode.startsWith('13.2.'))
          ? 'Se previsti da DPI:riportare evidenza controlli come campo NOTE'
          : (displayCode == '14.0' || displayCode.startsWith('14.0.'))
          ? 'riportare evidenza dell\'autocontrollo effettuato (registrazioni autocontrollo del…, n° soci.)'
          : (displayCode == '14.1' || displayCode.startsWith('14.1.'))
          ? 'riportare n° di analisi effettuate in autocontrollo in relazione al campione previsto'
          : (displayCode == '14.2' || displayCode.startsWith('14.2.'))
          ? 'riportare evidenza di gestione lotti Non conformi a seguito di analisi'
          : (displayCode == '14.4' || displayCode.startsWith('14.4.'))
          ? 'riportare evidenza di gestione Non conformità a seguito di autocontrollo'
          : (displayCode == '15.1' || displayCode.startsWith('15.1.'))
          ? 'riportare esempio di trattamento post raccolta effettuato dall\'operatore'
          : (displayCode == '15.4' || displayCode.startsWith('15.4.'))
          ? 'rispetto RMA'
          : (displayCode == '15.5' || displayCode.startsWith('15.5.'))
          ? 'Per prodotti trasformati : 95 % delle materie prime devono essere SQNPI, nel 5%rientrano  ingredienti non reperibili SQ sul mercato e il saccarosio.'
          : (displayCode == '15.6' ||
                displayCode.startsWith('15.6.') ||
                displayCode == '15.7' ||
                displayCode.startsWith('15.7.'))
          ? 'Riportare estremi del piano triennale ed evidenza aggiornamento.  - descrizione dei singoli punti oggetto di controllo'
          : (displayCode == '15.8' || displayCode.startsWith('15.8.'))
          ? 'verifica registrazione consumi: riportare evidenza di verifica.'
          : (displayCode == '15.9' ||
                displayCode.startsWith('15.9.') ||
                displayCode == '15.10' ||
                displayCode.startsWith('15.10.') ||
                displayCode == '15.11' ||
                displayCode.startsWith('15.11.'))
          ? 'Riportare estremi del piano triennale ed evidenza aggiornamento.  - descrizione misure adottate'
          : (displayCode == '15.12' || displayCode.startsWith('15.12.'))
          ? 'commento obbligatorio'
          : (displayCode == '15.13' || displayCode.startsWith('15.13.'))
          ? 'commento obbligatorio:    attenzione, certificato del casellario giudiziale obbligatorio (vedi campo NOTE)'
          : (displayCode == '15.14' || displayCode.startsWith('15.14.'))
          ? 'commento obbligatorio - riportare estremi doc'
          : (displayCode == '15.15' || displayCode.startsWith('15.15.'))
          ? 'commento obbligatorio: riportare informazioni relative agli ultimi corsi effettuati'
          : (displayCode == '16.1' || displayCode.startsWith('16.1.'))
          ? 'Obbligatorio: Fornire evidenza caricamento dati sul SI per un lotto a scelta (per settore vitivinicolo e olivicolo vedi campo NOTE)'
          : (displayCode == '16.2' || displayCode.startsWith('16.2.'))
          ? 'prova di rintracciabilità (registri, documenti fiscali) su almeno un lotto di prodotto'
          : (displayCode == '16.3' || displayCode.startsWith('16.3.'))
          ? 'effettuare Bilancio di massa di un lotto di prodotto secondo quanto previsto da  (vedi campo OBBLIGHI)'
          : (displayCode == '16.4' || displayCode.startsWith('16.4.'))
          ? 'commento obbligatorio'
          : ({'17.1', '17.2', '17.3', '17.4', '17.7', '17.8'}.contains(code) ||
                {
                  '17.1',
                  '17.2',
                  '17.3',
                  '17.4',
                  '17.7',
                  '17.8',
                }.contains(displayCode))
          ? 'Evidenza verifica n° di lotti secondo quanto previsto da (vedi campo FREQUENZA OPERATORE SINGOLO)'
          : (displayCode == '17.10' || displayCode.startsWith('17.10.'))
          ? 'verificare in Biosfera pagamento quote anni precedenti o quota fissa se prevista'
          : 'verificare presenza delle registrazioni e riportare ultimo trattamento registrato';
    }
    return null;
  }

  static String? getEsclSospText(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    // 0.9, 0.10 e 0.13 non hanno alcuna esclusione o sospensione
    if (code == '0.10' ||
        displayCode == '0.10' ||
        displayCode.startsWith('0.10.') ||
        code == '0.13' ||
        displayCode == '0.13' ||
        displayCode.startsWith('0.13.') ||
        code == '0.9' ||
        displayCode == '0.9') {
      return null;
    }

    // 0.1, 0.2 e 12.2: Esclusione lotto in caso di assenza completa delle registrazioni
    if (code == '0.1' ||
        displayCode == '0.1' ||
        displayCode.startsWith('0.1.') ||
        code == '0.2' ||
        displayCode == '0.2' ||
        displayCode.startsWith('0.2.') ||
        code == '12.2' ||
        displayCode == '12.2' ||
        displayCode.startsWith('12.2.')) {
      return "SI' (esclusione lotto) in caso di assenza completa delle registrazioni";
    }

    // 0.8: Sospensione operatore
    if (code == '0.8' ||
        displayCode == '0.8' ||
        displayCode.startsWith('0.8.')) {
      return 'Sospensione operatore ai fini della certificazione (marchio) - Sospensione operatore ai fini della conformità ACA (per ACA relativa alla SRA01 solo nel caso di domanda di adesione - primo anno di impegno).';
    }

    // 0.11: Esclusione UEC in caso di mancata AC o intervento Odc
    if (code == '0.11' ||
        displayCode == '0.11' ||
        displayCode.startsWith('0.11.')) {
      return 'esclusione UEC in caso di mancata AC o intervento Odc';
    }

    // 0.12 e 17.10: Sospensione
    if (code == '0.12' ||
        displayCode == '0.12' ||
        displayCode.startsWith('0.12.') ||
        code == '17.10' ||
        displayCode == '17.10' ||
        displayCode.startsWith('17.10.')) {
      return 'Sospensione';
    }

    // 14.0, 14.1, 14.2, 14.4: Sospensione OA
    if (code == '14.0' ||
        displayCode == '14.0' ||
        displayCode.startsWith('14.0.') ||
        code == '14.1' ||
        displayCode == '14.1' ||
        displayCode.startsWith('14.1.') ||
        code == '14.2' ||
        displayCode == '14.2' ||
        displayCode.startsWith('14.2.') ||
        code == '14.4' ||
        displayCode == '14.4' ||
        displayCode.startsWith('14.4.')) {
      return "Sì (da attribuire all'OA)";
    }

    // 16.2
    if (code == '16.2' ||
        displayCode == '16.2' ||
        displayCode.startsWith('16.2.')) {
      return "Regola generale post raccolta (capitolo 8.3.3 ):\nSe il numero di lotti non conformi è ≤ 10% del campione si procede con l'esclusione del/dei lotto/i non conformi;\nSe il numero di lotti non conformi è >10% fino al 25% si procede con l'esclusione del/dei lotto/i non conformi e con un rafforzamento del controllo dell'azienda o della OA da ripetere entro 6 mesi dall'ultima verifica.";
    }

    // 16.1, 16.3, 16.4, 17.2, 17.4, 17.8
    if ({'16.1', '16.3', '16.4', '17.2', '17.4', '17.8'}.contains(code) ||
        {
          '16.1',
          '16.3',
          '16.4',
          '17.2',
          '17.4',
          '17.8',
        }.contains(displayCode) ||
        displayCode.startsWith('16.1.') ||
        displayCode.startsWith('16.3.') ||
        displayCode.startsWith('16.4.') ||
        displayCode.startsWith('17.2.') ||
        displayCode.startsWith('17.4.') ||
        displayCode.startsWith('17.8.')) {
      return "Regola generale post raccolta (capitolo 8.3.3 ):\nSe il numero di lotti non conformi è ≤ 10% del campione si procede con l'esclusione del/dei lotto/i non conformi;\nSe il numero di lotti non conformi è >10% fino al 25% si procede con l'esclusione del/dei lotto/i non conformi e con un rafforzamento del controllo dell'azienda o della OA da ripetere entro 6 mesi dall'ultima verifica.";
    }

    // 1.2.2: Esclusione lotto specifica
    if (code == '1.2.2' ||
        displayCode == '1.2.2' ||
        displayCode.startsWith('1.2.2.')) {
      return "SI' in caso di rilevamento di p.a. non ammessi da etichetta e/o da norme di coltura";
    }

    // 10.1: Esclusione lotto specifica
    if (code == '10.1' ||
        displayCode == '10.1' ||
        displayCode.startsWith('10.1.')) {
      return "SI' (esclusione lotto) in caso di assenza completa del piano di fertilizzazione";
    }

    // 15.1 - 15.5: Esclusione lotto specifica post-raccolta
    if (code == '15.1' ||
        displayCode == '15.1' ||
        displayCode.startsWith('15.1.') ||
        code == '15.2' ||
        displayCode == '15.2' ||
        displayCode.startsWith('15.2.') ||
        code == '15.3' ||
        displayCode == '15.3' ||
        displayCode.startsWith('15.3.') ||
        code == '15.4' ||
        displayCode == '15.4' ||
        displayCode.startsWith('15.4.') ||
        code == '15.5' ||
        displayCode == '15.5' ||
        displayCode.startsWith('15.5.')) {
      return "SI' (esclusione lotto)";
    }

    // Punti con esclusione UEC specifica da disciplinare (1.1, 10.6)
    if (code == '1.1' ||
        displayCode == '1.1' ||
        code == '10.6' ||
        displayCode == '10.6') {
      return 'Sì';
    }

    // Se item.frequenzaSingolo contiene esplicitamente una nota di esclusione / sospensione
    if (item.frequenzaSingolo.isNotEmpty &&
        item.frequenzaSingolo.trim() != '-' &&
        item.frequenzaSingolo.trim() != 'N/A' &&
        (item.frequenzaSingolo.toLowerCase().contains('escl') ||
            item.frequenzaSingolo.toLowerCase().contains('sosp') ||
            item.frequenzaSingolo.trim().toUpperCase() == 'SI' ||
            item.frequenzaSingolo.trim().toLowerCase() == 'sì')) {
      return item.frequenzaSingolo.trim();
    }

    return null;
  }

  static String getSingleScoreText(
    ChecklistItem item,
    int? val,
    bool isOp, {
    String? esclusioneUecText,
    String? esclusioneLottoText,
    String? esclusioneOperatoreText,
  }) {
    if (val == null) return "-";

    final code = item.code.trim();
    final is14 =
        code == '14.0' || code == '14.1' || code == '14.2' || code == '14.4';

    if (isOp) {
      if (val == 0 ||
          (val == 3 &&
              (code == '0.8' ||
                  code == '0.12' ||
                  code == '16.2' ||
                  code == '17.10' ||
                  is14))) {
        if (esclusioneOperatoreText != null &&
            esclusioneOperatoreText.isNotEmpty) {
          return "3 ($esclusioneOperatoreText)";
        }
        if (code == '0.8') return "3 (Sospensione operatore)";
        if (code == '0.12' || code == '16.2' || code == '17.10') {
          return "3 (Sospensione)";
        }
        if (is14) return "3 (Esclusione OA)";
        return "3 (Sospensione)";
      }
      return val.toString();
    } else {
      if (val == 0 ||
          (val == 3 &&
              (is14 ||
                  const {
                    '1.1',
                    '1.2.2',
                    '10.1',
                    '12.2',
                    '15.1',
                    '15.2',
                    '15.3',
                    '15.4',
                    '15.5',
                    '16.1',
                    '16.2',
                    '16.3',
                    '16.4',
                    '17.2',
                    '17.4',
                    '17.8',
                  }.contains(code)))) {
        if (esclusioneUecText != null && esclusioneUecText.isNotEmpty) {
          return "3 ($esclusioneUecText)";
        }
        if (esclusioneLottoText != null && esclusioneLottoText.isNotEmpty) {
          return "3 ($esclusioneLottoText)";
        }
        if (is14) return "3 (Esclusione OA)";
        return "3 (Esclusione lotto)";
      }
      return val.toString();
    }
  }

  static String getScoreText(
    ChecklistItem item,
    int? pUec,
    int? pOp, {
    String? esclusioneUecText,
    String? esclusioneLottoText,
    String? esclusioneOperatoreText,
  }) {
    if (pUec == null && pOp == null) return "-";

    if (pUec != null && pOp != null) {
      return "UEC: ${getSingleScoreText(item, pUec, false, esclusioneUecText: esclusioneUecText, esclusioneLottoText: esclusioneLottoText)}\nOp: ${getSingleScoreText(item, pOp, true, esclusioneOperatoreText: esclusioneOperatoreText)}";
    } else if (pUec != null) {
      return getSingleScoreText(
        item,
        pUec,
        false,
        esclusioneUecText: esclusioneUecText,
        esclusioneLottoText: esclusioneLottoText,
      );
    } else {
      return getSingleScoreText(
        item,
        pOp!,
        true,
        esclusioneOperatoreText: esclusioneOperatoreText,
      );
    }
  }

  static bool isPhaseVisible(String fase, String visitType) {
    final fUpper = fase.toUpperCase();

    // Nuova logica per capitoli numerati (0-17)
    final numMatch = RegExp(r'^(\d+)\.').firstMatch(fase);
    if (numMatch != null) {
      final num = int.parse(numMatch.group(1)!);
      if (num == 0) return true; // Valutazione
      if (num == 1) return true; // Difesa

      if (num >= 2 && num <= 12) {
        if (visitType.contains('ACA') ||
            visitType.contains('MARCHIO') ||
            visitType.contains('ALTRO')) {
          return true;
        }
      }
      if (num >= 13 && num <= 17) {
        if (visitType.contains('MARCHIO') || visitType.contains('ALTRO')) {
          return true;
        }
      }
      return false;
    }

    // Fallback per vecchi nomi o nomi speciali
    if (fUpper.contains('COLTIVAZIONE')) return true;
    if (fUpper.contains('DIFESA')) return true;
    if (fUpper.contains('VALUTAZIONE')) return true;
    if (fUpper.contains('BILANCIO')) return true;
    if (fUpper.contains('GENERICA')) return true;
    if (fUpper.contains('IMPEGNI')) return true;

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

    if (visitType.contains('ALTRO')) return true;

    return false;
  }

  static String getFormattedObbligo(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    // Sezione 8: Gestione del suolo e pratiche agronomiche
    if (code == '8.1.1' || displayCode.startsWith('8.1.1')) {
      const prefix = 'Negli appezzamenti con pendenza media superiore al 30%: ';
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains('pendenza media superiore al 30%')) {
        return raw;
      }
      return '$prefix${raw.isNotEmpty ? raw : "colture erbacee: sono consentite solo tecniche di minima lavorazione, la semina su sodo e la scarificatura/ripuntatura"}';
    }

    if (code == '8.1.2' || displayCode.startsWith('8.1.2')) {
      const prefix = 'Negli appezzamenti con pendenza media superiore al 30%: ';
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains('pendenza media superiore al 30%')) {
        return raw;
      }
      return '$prefix${raw.isNotEmpty ? raw : "colture arboree: è obbligatorio l'inerbimento nell'interfila anche come vegetazione spontanea gestita con sfalci. All’impianto sono ammesse solo le lavorazioni puntuali (lavorazioni utili per la sola messa a dimora delle piante) o altre finalizzate alla sola asportazione dei residui dell’impianto arboreo precedente. Nei primi due anni di impianto della coltura l’impegno dell’inerbimento si puo' applicare anche a filari alterni"}';
    }

    if (code == '8.2.3' || displayCode.startsWith('8.2.3')) {
      return 'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: consentite lavorazioni ad una profondità max di 30 cm';
    }

    if (code == '8.2.4' || displayCode.startsWith('8.2.4')) {
      const prefix =
          'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ';
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains(
        'pendenza media compresa tra il 10% e il 30%',
      )) {
        return raw;
      }
      return '$prefix${raw.isNotEmpty ? raw : "Colture erbacee: obbligatoria la realizzazione di solchi acquai temporanei al max ogni 60 m (oppure vedere alternativa al punto del PCN 8.2.5)"}';
    }

    if (code == '8.2.5' || displayCode.startsWith('8.2.5')) {
      const prefix =
          'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ';
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains(
        'pendenza media compresa tra il 10% e il 30%',
      )) {
        return raw;
      }
      return '$prefix${raw.isNotEmpty ? raw : "In alternativa al punto del PCN 8.2.4, in situazioni geo-pedologiche particolari e di frammentazione fondiaria, prevedere sistemi alternativi di protezione del suolo dall'erosione"}';
    }

    if (code == '8.2.6' || displayCode.startsWith('8.2.6')) {
      const prefix =
          'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ';
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains(
        'pendenza media compresa tra il 10% e il 30%',
      )) {
        return raw;
      }
      return '$prefix${raw.isNotEmpty ? raw : "Colture arboree: obbligatorio l’inerbimento nell’interfila (anche come vegetazione spontanea gestita con sfalci). Le operazioni di semina ed interramento del sovescio sono ammissibili ma il sovescio andrà eseguito a filari alterni. Nei primi due anni di impianto della coltura l'impegno dell'inerbimento si puo' applicare anche a filari alterni."}';
    }

    if (code == '8.3' || displayCode.startsWith('8.3')) {
      final raw = item.obbligo.trim();
      if (raw.toLowerCase().contains('pendenza media < 10%')) {
        return raw;
      }
      if (raw.isNotEmpty) {
        return 'Colture arboree negli appezzamenti con pendenza media < 10%: $raw';
      }
      return 'Colture arboree negli appezzamenti con pendenza media < 10%: è obbligatorio l’inerbimento dell’interfila nel periodo autunno-invernale. Le operazioni di semina ed inerramento del sovescio sono consentite';
    }

    if (code == '8.4' || displayCode.startsWith('8.4')) {
      final raw = item.obbligo.trim();
      if (raw.isNotEmpty) return raw;
      return 'Rispetto ulteriori disposizioni relative alla gestione del suolo e pratiche agronomiche per il controllo delle infestanti';
    }

    // Sezione 4: Materiale di propagazione
    if (code == '4.5' ||
        code == '4.5.1' ||
        displayCode.startsWith('4.5.1') ||
        displayCode.startsWith('4.5.2')) {
      const base =
          'Il materiale di propagazione deve essere sano e garantito dal punto di vista genetico e deve essere in grado di offrire garanzie fitosanitarie e di qualità agronomica';
      final raw = item.obbligo.trim();
      if (raw.contains('Il materiale di propagazione deve essere sano')) {
        return raw;
      }
      return raw.isNotEmpty ? '$base; $raw' : base;
    }

    // Sezione 0: Punti 0.10 e 0.11
    if (code == '0.10' || code == '0.11') {
      return item.obbligo.replaceFirst(
        'superfici catastali',
        'superfici aziendali',
      );
    }

    // Sezione 6: Avvicendamento
    if (code == '6.1') {
      return "coinvolgimento intera superficie aziendale o parte di essa: devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)";
    }
    if (code == '6.2') {
      return "coinvolgimento superfici aziendali dedicate a specifiche colture :devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)";
    }

    // Sezione 7: Semina, trapianto, impianto
    if (code == '7.1' || displayCode.startsWith('7.1')) {
      final raw = item.obbligo.trim();
      if (raw.isNotEmpty) return raw;
      return 'Colture annuali e perenni: Rispettare le densità di semina e impianto laddove posti dei vincoli nei DPI';
    }

    // Sezione 10: Concimazione / analisi suolo
    if (code == '10.5.1' ||
        code == '10.5.2' ||
        displayCode.startsWith('10.5.1') ||
        displayCode.startsWith('10.5.2')) {
      const base =
          "Esecuzione di analisi del suolo (effettuazione di un'analisi almeno per ciascuna area omogenea dal punto di vista pedologico ed agronomico) prima della stesura del piano di fertilizzazione o utilizzo delle schede a dose standard";
      final raw = item.obbligo.trim();
      if (raw.contains('Esecuzione di analisi del suolo')) {
        return raw;
      }
      return raw.isNotEmpty ? '$base; $raw' : base;
    }

    // Sezione 13: Raccolta
    if (code == '13' || displayCode == '13') {
      return 'Raccolta ; Secondo quanto definito dalla Regione nel disciplinare (laddove siano previste prescrizioni obbligatorie)';
    }
    if (code == '13.1' ||
        displayCode == '13.1' ||
        displayCode.startsWith('13.1.')) {
      return 'Se disciplinati dalla Regione o P.A. verificare il rispetto dei parametri per inizio raccolta';
    }
    if (code == '13.2' ||
        displayCode == '13.2' ||
        displayCode.startsWith('13.2.')) {
      return 'Se disciplinati dalla Regione o P.A. verificare il rispetto delle modalità di raccolta e conferimento ai centri di stoccaggio / lavorazione';
    }

    // Sezione 15: Impegni aziendali
    if (code == '15.15') {
      return 'predisporre un piano aziendale all’interno del quale prevedere le modalità e tempi di realizzazione degli impegni aziendali relativi a:\n• formazione a tutto il personale sul tema della sicurezza sul lavoro;\n• formazione sul tema della sostenibilità delle produzioni almeno al personale tecnico assunto a tempo indeterminato';
    }

    // Sezione 17: Osservatorio
    if (code == '17.9') {
      return 'Pubblicizzare l’indirizzo dell’Osservatorio SQNPI e le modalità di segnalazione. Per gli OA mediante l’utilizzo del proprio sito web; per le aziende singole sito web o almeno un cartello presso il centro aziendale.';
    }

    return item.obbligo;
  }

  static String? getDeroghe(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '8.2.3' || displayCode.startsWith('8.2.3')) {
      return 'Eccezione per la ripuntatura per la quale è ammessa una profondità massima di 50 cm';
    }
    if (code == '8.2.6' || displayCode.startsWith('8.2.6')) {
      return 'In areali contraddistinti da scarsa piovosità nel periodo vegetativo, su terreni a tessitura argillosa, argillosa-limosa, argillosa-sabbiosa, franco-limosa-argillosa, franco-argillosa e franco-sabbiosa-argillosa (classificazione USDA) il vincolo non si applica. In tal caso nel periodo primaverile-estivo, in alternativa all\'inerbimento, sono consentite lavorazioni a filari alterni con lo scopo di arieggiare/decompattare il terreno fino ad un massimo di 30 cm di profondità.';
    }
    if (code == '8.3' || displayCode.startsWith('8.3')) {
      return "L'impegno dell'inerbimento non si applica nei primi 2 anni di impianto della coltura arborea. Dove vige il vincolo dell'inerbimento nell'interfila sono ammessi quegli interventi localizzati di interramento dei concimi sulla fila, individuati dalle regioni e province autonome come i meno impattanti.";
    }
    if (code == '13.1' ||
        code == '13.2' ||
        displayCode.startsWith('13.1') ||
        displayCode.startsWith('13.2')) {
      return null;
    }

    final raw = item.deroghe.trim();
    if (raw.isNotEmpty && raw != '1' && !raw.startsWith('100%')) {
      return raw;
    }

    return null;
  }

  static String? getFrequenzaSingolo(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '0.12' ||
        code == '0.13' ||
        code == '10.4' ||
        displayCode.startsWith('10.4') ||
        displayCode.startsWith('14.0') ||
        code == '14.1' ||
        displayCode.startsWith('14.1') ||
        code == '14.2' ||
        displayCode.startsWith('14.2') ||
        code == '14.4' ||
        displayCode.startsWith('14.4') ||
        code == '17.10' ||
        code == '0.8' ||
        code == '0.9' ||
        code == '0.10' ||
        code == '0.11' ||
        code == '10.6' ||
        displayCode.startsWith('10.6')) {
      return null;
    }

    if (code == '16.2' ||
        displayCode.startsWith('16.2') ||
        code == '16.3' ||
        displayCode.startsWith('16.3') ||
        {'17.1', '17.2', '17.3', '17.4', '17.7', '17.8'}.contains(code)) {
      return '100% operatori (verifica lotti in stoccaggio, da 1 a 10 lotti n. 1 lotto da verificare, da 11 a 50 n. 2 lotti da verificare, da 51 a 100 n. 3 lotti da verificare, da 101 a 500 n. 4 lotti, da 501 a 5000 n. 5 lotti da verificare, da 5001 a 50000 n. 6 lotti, oltre 50000 n. 7 lotti)';
    }

    return '100%';
  }

  static String? getFrequenzaAssociato(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '0.12' ||
        code == '0.13' ||
        code == '10.4' ||
        displayCode.startsWith('10.4') ||
        code == '14.0' ||
        displayCode.startsWith('14.0') ||
        code == '16.2' ||
        displayCode.startsWith('16.2') ||
        code == '16.3' ||
        displayCode.startsWith('16.3') ||
        code == '10.6' ||
        displayCode.startsWith('10.6') ||
        code == '17.10') {
      return null;
    }

    if (code == '0.8' || code == '0.9' || code == '14.2') {
      return '100%';
    }

    if ({'17.1', '17.2', '17.3', '17.4', '17.7', '17.8'}.contains(code)) {
      return '100% operatori del campione (verifica lotti in stoccaggio, da 1 a 10 lotti n. 1 lotto da verificare, da 11 a 50 n. 2 lotti da verificare, da 51 a 100 n. 3 lotti da verificare, da 101 a 500 n. 4 lotti, da 501 a 5000 n. 5 lotti da verificare, da 5001 a 50000 n. 6 lotti, oltre 50000 n. 7 lotti)';
    }

    return '√n';
  }

  static String? getGravitaUec(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '10.6' ||
        displayCode == '10.6' ||
        displayCode.startsWith('10.6.')) {
      return '3';
    }
    if (code == '13.1' ||
        code == '13.2' ||
        displayCode.startsWith('13.1') ||
        displayCode.startsWith('13.2')) {
      return '2';
    }
    if (code == '6.2' || displayCode.startsWith('6.2')) {
      return "1 se è nell'intervallo 3% -10% della SAU aziendale dedicata alla specifica coltura sulla quale non vengono rispettate le norme ; 2 se nell'intervallo 10%-30%; 3 se > 30%.";
    }
    if (code == '17.7' || displayCode.startsWith('17.7')) {
      return 'Nessuna NC qualora si agisca con AC e rafforzamento del campione';
    }
    if (item.tipologiaControllo.trim().isNotEmpty) {
      return item.tipologiaControllo.trim().replaceAll('quaolra', 'qualora');
    }
    return null;
  }

  static String? getGravitaOperatore(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '15.6' ||
        code == '15.7' ||
        displayCode.startsWith('15.6') ||
        displayCode.startsWith('15.7')) {
      return 'NC lieve pari ad 1 per ogni requisito non rispettato';
    }
    if (code == '15.8' ||
        code == '15.9' ||
        code == '15.10' ||
        code == '15.11' ||
        code == '15.13' ||
        displayCode.startsWith('15.8') ||
        displayCode.startsWith('15.9') ||
        displayCode.startsWith('15.10') ||
        displayCode.startsWith('15.11') ||
        displayCode.startsWith('15.13')) {
      return '1';
    }
    if (code == '15.12' ||
        code == '15.14' ||
        code == '15.15' ||
        displayCode.startsWith('15.12') ||
        displayCode.startsWith('15.14') ||
        displayCode.startsWith('15.15')) {
      return '2';
    }

    if (item.frequenzaAssociato.trim().isNotEmpty) {
      return item.frequenzaAssociato.trim();
    }
    return null;
  }

  static String? getTarget(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    // Headers do not have targets
    if (item.indicatorType.toLowerCase() == 'header' ||
        code == '0.0' ||
        code == '15_D1' ||
        code == '15_D2' ||
        RegExp(r'^\d+$').hasMatch(code)) {
      return null;
    }

    const operatorOnlyCodes = {
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
      '14.0',
      '14.1',
      '14.2',
      '14.4',
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

    if (operatorOnlyCodes.contains(code) ||
        operatorOnlyCodes.contains(displayCode) ||
        code.startsWith('14.') ||
        displayCode.startsWith('14.')) {
      return 'Operatore';
    }

    if (code == '16.2' || displayCode.startsWith('16.2')) {
      return 'Lotto / Operatore';
    }

    const lottoCodes = {
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
    };

    if (lottoCodes.contains(code) ||
        lottoCodes.contains(displayCode) ||
        displayCode.startsWith('15.1.') ||
        displayCode.startsWith('15.2.') ||
        displayCode.startsWith('15.3.') ||
        displayCode.startsWith('15.4.') ||
        displayCode.startsWith('15.5.') ||
        displayCode.startsWith('16.1.') ||
        displayCode.startsWith('16.3.') ||
        displayCode.startsWith('16.4.') ||
        displayCode.startsWith('17.1.') ||
        displayCode.startsWith('17.2.') ||
        displayCode.startsWith('17.3.') ||
        displayCode.startsWith('17.4.') ||
        displayCode.startsWith('17.7.') ||
        displayCode.startsWith('17.8.')) {
      return 'Lotto';
    }

    return 'UEC';
  }

  static String? getRiferimento(ChecklistItem item) {
    if (item.colGText.trim().isNotEmpty) {
      return item.colGText.trim();
    }
    return null;
  }

  static String? getFormattedNote(ChecklistItem item) {
    final code = item.code.trim();
    final displayCode = item.displayCode.trim();

    if (code == '13.1' ||
        displayCode == '13.1' ||
        displayCode.startsWith('13.1.')) {
      return 'Scheda di raccolta con registrazione parametri previsti dal DPI. Estrazione a campione delle schede da verificare in funzione delle colture praticate. Verifica analitica in campo in caso di visita in fase di raccolta. Per le aziende oggetto di verifica: almeno 2 schede di cui una del prodotto più rappresentativo in termini di superficie';
    }
    if (code == '13.2' ||
        displayCode == '13.2' ||
        displayCode.startsWith('13.2.')) {
      return 'Descrizione delle modalità di raccolta e conferimento in manuale di autocontrollo o altro documento. Verifica in sede di visita ispettiva. Verifica visiva del prodotto al centro di stoccaggio ove possibile.';
    }
    if (code == '0.4') {
      final base = item.noteNorma.trim();
      const extra =
          "La verifica delle registrazioni sul registro aziendale SQNPI elettronico, entro i termini stabiliti dalla norma, si intende soddisfatta anche a fronte di evidenze desumibili da registri cartacei o e-mail. Il ritardo o la registrazione incompleta/imprecisa si riferiscono ad uno o piu' interventi. Per il materiale di moltiplicazione le verifiche in merito al requisito di eventuali certificazioni previste dalla norma, riscontrano la presenza degli appositi cartellini o certificati.";
      return base.isNotEmpty ? '$base\n\n$extra' : extra;
    }
    if (code == '0.10' || code == '0.11') {
      return "Eventuali incongruenze vanno gestite mediante AC finalizzate ad aggiornare la domanda. Nel caso in cui la formalizzazione dell'A.C possa compromettere la tempistica per il rilascio della certificazione o conformità ACA, l'ODC procede con l'allocazione delle parcelle interessate in uno o più aggregati- UEC aggiuntivi e l'attribuzione della relativa N.C. Nel caso di piano colturale difforme si sottolinea l’importanza di accertare la natura avvicendante o intercalare della coltura, da gestire come riportato al punto 5 della Norma.";
    }
    if (code == '0.13') {
      return "La relativa non conformità viene attribuita nella seguente maniera:\n- operatore interessato alla fase di campo : si attribuisce il valore correlato alla fase di campo\n- operatore post raccolta: si attribuisce il valore correlato alla fase di raccolta/ post raccolta\n- operatore interessato a tutte le fasi del processo, di campo e di raccolta/post raccolta: si attribuisce il valore correlato alla fase di post raccolta\n(Vedere anche punto 17.9 del PCN)";
    }
    if (code == '15.3') {
      return 'Verifica analisi';
    }
    if (item.noteNorma.trim().isNotEmpty) {
      return item.noteNorma.trim();
    }
    return null;
  }
}
