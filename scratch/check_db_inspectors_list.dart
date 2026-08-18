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

  print('User from Biosfera login: ${loginJson['user']}');
  client.close();
}
