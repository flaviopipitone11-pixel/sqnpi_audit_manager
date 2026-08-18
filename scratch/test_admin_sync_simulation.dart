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

  // Simulate Admin mode multi-inspector fetch:
  final targetInspectorCodes = {'MMM1', 'CV57', 'CD57'};
  final Map<String, dynamic> uniqueCloudVisitsMap = {};

  print(
    '🔍 Simulation: Searching Cloud visits for ${targetInspectorCodes.length} inspectors (${targetInspectorCodes.join(", ")})...',
  );

  for (final code in targetInspectorCodes) {
    final url = Uri.parse(
      'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
    );
    final req = await client.getUrl(url);
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    if (json['success'] == true && json['data'] is List) {
      final list = json['data'] as List<dynamic>;
      print('   -> Inspector $code: found ${list.length} visits');
      for (final v in list) {
        final id = v['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          uniqueCloudVisitsMap[id] = v;
        }
      }
    }
  }

  print(
    '\n✅ SUCCESS: Total unique Cloud visits fetched: ${uniqueCloudVisitsMap.length}',
  );
  client.close();
}
