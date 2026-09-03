import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(
    jsonEncode({'email': 'm.nicolosi@certbios.it', 'password': 'NicoMic2504*'}),
  );

  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();

  if (loginRes.statusCode == 200) {
    print('Login Response Body: $loginBody');
  }

  client.close();
}
