import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];

  final endpoints = [
    'list-inspectors',
    'inspectors',
    'ispettori',
    'list-ispettori',
    'users',
    'user-list',
    'collaboratori',
    'list-collaboratori',
    'tecnici',
    'list-tecnici',
    'inspector?code=B520',
    'inspector?cod_isp=B520',
    'user?code=B520',
  ];

  for (final ep in endpoints) {
    try {
      final req = await client.getUrl(
        Uri.parse('https://biosfera2.certbios.it/api-jwt/$ep'),
      );
      req.headers.add('Authorization', 'Bearer $token');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      print(
        'Endpoint $ep -> status: ${res.statusCode}, body: ${body.substring(0, body.length > 200 ? 200 : body.length)}',
      );
    } catch (e) {
      print('Endpoint $ep -> error: $e');
    }
  }

  client.close();
}
