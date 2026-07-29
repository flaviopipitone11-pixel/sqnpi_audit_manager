import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print(
    '=== TEST DOWNLOAD SPECIFICO NC ANNI PRECEDENTI PER ID 65147 E ALTRI ===\n',
  );
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

  // Test ID 65147
  final downUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/download-assignment?id=65147',
  );
  final reqDown = await client.getUrl(downUrl);
  reqDown.headers.add('Authorization', 'Bearer $token');
  final resDown = await reqDown.close();
  final bodyDown = await resDown.transform(utf8.decoder).join();

  final data = jsonDecode(bodyDown)['data'];
  print('JSON Keys in data per ID 65147: ${data.keys.toList()}');

  print('\nContenuto completo di data per ID 65147:');
  print(const JsonEncoder.withIndent('  ').convert(data));

  client.close();
}
