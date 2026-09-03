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

  // 1. Inspect a real visit from B193 or CV57 to see structure & fields
  print('=== INSPECTING VISITS FROM B193 ===');
  final rB193 = await client.getUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=B193'),
  );
  rB193.headers.add('Authorization', 'Bearer $token');
  final rsB193 = await rB193.close();
  final bodyB193 = await rsB193.transform(utf8.decoder).join();
  final jsonB193 = jsonDecode(bodyB193);
  final visitsB193 = jsonB193['data'] as List<dynamic>? ?? [];
  if (visitsB193.isNotEmpty) {
    print('Sample visit keys: ${visitsB193.first.keys}');
    print('Sample visit: ${jsonEncode(visitsB193.first)}');
  }

  // 2. Scan possible inspector codes (B500-B550, NICO, MNIC, etc.)
  print('\n=== SCANNING POTENTIAL CODES ===');
  final codesToTest = <String>[];
  for (int i = 500; i <= 550; i++) {
    codesToTest.add('B$i');
    codesToTest.add('b$i');
  }
  for (final prefix in [
    'N',
    'NIC',
    'MN',
    'NICOLOSI',
    'MNIC',
    'B0520',
    '0520',
    '520',
  ]) {
    codesToTest.add(prefix);
  }

  final foundWithVisits = <String, int>{};

  for (final c in codesToTest) {
    final req = await client.getUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$c'),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    try {
      final json = jsonDecode(body);
      final count = (json['data'] as List?)?.length ?? 0;
      if (count > 0) {
        foundWithVisits[c] = count;
        print('FOUND VISITS for code $c: $count visits!');
        for (var v in json['data']) {
          print(
            '   -> Visita ${v['id']}: ${v['company_name'] ?? v['ragione_sociale']} (${v['inspector_name'] ?? v['tecnico'] ?? ''})',
          );
        }
      }
    } catch (_) {}
  }

  print('\n=== SUMMARY OF FOUND CODES IN RANGE ===');
  foundWithVisits.forEach((k, v) {
    print('Code $k: $v visits');
  });

  client.close();
}
