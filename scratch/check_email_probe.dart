import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // Try login attempts or probe user info
  final candidates = [
    'b520@certbios.it',
    'b.520@certbios.it',
    'ispettore.b520@certbios.it',
  ];

  for (final email in candidates) {
    final loginReq = await client.postUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
    );
    loginReq.headers.contentType = ContentType.json;
    loginReq.write(
      jsonEncode({'email': email, 'password': 'wrong_password_test'}),
    );
    final loginRes = await loginReq.close();
    final loginBody = await loginRes.transform(utf8.decoder).join();
    print('Email $email -> status: ${loginRes.statusCode}, body: $loginBody');
  }

  client.close();
}
