import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST E DIAGNOSTICA BIOSFERA PER IL TECNICO ===\n');

  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );
  final loginHeaders = {'Content-Type': 'application/json'};
  final loginBody = jsonEncode({
    'email': 'ced@certbios.it',
    'password': 'test',
  });

  print('1. RICHIESTA DI LOGIN:');
  print('   URL: $loginUrl');
  print('   Headers: $loginHeaders');
  print('   Body: $loginBody');

  try {
    final loginRes = await http.post(
      loginUrl,
      headers: loginHeaders,
      body: loginBody,
    );
    print('\n2. RISPOSTA LOGIN:');
    print('   Status Code: ${loginRes.statusCode}');
    print('   Headers: ${loginRes.headers}');
    print('   Body Raw: ${loginRes.body}');

    if (loginRes.statusCode != 200) {
      print('❌ Errore Login');
      return;
    }

    final loginData = jsonDecode(loginRes.body);
    final token =
        loginData['token'] ?? loginData['jwt'] ?? loginData['access_token'];
    print(
      '\n   Token estratto: ${token != null ? "${token.toString().substring(0, 25)}..." : "NULL"}',
    );
    print('   User Data: ${loginData['user']}');

    final user = loginData['user'] ?? {};
    final String? codIsp =
        user['cod_isp'] ??
        user['codice_ispettore'] ??
        user['username']?.toString().split('@').first;

    print('\n3. TEST CHIAMATE API LIST-AUDITS (PULL VISITE):');

    final testUrls = [
      'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=MMM1',
      'https://biosfera2.certbios.it/api-jwt/get-audit?id=65147',
      'https://biosfera2.certbios.it/api-jwt/audit-details?id=65147',
      'https://biosfera2.certbios.it/api-jwt/audit?id=65147',
      'https://biosfera2.certbios.it/api-jwt/show-audit?id=65147',
    ];

    for (final urlStr in testUrls) {
      final url = Uri.parse(urlStr);
      print('\n   --- Calling: $urlStr ---');
      final auditRes = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('   Status Code: ${auditRes.statusCode}');
      print('   Body Raw: ${auditRes.body}');
    }
  } catch (e, stack) {
    print('❌ Eccezione durante la richiesta: $e');
    print(stack);
  }
}
