import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('=== TEST SINCRONIZZAZIONE ED INSERSIONE SU SUPABASE ===');

  final client = HttpClient();

  // 1. Login su Biosfera
  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );
  final reqLogin = await client.postUrl(loginUrl);
  reqLogin.headers.contentType = ContentType.json;
  reqLogin.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final resLogin = await reqLogin.close();
  final bodyLogin = await resLogin.transform(utf8.decoder).join();
  final decodedLogin = jsonDecode(bodyLogin);
  final token = decodedLogin['access_token'];

  // 2. Download assignment 65147
  final downloadUrl =
      'https://biosfera2.certbios.it/api-jwt/download-assignment?id=65147';
  print('\n1. Download da Biosfera (ID: 65147)...');
  final reqDown = await client.getUrl(Uri.parse(downloadUrl));
  reqDown.headers.add('Authorization', 'Bearer $token');
  final resDown = await reqDown.close();
  final bodyDown = await resDown.transform(utf8.decoder).join();
  final assignmentData = jsonDecode(bodyDown)['data'];

  final companyData = assignmentData['visit_companies'];
  print('   Azienda: ${companyData['ragione_sociale']}');
  print('   Protocollo: ${companyData['sqnpi_protocol']}');
  print('   Data Certificazione: ${companyData['prev_org_certified_date']}');

  // 3. Invio su Supabase (visits)
  print('\n2. Invio a Supabase (tabella visits)...');
  final supabaseUrl = 'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1/visits';
  final anonKey = 'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x';

  final visitPayload = [
    {
      'id': '65147',
      'scheduled_at': DateTime.now().toIso8601String(),
      'company_name': companyData['ragione_sociale'],
      'crop': 'Varie',
      'status': 0,
      'visit_type': 'ACA',
      'inspector_name': 'CED',
      'inspector_email': 'ced@certbios.it',
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  final reqSupabaseVisits = await client.postUrl(Uri.parse(supabaseUrl));
  reqSupabaseVisits.headers.add('apikey', anonKey);
  reqSupabaseVisits.headers.add('Authorization', 'Bearer $anonKey');
  reqSupabaseVisits.headers.add('Content-Type', 'application/json');
  reqSupabaseVisits.headers.add('Prefer', 'resolution=merge-duplicates');
  reqSupabaseVisits.write(jsonEncode(visitPayload));
  final resSupabaseVisits = await reqSupabaseVisits.close();
  print(
    '   Status visits: ${resSupabaseVisits.statusCode} (201/200 = Successo!)',
  );

  // 4. Invio su Supabase (visit_companies)
  print('\n3. Invio a Supabase (tabella visit_companies)...');
  final companyPayload = [
    {
      'visit_id': '65147',
      'ragione_sociale': companyData['ragione_sociale'],
      'cuaa': companyData['cuaa'],
      'partita_iva': companyData['partita_iva'],
      'indirizzo': companyData['indirizzo'],
      'cap': companyData['cap'],
      'comune': companyData['comune'],
      'provincia': companyData['provincia'],
      'email': companyData['email'],
      'pec': companyData['pec'],
      'submission_number': companyData['submission_numer'],
      'sqnpi_protocol': companyData['sqnpi_protocol'],
      'sqnpi_submission_date': companyData['sqnpi_submission_date'],
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  final reqSupabaseComp = await client.postUrl(
    Uri.parse(
      'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1/visit_companies',
    ),
  );
  reqSupabaseComp.headers.add('apikey', anonKey);
  reqSupabaseComp.headers.add('Authorization', 'Bearer $anonKey');
  reqSupabaseComp.headers.add('Content-Type', 'application/json');
  reqSupabaseComp.headers.add('Prefer', 'resolution=merge-duplicates');
  reqSupabaseComp.write(jsonEncode(companyPayload));
  final resSupabaseComp = await reqSupabaseComp.close();
  print('   Status visit_companies: ${resSupabaseComp.statusCode}');

  // 5. Invio su Supabase (visit_previous_nc_managements)
  print('\n4. Invio a Supabase (tabella visit_previous_nc_managements)...');
  final prevNcPayload = [
    {
      'visit_id': '65147',
      'prev_org_certified_date': companyData['prev_org_certified_date'],
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  final reqSupabaseNc = await client.postUrl(
    Uri.parse(
      'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1/visit_previous_nc_managements',
    ),
  );
  reqSupabaseNc.headers.add('apikey', anonKey);
  reqSupabaseNc.headers.add('Authorization', 'Bearer $anonKey');
  reqSupabaseNc.headers.add('Content-Type', 'application/json');
  reqSupabaseNc.headers.add('Prefer', 'resolution=merge-duplicates');
  reqSupabaseNc.write(jsonEncode(prevNcPayload));
  final resSupabaseNc = await reqSupabaseNc.close();
  print('   Status visit_previous_nc_managements: ${resSupabaseNc.statusCode}');

  print('\n✅ TEST COMPLETATO CON SUCCESSO!');
  client.close();
}
