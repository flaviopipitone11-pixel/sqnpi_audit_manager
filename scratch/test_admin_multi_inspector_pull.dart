import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // Login with p.marchese@certbios.it
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

  // List of known inspector codes
  final inspectorCodes = ['MMM1', 'CV57', 'CD57'];
  final Map<String, dynamic> allVisitsMap = {};

  for (final code in inspectorCodes) {
    final req = await client.getUrl(
      Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
      ),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    final visits = json['data'] as List<dynamic>? ?? [];
    print('Fetched ${visits.length} visits for inspector code: $code');
    for (final v in visits) {
      final id = v['id'].toString();
      allVisitsMap[id] = v;
    }
  }

  print(
    '\nTOTAL UNIQUE VISITS FOUND FOR ALL INSPECTORS: ${allVisitsMap.length}',
  );
  allVisitsMap.forEach((id, v) {
    print(
      ' - Visita ID $id: ${v['company_name'] ?? v['ragione_sociale']} (coltura: ${v['coltura']})',
    );
  });

  client.close();
}
