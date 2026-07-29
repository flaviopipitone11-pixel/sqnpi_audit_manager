import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print(
    '=== TEST DOWNLOAD ASSIGNMENT DIRETTI SU RANGE ID (65140..65160) ===\n',
  );
  final client = HttpClient();

  // 1. Login su Biosfera per ced@certbios.it
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
  print('✅ Login effettuato!');

  for (int id = 65140; id <= 65155; id++) {
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
      if (data != null && data['visit_companies'] != null) {
        final comp = data['visit_companies'];
        final prevNc =
            data['visit_previous_nc_managements'] ??
            data['visit_previous_ncs'] ??
            [];
        print(
          '📌 FOUND INCARICO ID: $id | Azienda: ${comp['ragione_sociale']} | CUAA: ${comp['cuaa']}',
        );
        print(
          '   Date Cert: ${comp['prev_org_certified_date']} | Date Sanz: ${comp['prev_org_sanctioned_date']}',
        );
        print('   NC Anni Precedenti count: ${(prevNc as List).length}');
        for (var nc in prevNc) {
          print(
            '      -> NC ID: ${nc['id']} | Anno: ${nc['year']} | Codice: ${nc['nc_code']} | Desc: ${nc['description']}',
          );
        }
      }
    } catch (_) {}
  }

  client.close();
}
