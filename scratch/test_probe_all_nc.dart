import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('=== RICERCA INCARICHI CON NC ANNI PRECEDENTI SU BIOSFERA ===\n');
  final client = HttpClient();

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
  print('✅ Login effettuato su Biosfera!');

  int foundCount = 0;
  int foundWithNc = 0;

  // Probiamo un range di ID attorno a 65100..65200
  for (int id = 65100; id <= 65200; id++) {
    try {
      final downUrl = Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
      );
      final reqDown = await client.getUrl(downUrl);
      reqDown.headers.add('Authorization', 'Bearer $token');
      final resDown = await reqDown.close();
      final bodyDown = await resDown.transform(utf8.decoder).join();

      final decodedDown = jsonDecode(bodyDown);
      final data = decodedDown['data'];
      if (data != null && data['visit_companies'] != null) {
        foundCount++;
        final comp = data['visit_companies'];
        final prevNc =
            data['previous_nc_items'] ??
            data['visit_previous_nc_managements'] ??
            [];
        final ncCount = (prevNc as List).length;

        if (ncCount > 0 ||
            comp['ragione_sociale'].toString().contains('MMM1') ||
            comp['cuaa'].toString().contains('MMM1')) {
          foundWithNc++;
          print('----------------------------------------------------');
          print('🔥 TROVATO INCARICO ID: $id');
          print(
            '   Azienda: ${comp['ragione_sociale']} (CUAA: ${comp['cuaa']})',
          );
          print('   NC Anni Precedenti Trovate: $ncCount');
          print('   Oggetti NC: $prevNc');
        }
      }
    } catch (_) {}
  }

  print('\n=== SINTESI ===');
  print('Incarichi validi trovati nel range 65100..65200: $foundCount');
  print('Incarichi con NC anni precedenti o MMM1: $foundWithNc');

  client.close();
}
