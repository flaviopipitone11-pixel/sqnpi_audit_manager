import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final accounts = [
    {'email': 'ced@certbios.it', 'password': 'test'},
    {'email': 'p.marchese@certbios.it', 'password': 'PiMar1104*'},
  ];

  for (final acc in accounts) {
    print('\n==============================');
    print('Testing login for: ${acc['email']}');
    try {
      final loginReq = await client.postUrl(
        Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
      );
      loginReq.headers.contentType = ContentType.json;
      loginReq.write(jsonEncode(acc));
      final loginRes = await loginReq.close();
      final loginBody = await loginRes.transform(utf8.decoder).join();
      final loginJson = jsonDecode(loginBody);
      final token = loginJson['access_token'];

      if (token == null) {
        print('Login failed: $loginBody');
        continue;
      }
      print('Login OK. User: ${loginJson['user']}');

      // Check B520
      final reqB520 = await client.getUrl(
        Uri.parse(
          'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=B520',
        ),
      );
      reqB520.headers.add('Authorization', 'Bearer $token');
      final resB520 = await reqB520.close();
      final bodyB520 = await resB520.transform(utf8.decoder).join();
      final jsonB520 = jsonDecode(bodyB520);
      final visitsB520 = jsonB520['data'] as List<dynamic>? ?? [];
      print(
        'list-audits?cod_isp=B520 -> success: ${jsonB520['success']}, total: ${jsonB520['total']}, count: ${visitsB520.length}',
      );
      if (visitsB520.isNotEmpty) {
        for (var v in visitsB520) {
          print(
            ' -> Visita: ID ${v['id']}, Azienda: ${v['company_name'] ?? v['ragione_sociale']}, Data: ${v['scheduled_at'] ?? v['data_visita']}',
          );
        }
      }

      // Check without cod_isp
      final reqAll = await client.getUrl(
        Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits'),
      );
      reqAll.headers.add('Authorization', 'Bearer $token');
      final resAll = await reqAll.close();
      final bodyAll = await resAll.transform(utf8.decoder).join();
      final jsonAll = jsonDecode(bodyAll);
      final visitsAll = jsonAll['data'] as List<dynamic>? ?? [];
      print(
        'list-audits (NO cod_isp) -> success: ${jsonAll['success']}, total: ${jsonAll['total']}, count: ${visitsAll.length}',
      );

      // Let's also check other known codes to see if the API is working
      for (final code in ['B193', 'B442', 'MMM1', 'CV57', 'CD57']) {
        final r = await client.getUrl(
          Uri.parse(
            'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
          ),
        );
        r.headers.add('Authorization', 'Bearer $token');
        final rs = await r.close();
        final rb = await rs.transform(utf8.decoder).join();
        final rj = jsonDecode(rb);
        final vl = rj['data'] as List<dynamic>? ?? [];
        print(' - Code $code -> ${vl.length} visits');
      }
    } catch (e) {
      print('Error testing account: $e');
    }
  }

  client.close();
}
