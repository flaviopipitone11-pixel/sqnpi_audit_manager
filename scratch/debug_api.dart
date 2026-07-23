import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  // 1. Login
  print('Logging in...');
  final loginReq = await client.postUrl(Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'));
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'p.marchese@certbios.it', 'password': 'PiMar1104*'}));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];
  print('Token: ${token?.substring(0, 20)}...');
  
  if (token == null) {
    print('Failed to get token: $loginJson');
    return;
  }
  
  // 3. List Audits without cod_isp
  print('\nList Audits (No cod_isp)...');
  final req1 = await client.getUrl(Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits'));
  req1.headers.add('Authorization', 'Bearer $token');
  final res1 = await req1.close();
  final body1 = await res1.transform(utf8.decoder).join();
  print('Response 1: $body1');
  
  // 4. List Audits with cod_isp=CV57
  print('\nList Audits (cod_isp=CV57)...');
  final req2 = await client.getUrl(Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=CV57'));
  req2.headers.add('Authorization', 'Bearer $token');
  final res2 = await req2.close();
  final body2 = await res2.transform(utf8.decoder).join();
  print('Response 2: $body2');

  // 5. List Audits with cod_isp=CD57
  print('\nList Audits (cod_isp=CD57)...');
  final req3 = await client.getUrl(Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=CD57'));
  req3.headers.add('Authorization', 'Bearer $token');
  final res3 = await req3.close();
  final body3 = await res3.transform(utf8.decoder).join();
  print('Response 3: $body3');

  client.close();
}
