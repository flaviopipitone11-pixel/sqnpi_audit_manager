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
          : (code == '4.5.2' || displayCode.startsWith('4.5.2'))
          ? "verificare documenti fiscali e i certificati relativi a nuovi impianti effettuati"
          : (code == '4.5.1' || displayCode.startsWith('4.5.1'))
          ? "verificare documenti fiscali e i certificati relativi all'acquisto di semente e piantine orticole"
          : (code == '4.6' || displayCode.startsWith('4.6'))
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

  static String getSingleScoreText(
    ChecklistItem item,
    int? val,
    bool isOp, {
    String? esclusioneUecText,
    String? esclusioneLottoText,
    String? esclusioneOperatoreText,
  }) {
    if (val == null) return "-";
    if (val != 0) return val.toString();

    final code = item.code.trim();
    final is14 =
        code == '14.0' || code == '14.1' || code == '14.2' || code == '14.4';

    if (isOp) {
      if (esclusioneOperatoreText != null &&
          esclusioneOperatoreText.isNotEmpty) {
        return esclusioneOperatoreText;
      }
      if (code == '0.8') return "Sospensione operatore";
      if (code == '0.12' || code == '16.2' || code == '17.10') {
        return "Sospensione";
      }
      if (is14) return "Esclusione OA";
      return "Esclusione OA";
    } else {
      if (esclusioneUecText != null && esclusioneUecText.isNotEmpty) {
        return esclusioneUecText;
      }
      if (esclusioneLottoText != null && esclusioneLottoText.isNotEmpty) {
        return esclusioneLottoText;
      }
      if (is14) return "Esclusione OA";
      return "Esclusione lotto";
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
}
