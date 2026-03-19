class HelpTexts {
  static const Map<String, String> all = {
    // Anagrafica Azienda
    'CUAA': 'Codice Univoco Anagrafe Agricola. Deve corrispondere a quanto presente sul SI del SQNPI.',
    'Partita IVA': 'Partita IVA dell\'azienda or codice fiscale se ditta individuale.',
    'Sede Operativa': 'Luogo fisico in cui avvengono le principali attività agricole o di condizionamento oggetto di controllo.',
    'Operatore certificato da un altro OdC negli anni precedenti': 'Attivare se l\'azienda proviene da un altro Organismo di Controllo per la procedura M904.',
    'Mesi di Picco dell\'Attività': 'Selezionare i mesi in cui l\'attività aziendale è più intensa (es. raccolta, vendemmia).',

    // Quadro Verifica
    'Campionamento Effettuato': 'Indica se durante la visita è stato prelevato un campione di prodotto o vegetale per analisi multiresiduale.',
    'Lotto Campionamento': 'Identificativo univoco del lotto da cui è stato prelevato il campione.',
    'Prodotto Identificabile': 'Verificare se il prodotto in campo o in magazzino è chiaramente identificato con cartellini o segnaletica.',
    'Processo Verificato': 'Confermare che le fasi produttive dichiarate siano state effettivamente riscontrate durante il sopralluogo.',

    // Bilancio di Massa
    'Prodotti verificati': 'Elenco dei prodotti (es. Vino DOC, Olio EVO) oggetto della verifica di bilancio di massa.',
    'Dati in ingresso': 'Quantità totali caricate (es. da registro di campagna o fatture acquisto).',
    'Dati in uscita': 'Quantità totali scaricate (es. vendite certificate o rimanenze).',
    'Documenti di riferimento': 'Indicare i documenti visionati (es. registri di cantina, fatture, DDT).',

    // Rintracciabilità
    'Prova di rintracciabilità': 'Test per risalire dal prodotto finito (lotto) alle materie prime e alle fasi colturali.',

    // Chiusura
    'Data Visita': 'Giorno effettivo in cui si è svolto il sopralluogo.',
    'Ora Inizio': 'Orario di apertura della visita ispettiva presso l\'azienda.',
    'Ora Fine': 'Orario di chiusura del verbale e firma delle parti.',
    'Esito': 'Risultato finale basato sulla gravità delle non conformità rilevate (Soddisfacente, Non Soddisfacente).',
    'Proposta provvedimento': 'Azione proposta dall\'ispettore (es. Mantenimento, Sospensione, Esclusione).',
    'Riserve': 'Eventuali osservazioni o contestazioni sollevate dal rappresentante aziendale al termine della visita.',
  };

  static String? get(String label) {
    // Cerchiamo una corrispondenza esatta o parziale
    for (final entry in all.entries) {
      if (label.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}
