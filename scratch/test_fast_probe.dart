import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('=== PROBA PARALLELA NC ANNI PRECEDENTI ID 65000..65500 ===\n');
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

  final idsToTest = List.generate(300, (index) => 65000 + index);

  final results = await Future.wait(
    idsToTest.map((id) async {
      try {
        final req = await client.getUrl(
          Uri.parse(
            'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
          ),
        );
        req.headers.add('Authorization', 'Bearer $token');
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final decoded = jsonDecode(body);
          final data = decoded['data'];
          if (data != null && data['visit_companies'] != null) {
            final comp = data['visit_companies'];
            final prevNc =
                data['previous_nc_items'] ??
                data['visit_previous_nc_managements'] ??
                [];
            return {
              'id': id,
              'company': comp['ragione_sociale'],
              'cuaa': comp['cuaa'],
              'ncCount': (prevNc as List).length,
              'ncItems': prevNc,
            };
          }
        }
      } catch (_) {}
      return null;
    }),
  );

  final validResults = results.whereType<Map<String, dynamic>>().toList();
  print('Incarichi validi trovati nel range: ${validResults.length}');

  for (var res in validResults) {
    if (res['ncCount'] > 0 ||
        res['company'].toString().contains('MMM1') ||
        res['cuaa'].toString().contains('MMM1')) {
      print('----------------------------------------------------');
      print('🔥 INCARICO TROVATO ID: ${res['id']}');
      print('   Azienda: ${res['company']} (CUAA: ${res['cuaa']})');
      print('   NC Anni Precedenti count: ${res['ncCount']}');
      print('   NC Items: ${res['ncItems']}');
    }
  }

  client.close();
}
