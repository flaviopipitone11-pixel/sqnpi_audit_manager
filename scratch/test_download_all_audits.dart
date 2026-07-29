import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('=== TEST DOWNLOAD TUTTI GLI INCARICHI E NC ANNI PRECEDENTI ===\n');
  final client = HttpClient();

  // 1. Login su Biosfera per p.marchese@certbios.it
  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );
  final reqLogin = await client.postUrl(loginUrl);
  reqLogin.headers.contentType = ContentType.json;
  reqLogin.write(
    jsonEncode({'email': 'p.marchese@certbios.it', 'password': 'PiMar1104*'}),
  );
  final resLogin = await reqLogin.close();
  final bodyLogin = await resLogin.transform(utf8.decoder).join();
  final decodedLogin = jsonDecode(bodyLogin);
  final token = decodedLogin['access_token'];
  print('✅ Login effettuato per p.marchese@certbios.it!');

  // 2. Chiamata a list-audits
  final listUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/list-audits',
  );
  final reqList = await client.getUrl(listUrl);
  reqList.headers.add('Authorization', 'Bearer $token');
  final resList = await reqList.close();
  final bodyList = await resList.transform(utf8.decoder).join();
  final decodedList = jsonDecode(bodyList);

  final List audits = decodedList['data'] ?? [];
  print(
    'Trovati ${audits.length} incarichi in list-audits per l\'ispettore.\n',
  );

  for (final audit in audits) {
    final id = audit['id_incarico'] ?? audit['id'];
    final company = audit['ragione_sociale'] ?? audit['company_name'] ?? '';
    final cuaa = audit['cuaa'] ?? '';

    print('----------------------------------------------------');
    print('📌 AUDIT ID: $id | Azienda: $company | CUAA: $cuaa');

    // Call download-assignment
    final downUrl = Uri.parse(
      'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
    );
    final reqDown = await client.getUrl(downUrl);
    reqDown.headers.add('Authorization', 'Bearer $token');
    final resDown = await reqDown.close();
    final bodyDown = await resDown.transform(utf8.decoder).join();

    try {
      final decodedDown = jsonDecode(bodyDown);
      final data = decodedDown['data'];
      if (data != null) {
        final visitComp = data['visit_companies'];
        if (visitComp != null) {
          print(
            '   Azienda Incarico: ${visitComp['ragione_sociale']} (CUAA: ${visitComp['cuaa']})',
          );
          print(
            '   Data Cert: ${visitComp['prev_org_certified_date']} | Data Sanz: ${visitComp['prev_org_sanctioned_date']}',
          );
        }

        final prevNcList =
            data['visit_previous_nc_managements'] ??
            data['visit_previous_ncs'] ??
            [];
        print('   NC Anni Precedenti trovate: ${(prevNcList as List).length}');
        for (var nc in prevNcList) {
          print(
            '      -> NC ID: ${nc['id']} | Anno: ${nc['year']} | Codice: ${nc['nc_code']} | Desc: ${nc['description']} | Risoluzione/Esito: ${nc['resolution_status'] ?? nc['outcome']}',
          );
        }

        // Check if there are other fields in data
        print('   Tasti/Oggetti disponibili in data: ${data.keys.toList()}');
      } else {
        print('   ⚠️ Nessun dato restituito da download-assignment per ID $id');
      }
    } catch (e) {
      print('   ❌ Errore parsing download-assignment per ID $id: $e');
    }
  }

  client.close();
}
