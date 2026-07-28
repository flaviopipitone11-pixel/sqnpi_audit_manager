import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();

  print('=== LOGIN CON CED (ced@certbios.it / test) ===');
  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );

  final request = await client.postUrl(loginUrl);
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final decodedLogin = jsonDecode(body);

  final token = decodedLogin['access_token'];
  final userMeta = decodedLogin['user']?['user_metadata'];
  final inspectorCode = userMeta?['inspector_code'] ?? 'MMM1';

  print('✅ Login CED OK!');
  print('   Token: ${token.toString().substring(0, 20)}...');
  print('   Inspector Code: $inspectorCode');

  // 1. Chiamata list-audits con cod_isp
  final listUrl =
      'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$inspectorCode';
  print('\n=== CHIAMATA: GET $listUrl ===');
  final reqList = await client.getUrl(Uri.parse(listUrl));
  reqList.headers.add('Authorization', 'Bearer $token');
  final resList = await reqList.close();
  final bodyList = await resList.transform(utf8.decoder).join();

  print('Status: ${resList.statusCode}');
  print('Body: $bodyList');

  final decodedList = jsonDecode(bodyList);
  final audits = decodedList['data'] as List<dynamic>? ?? [];

  final idsToTest = <String>[];
  for (final a in audits) {
    if (a['id'] != null) idsToTest.add(a['id'].toString());
  }

  if (idsToTest.isEmpty) {
    idsToTest.add('65147');
  }

  // 2. Chiamata download-assignment per l'utente CED
  for (final id in idsToTest) {
    final downloadUrl =
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id';
    print('\n=== CHIAMATA: GET $downloadUrl ===');
    final reqDown = await client.getUrl(Uri.parse(downloadUrl));
    reqDown.headers.add('Authorization', 'Bearer $token');
    final resDown = await reqDown.close();
    final bodyDown = await resDown.transform(utf8.decoder).join();

    print('Status Code: ${resDown.statusCode}');
    if (resDown.statusCode == 200) {
      print('✅ 200 OK!');
      print(bodyDown);
    } else {
      print('❌ Errore (${resDown.statusCode})');
      print(
        bodyDown.length > 500 ? '${bodyDown.substring(0, 500)}...' : bodyDown,
      );
    }
  }

  client.close();
}
