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

  for (final code in ['B520', 'b520', '520', 'B-520']) {
    final r = await client.getUrl(
      Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
      ),
    );
    r.headers.add('Authorization', 'Bearer $token');
    final rs = await r.close();
    final rb = await rs.transform(utf8.decoder).join();
    final rj = jsonDecode(rb);
    print(
      'cod_isp=$code -> status=${rs.statusCode}, success=${rj['success']}, total=${rj['total']}, visits=${(rj['data'] as List?)?.length}',
    );
  }

  client.close();
}
