import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // Login with p.marchese@certbios.it
  print('Logging in...');
  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(
    jsonEncode({'email': 'p.marchese@certbios.it', 'password': 'PiMar1104*'}),
  );
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];

  print('User data: ${loginJson['user']}');
  print('Token obtained successfully.');

  // Test list-audits without cod_isp
  final reqNoIsp = await client.getUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits'),
  );
  reqNoIsp.headers.add('Authorization', 'Bearer $token');
  final resNoIsp = await reqNoIsp.close();
  final bodyNoIsp = await resNoIsp.transform(utf8.decoder).join();
  final jsonNoIsp = jsonDecode(bodyNoIsp);
  print(
    'list-audits (NO cod_isp): total = ${jsonNoIsp['total']}, data length = ${(jsonNoIsp['data'] as List?)?.length}',
  );

  // Test other endpoints if any (e.g. list-inspectors or list-all-audits or list-users)
  for (final endpoint in [
    'list-audits',
    'list-inspectors',
    'list-all-audits',
    'inspectors',
    'audits',
  ]) {
    try {
      final req = await client.getUrl(
        Uri.parse('https://biosfera2.certbios.it/api-jwt/$endpoint'),
      );
      req.headers.add('Authorization', 'Bearer $token');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      print(
        'Endpoint /$endpoint status=${res.statusCode}: ${body.substring(0, body.length > 200 ? 200 : body.length)}',
      );
    } catch (e) {
      print('Endpoint /$endpoint error: $e');
    }
  }

  client.close();
}
