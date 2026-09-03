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

  final req = await client.getUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=B193'),
  );
  req.headers.add('Authorization', 'Bearer $token');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body);

  if (json['data'] != null && json['data'].isNotEmpty) {
    print('Visit sample:');
    print(JsonEncoder.withIndent('  ').convert(json['data'][0]));
  }

  client.close();
}
