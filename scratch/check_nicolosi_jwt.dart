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
    final loginJson = jsonDecode(loginBody);
    final token = loginJson['access_token'];

    // Decode JWT payload
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payloadBase64 = parts[1];
        String normalized = base64Url.normalize(payloadBase64);
        String payloadString = utf8.decode(base64Url.decode(normalized));
        print('JWT Payload: $payloadString');
      }
    } catch (e) {
      print('Failed to decode JWT: $e');
    }
  }

  client.close();
}
