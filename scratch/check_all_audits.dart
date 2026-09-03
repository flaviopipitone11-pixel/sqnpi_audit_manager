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

  // Test list-audits without cod_isp
  print('Trying list-audits without cod_isp...');
  try {
    final req = await client.getUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits'),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    
    if (res.statusCode == 200) {
        final json = jsonDecode(body);
        if (json['data'] != null && json['data'] is List) {
           final list = json['data'] as List;
           print('Found ${list.length} audits.');
           
           // search for bongiovanni
           for (final v in list) {
              final str = jsonEncode(v).toUpperCase();
              if (str.contains('BONGIOVANNI') || str.contains('19AI01872')) {
                  print('FOUND BONGIOVANNI IN ALL AUDITS:');
                  print(v);
              }
           }
        } else {
            print('Data is not a list: ${body.substring(0, 200)}');
        }
    } else {
        print('Error body: $body');
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
