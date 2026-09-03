import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  print('Logging in as m.nicolosi@certbios.it...');
  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(
    jsonEncode({'email': 'm.nicolosi@certbios.it', 'password': 'NicoMic2504*'}),
  );

  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();

  if (loginRes.statusCode == 200) {
    print('✅ Login successful!');
    final loginJson = jsonDecode(loginBody);
    final token = loginJson['access_token'];

    print('Fetching visits...');
    // Try fetching list-audits without specifying cod_isp, maybe it defaults to the logged-in user
    final req = await client.getUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits'),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    print('Response status: ${res.statusCode}');
    try {
      final json = jsonDecode(body);
      final list = json['data'] as List<dynamic>? ?? [];
      print('Found ${list.length} visits.');
      if (list.isNotEmpty) {
        print('First visit: ${list.first}');
      } else {
        print('Raw response: $body');
      }
    } catch (e) {
      print('Could not parse response as JSON. Body: $body');
    }
  } else {
    print('❌ Login failed with status: ${loginRes.statusCode}');
    print('Response: $loginBody');
  }

  client.close();
}
