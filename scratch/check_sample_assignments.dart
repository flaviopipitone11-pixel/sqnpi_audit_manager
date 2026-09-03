import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // Login
  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];

  // Test download-assignment for sample visits of found codes
  final sampleVisits = {
    'B517': '65556',
    'B529': '65314',
    'B533': '64964',
    'B535': '65015',
    'B537': '65311',
    'B544': '65309',
  };

  for (final entry in sampleVisits.entries) {
    final code = entry.key;
    final visitId = entry.value;
    final req = await client.getUrl(
      Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$visitId',
      ),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    try {
      final json = jsonDecode(body);
      final data = json['data'];
      print('Code $code (Visit $visitId):');
      print(
        '   inspector_name: ${data?['inspector_name'] ?? data?['ispettore'] ?? data?['tecnico']}',
      );
      print(
        '   inspector_email: ${data?['inspector_email'] ?? data?['email_ispettore']}',
      );
      print(
        '   inspector_code: ${data?['inspector_code'] ?? data?['cod_isp']}',
      );
    } catch (e) {
      print('Code $code error: $e');
    }
  }

  client.close();
}
