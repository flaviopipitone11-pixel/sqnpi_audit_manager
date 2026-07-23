import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final loginUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
  );

  print('--- Effettuo il login per ottenere il token ---');
  final client = HttpClient();

  String? token;
  String? inspectorCode;

  try {
    final request = await client.postUrl(loginUrl);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({'email': 'p.marchese@certbios.it', 'password': 'PiMar1104*'}),
    );
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody);
      token = decoded['access_token'];
      inspectorCode = decoded['user']?['user_metadata']?['inspector_code'];
      print('Token ottenuto con successo. Inspector code: $inspectorCode');
    } else {
      print('Login fallito: ${response.statusCode}');
      return;
    }
  } catch (e) {
    print('Errore di login: $e');
    return;
  }

  if (token == null || inspectorCode == null) {
    print('Token o inspectorCode mancante.');
    return;
  }

  // Chiamata a list-audits
  final listUrl = Uri.parse(
    'https://biosfera2.certbios.it/api-jwt/list-audits',
  );

  print('\n--- Iniziando la richiesta verso: $listUrl ---');

  try {
    final request = await client.getUrl(listUrl);
    request.headers.add('Authorization', 'Bearer $token');
    request.headers.contentType = ContentType.json;
    final response = await request.close();

    print('Status Code: ${response.statusCode}');

    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(responseBody);

        final audits = decoded['data'] as List?;
        print('Trovate ${audits?.length ?? 0} visite assegnate.');

        print('Risposta JSON formattata:');
        print(const JsonEncoder.withIndent('  ').convert(decoded));
      } catch (e) {
        print('Risposta Body (non JSON):');
        print(responseBody);
      }
    } else {
      print('Errore nella richiesta. Body:');
      print(responseBody);
    }
  } catch (e) {
    print('Errore durante la richiesta list-audits: $e');
  } finally {
    client.close();
  }
}
