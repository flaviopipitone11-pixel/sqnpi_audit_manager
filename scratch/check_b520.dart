import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  // Use CED account to be sure we have permissions
  loginReq.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));

  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();

  if (loginRes.statusCode == 200) {
    final loginJson = jsonDecode(loginBody);
    final token = loginJson['access_token'];

    print('Verifying visits for inspector code: B520...');
    final req = await client.getUrl(
      Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=B520',
      ),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    try {
      final json = jsonDecode(body);
      final list = json['data'] as List<dynamic>? ?? [];
      print('✅ Code B520 has ${list.length} visits.');
      if (list.isNotEmpty) {
        print('Sample visit: ${list.first}');
      }
    } catch (e) {
      print('Could not parse response: $body');
    }
  }

  client.close();
}
