import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('================================================================');
  print('=== TEST SIMULAZIONE ISPETTORE CED (ced@certbios.it)          ===');
  print(
    '=== Sincronizzazione Visite Assegnate -> Compilazione -> Supabase ===',
  );
  print('================================================================\n');

  final client = HttpClient();

  // 1. LOGIN BIOSFERA CON PROFILO CED
  print('1. Autenticazione Biosfera con profilo CED (ced@certbios.it)...');
  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );
  final reqLogin = await client.postUrl(loginUrl);
  reqLogin.headers.contentType = ContentType.json;
  reqLogin.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final resLogin = await reqLogin.close();
  final bodyLogin = await resLogin.transform(utf8.decoder).join();
  final decodedLogin = jsonDecode(bodyLogin);

  if (resLogin.statusCode != 200 || decodedLogin['access_token'] == null) {
    print('❌ Errore login Biosfera: ${resLogin.statusCode} - $bodyLogin');
    client.close();
    return;
  }

  final token = decodedLogin['access_token'] as String;
  final userData = decodedLogin['user'] ?? {};
  final inspectorCode = userData['inspectorCode'] ?? 'CED';
  print('   ✅ Autenticazione riuscita! Token ottenuto.');
  print('   Codice Ispettore CED: $inspectorCode\n');

  // 2. DOWNLOAD VISITE ASSEGNATE A CED (SINCRONIZZA)
  print('2. Sincronizzazione: Download visite assegnate al profilo CED...');
  final listAuditsUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$inspectorCode',
  );
  final reqList = await client.getUrl(listAuditsUrl);
  reqList.headers.add('Authorization', 'Bearer $token');
  final resList = await reqList.close();
  final bodyList = await resList.transform(utf8.decoder).join();
  final decodedList = jsonDecode(bodyList);

  final List<dynamic> visitsList = decodedList['data'] ?? [];
  print(
    '   ✅ Trovate ${visitsList.length} visite assegnate all\'ispettore CED.',
  );

  if (visitsList.isEmpty) {
    print(
      '   ⚠️ Nessuna visita trovata nell\'elenco, uso visita di default 65147 per il test.',
    );
  }

  // Selezioniamo la visita per il test (es. 65147 o la prima dall'elenco)
  final targetVisit = visitsList.firstWhere(
    (v) => v['id'] == '65147',
    orElse: () => visitsList.isNotEmpty ? visitsList.first : {'id': '65147'},
  );
  final String visitId = targetVisit['id'].toString();
  print('   📌 Visita selezionata per il test: ID $visitId\n');

  // 3. DOWNLOAD DETTAGLI COMPLETI ASSEGNAZIONE
  print('3. Download dettagli audit $visitId da Biosfera...');
  final downUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$visitId',
  );
  final reqDown = await client.getUrl(downUrl);
  reqDown.headers.add('Authorization', 'Bearer $token');
  final resDown = await reqDown.close();
  final bodyDown = await resDown.transform(utf8.decoder).join();
  final decodedDown = jsonDecode(bodyDown);
  final assignment = decodedDown['data'] ?? {};
  final companyData = assignment['visit_companies'] ?? {};
  print(
    '   Azienda: ${companyData['ragione_sociale'] ?? 'Azienda Agricola CED'}',
  );
  print('   CUAA: ${companyData['cuaa'] ?? 'CEDCUAA12345'}');
  print(
    '   Protocollo SQNPI: ${companyData['sqnpi_protocol'] ?? 'PROT-2026-CED'}\n',
  );

  // 4. SIMULAZIONE COMPILAZIONE CAMPI E SEZIONI (CHECKLIST INCLUSA)
  print('4. Simulazione compilazione integrale campi, sezioni e checklist...');
  final nowStr = DateTime.now().toIso8601String();

  final supabaseBaseUrl = 'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1';
  final anonKey = 'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x';

  Future<bool> pushToSupabase(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$supabaseBaseUrl/$table');
    final req = await client.postUrl(url);
    req.headers.add('apikey', anonKey);
    req.headers.add('Authorization', 'Bearer $anonKey');
    req.headers.add('Content-Type', 'application/json');
    req.headers.add('Prefer', 'resolution=merge-duplicates');
    req.write(jsonEncode([payload]));
    final res = await req.close();
    final resBody = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200 || res.statusCode == 201) {
      print(
        '   ✅ [$table] Salvataggio su Supabase riuscito (${res.statusCode})',
      );
      return true;
    } else {
      print('   ❌ [$table] Errore salvataggio: ${res.statusCode} - $resBody');
      return false;
    }
  }

  // 4.1 Tabella visits
  final visitsPayload = {
    'id': visitId,
    'scheduled_at': nowStr,
    'company_name':
        companyData['ragione_sociale'] ?? 'Azienda Agricola Test CED',
    'crop': 'VITE DA VINO',
    'status': 1,
    'visit_type': 'ACA',
    'inspector_name': 'Ispettore CED',
    'inspector_email': 'ced@certbios.it',
    'duration_hours': 4.5,
    'planned_duration_hours': 5.0,
    'duration_justification': 'Visita approfondita campo e cantina',
    'companion_name': 'Mario Rossi',
    'representative_name': 'Giuseppe Verdi',
    'other_operators': 'Anna Bianchi',
    'contacted_persons': 'Responsabile Qualità',
    'is_representative_delegate': true,
    'representative_delegate_details':
        'Delega formalizzata con documento n. 123',
    'uses_m202_manual_signature': false,
    'updated_at': nowStr,
  };
  await pushToSupabase('visits', visitsPayload);

  // 4.2 Tabella visit_companies
  final companiesPayload = {
    'visit_id': visitId,
    'ragione_sociale':
        companyData['ragione_sociale'] ?? 'Azienda Agricola Test CED',
    'cuaa': companyData['cuaa'] ?? 'VRDFNC80A01H501Z',
    'partita_iva': companyData['partita_iva'] ?? '01234567890',
    'indirizzo': companyData['indirizzo'] ?? 'Via delle Vigne 10',
    'cap': companyData['cap'] ?? '37100',
    'comune': companyData['comune'] ?? 'Verona',
    'provincia': companyData['provincia'] ?? 'VR',
    'referente': 'Giuseppe Verdi',
    'telefono': '045123456',
    'email': 'info@aziendaced.it',
    'pec': 'aziendaced@pec.it',
    'submission_number': companyData['submission_numer'] ?? 'SUB-999',
    'sqnpi_protocol': companyData['sqnpi_protocol'] ?? 'PROT-CED-2026',
    'sqnpi_submission_date': nowStr,
    'is_new_operator': false,
    'processing_type': 'In loco',
    'third_party_cert_number': 'CERT-3321',
    'si_verification': 'Conforme',
    'manipulation_site_address': 'Via Cantina 5',
    'manipulation_site_cap': '37100',
    'manipulation_site_comune': 'Verona',
    'manipulation_site_provincia': 'VR',
    'peak_period_from': '01/09/2026',
    'peak_period_to': '15/10/2026',
    'is_joint_visit': false,
    'marchio_nature': 'SQNPI Qualità Sostenibile',
    'marchio_processes': 'Vinificazione e Imbottigliamento',
  };
  await pushToSupabase('visit_companies', companiesPayload);

  // 4.3 Tabella visit_documents (Documenti riferimento / visionati)
  final documentPayload = {
    'id': 'DOC-CED-001',
    'visit_id': visitId,
    'category': 'reference',
    'doc_type': 'Disciplinare Produzione Integrata 2026',
    'extra_value': 'Rev 08',
    'is_checked': true,
  };
  await pushToSupabase('visit_documents', documentPayload);

  // 4.4 Tabella visit_uecs (Unità Elementari di Controllo)
  final uecId = 'UEC-CED-$visitId-01';
  final uecsPayload = {
    'id': uecId,
    'visit_id': visitId,
    'coltura': 'VITE DA VINO',
    'descrizione': 'Vigneto San Zeno - Foglio 12 Mappale 45',
    'n_aggregato': '1',
    'note': 'Verifica coltiva in pieno campo',
    'latitude': 45.4383,
    'longitude': 10.9916,
    'sqnpi_consistency': 'Conforme',
    'sqnpi_compliance': 'Conforme',
    'is_traceable': true,
    'has_claims': false,
    'is_field_process_verified': true,
    'has_sampling': true,
    'sampling_lot_id': 'LOTTO-VITE-01',
    'found_product': 'Uva Chardonnay',
    'updated_at': nowStr,
  };
  await pushToSupabase('visit_uecs', uecsPayload);

  // 4.5 Tabella visit_lots (Lotti)
  final lotsPayload = {
    'id': 'LOT-CED-001',
    'uec_id': uecId,
    'codice': 'LOTTO-VITE-01',
    'quantita': '250 Quintali',
    'note': 'Uva destinata a vinificazione integrata',
    'updated_at': nowStr,
  };
  await pushToSupabase('visit_lots', lotsPayload);

  // 4.6 Tabella checklist_responses_packed (Check List completa)
  final checklistResponses = [
    {
      'id': 'RESP-1.1.1',
      'item_code': '1.1.1',
      'conformita': 'C',
      'livello_ko': 0,
      'punteggio_uec': 10,
      'punteggio_operatore': 10,
      'rilievo_nc': '',
      'azione_correttiva': '',
      'note': 'Registro trattamenti conforme e sottoscritto.',
      'updated_at': nowStr,
    },
    {
      'id': 'RESP-1.1.2',
      'item_code': '1.1.2',
      'conformita': 'NC',
      'livello_ko': 1,
      'punteggio_uec': 0,
      'punteggio_operatore': 0,
      'rilievo_nc': 'Mancata taratura periodica dell\'atomizzatore.',
      'azione_correttiva':
          'Eseguire taratura presso centro autorizzato entro 30gg.',
      'note': 'Rilevato in sede di sopralluogo fabbricato macchine.',
      'updated_at': nowStr,
    },
    {
      'id': 'RESP-2.1.1',
      'item_code': '2.1.1',
      'conformita': 'C',
      'livello_ko': 0,
      'punteggio_uec': 5,
      'punteggio_operatore': 5,
      'rilievo_nc': '',
      'azione_correttiva': '',
      'note': 'Stoccaggio fitosanitari in armadio dedicato e chiuso a chiave.',
      'updated_at': nowStr,
    },
  ];
  final packedPayload = {
    'uec_id': uecId,
    'visit_id': visitId,
    'responses_json': checklistResponses,
    'updated_at': nowStr,
  };
  await pushToSupabase('checklist_responses_packed', packedPayload);

  // 4.7 Tabella visit_previous_nc_managements (NC Anni Precedenti)
  final prevNcPayload = {
    'visit_id': visitId,
    'prev_nc_results': 1,
    'prev_nc_requirements_still_ko': 'Nessuna',
    'prev_corrective_actions_coherent': 1,
    'prev_corrective_actions_details':
        'L\'operatore ha fornito evidenza documentale dell\'avvenuto ripristino.',
    'prev_org_certified_date': '2024-05-10',
    'updated_at': nowStr,
  };
  await pushToSupabase('visit_previous_nc_managements', prevNcPayload);

  // 4.8 Tabella visit_closings (Esito finale e chiusura)
  final closingsPayload = {
    'visit_id': visitId,
    'corrective_actions': 'Risoluzione NC 1.1.2 entro il termine prescritto.',
    'resolution_deadline': '2026-08-30T00:00:00.000',
    'is_closed': 1,
    'cap5_adherence': 1,
    'cap5_specific_crops': 'Vite da vino',
    'commitment_to_rectify': 1,
    'inspection_methods':
        'Sopralluogo in campo, verifica magazzino e controllo documentale',
    'representative_present': 1,
    'is_outcome_formalized': 1,
    'verification_notes': 'Audit completato regolarmente',
    'final_recommendation': 1,
    'inspector_final_comment':
        'L\'operatore ha dimostrato collaborazione e correttezza nelle registrazioni.',
    'final_outcome': 1,
    'provision_detail': 'Emissione certificato subordinata a verifica AC.',
    'updated_at': nowStr,
  };
  await pushToSupabase('visit_closings', closingsPayload);

  // 4.9 Tabella visit_signatures (Firme)
  final signaturePayload = {
    'id': 'SIG-CED-01',
    'visit_id': visitId,
    'signature_type': 'ISPETTORE',
    'signer_name': 'Ispettore CED',
    'file_path': '/signatures/inspector_ced_$visitId.png',
    'created_at': nowStr,
  };
  await pushToSupabase('visit_signatures', signaturePayload);

  // 4.10 Tabella mass_balance_records (Bilancio di massa)
  final massBalancePayload = {
    'id': 'MB-CED-01',
    'visit_id': visitId,
    'substances': 'Fitosanitario Alfa-10',
    'purchased': 100.0,
    'used': 60.0,
    'stock': 40.0,
    'discrepancy': 0.0,
    'reference_documents': 'Fattura n. 456 del 10/05/2026',
    'verified_products': 'Uva Chardonnay',
    'comment': 'Bilancio di massa perfettamente congruente.',
    'updated_at': nowStr,
  };
  await pushToSupabase('mass_balance_records', massBalancePayload);

  // 4.11 Tabella mass_balance_documents
  final mbDocsPayload = {
    'id': 'MBDOC-CED-01',
    'visit_id': visitId,
    'file_path': '/docs/fattura_456.pdf',
    'file_name': 'fattura_456.pdf',
  };
  await pushToSupabase('mass_balance_documents', mbDocsPayload);

  // 4.12 Tabella post_harvest_records (Post-raccolta)
  final postHarvestPayload = {
    'id': 'PH-CED-01',
    'visit_id': visitId,
    'phases': 'Diraspatura, Fermentazione, Affinamento in acciaio',
    'mb_verified_products': 'Vino IGT Verona 2026',
    'mb_comment': 'Tracciabilità di cantina verificata con successo.',
    'updated_at': nowStr,
  };
  await pushToSupabase('post_harvest_records', postHarvestPayload);

  // 4.13 Tabella visit_samples (Campionamento)
  final samplesPayload = {
    'id': 'SMP-CED-01',
    'visit_id': visitId,
    'sample_code': 'CAMP-CED-2026-001',
    'seal_number': 'SIGILLO-CED-8877',
    'producer_name': 'Azienda Agricola Test CED',
    'producer_code': 'PROD-CED-1',
    'photo_path': '/photos/sample_ced_01.jpg',
  };
  await pushToSupabase('visit_samples', samplesPayload);

  // 4.14 Tabella visit_attachments (Allegati)
  final attachmentsPayload = {
    'id': 'ATT-CED-01',
    'visit_id': visitId,
    'file_path': '/attachments/foto_vigneto_ced.jpg',
    'caption': 'Foto panoramica vigneto San Zeno',
    'category': 'photo',
    'attachment_type': 'field_photo',
    'latitude': 45.4383,
    'longitude': 10.9916,
    'uec_id': uecId,
    'checklist_code': '1.1.1',
    'created_at': nowStr,
  };
  await pushToSupabase('visit_attachments', attachmentsPayload);

  // 5. VERIFICA FINALE DEL SALVATAGGIO SU SUPABASE
  print(
    '\n5. Verifica della persistenza dei dati salvati nelle tabelle Supabase...',
  );
  final tablesToVerify = [
    'visits',
    'visit_companies',
    'visit_documents',
    'visit_uecs',
    'visit_lots',
    'checklist_responses_packed',
    'visit_previous_nc_managements',
    'visit_closings',
    'visit_signatures',
    'mass_balance_records',
    'mass_balance_documents',
    'post_harvest_records',
    'visit_samples',
    'visit_attachments',
  ];

  int verifiedCount = 0;
  for (final table in tablesToVerify) {
    final queryField = table == 'visit_lots'
        ? 'uec_id'
        : (table == 'visit_companies' ||
                  table == 'visit_previous_nc_managements' ||
                  table == 'visit_closings' ||
                  table == 'checklist_responses_packed'
              ? 'visit_id'
              : (table == 'visits' ? 'id' : 'visit_id'));

    final queryValue = table == 'visit_lots' ? uecId : visitId;

    final verifyUrl = Uri.parse(
      '$supabaseBaseUrl/$table?$queryField=eq.$queryValue',
    );
    final reqV = await client.getUrl(verifyUrl);
    reqV.headers.add('apikey', anonKey);
    reqV.headers.add('Authorization', 'Bearer $anonKey');
    final resV = await reqV.close();
    final bodyV = await resV.transform(utf8.decoder).join();
    final decodedV = jsonDecode(bodyV);
    final int recordCount = decodedV is List
        ? decodedV.length
        : (decodedV is Map ? 1 : 0);

    if (resV.statusCode == 200 && recordCount > 0) {
      print('   ✅ Table [$table]: $recordCount record trovati su Supabase');
      verifiedCount++;
    } else {
      print(
        '   ❌ Table [$table]: Nessun record o errore (Status ${resV.statusCode} - $bodyV)',
      );
    }
  }

  print('\n================================================================');
  print('=== RISULTATO FINALE DEL TEST PER IL PROFILO ISPETTORE CED   ===');
  print(
    '=== Tabelle verificate con successo su Supabase: $verifiedCount / ${tablesToVerify.length} ===',
  );
  if (verifiedCount == tablesToVerify.length) {
    print('=== 🎉 TEST COMPLETATO CON SUCCESSO AL 100%!                ===');
  } else {
    print('=== ⚠️ ALCUNE TABELLE RICHIEDONO VERIFICA ULTERIORE.        ===');
  }
  print('================================================================\n');

  client.close();
}
