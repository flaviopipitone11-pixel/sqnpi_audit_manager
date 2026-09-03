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
    '/api-jwt/inspectors',
    '/api-jwt/inspector/B520',
    '/api-jwt/users',
    '/api-jwt/user/B520',
    '/api-jwt/anagrafica/B520',
    '/api-jwt/ispettori',
    '/api-jwt/tecnici',
  ];

  print('Probing endpoints to see if we can find B520...');
  for (var ep in endpoints) {
    try {
      final req = await client.getUrl(
        Uri.parse('https://biosfera2.certbios.it$ep'),
      );
      req.headers.add('Authorization', 'Bearer $token');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      print('Endpoint: $ep -> Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print(
          '  Response (first 150 chars): ${body.length > 150 ? body.substring(0, 150) : body}',
        );
      }
    } catch (e) {
      print('Endpoint: $ep -> Error');
    }
  }

  client.close();
}
