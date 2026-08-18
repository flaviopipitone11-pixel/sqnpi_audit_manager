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

  // Test various candidate inspector codes
  final testCodes = [
    'CED',
    'MMM1',
    'CV57',
    'CD57',
    'ADMIN',
    'ALL',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
  ];

  for (final code in testCodes) {
    final req = await client.getUrl(
      Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
      ),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    print(
      'cod_isp=$code -> total: ${json['total']}, length: ${(json['data'] as List?)?.length}',
    );
    if ((json['data'] as List?)?.isNotEmpty == true) {
      for (var item in json['data']) {
        print(
          '   Visit: ${item['id']} - ${item['company_name'] ?? item['ragione_sociale']} (isp: ${item['inspector_code'] ?? item['cod_isp']})',
        );
      }
    }
  }

  client.close();
}
