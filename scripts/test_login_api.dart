// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final url = Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login');

  print('==================================================');
  print('STARTING BIOSFERA LOGIN API TESTS');
  print('URL: $url');
  print('==================================================\n');

  final testCases = <Map<String, dynamic>>[
    {
      'name': '1. Valid Credentials (ced@certbios.it)',
      'body': {'email': 'ced@certbios.it', 'password': 'test'},
    },
    {
      'name': '2. Non-existent Inspector (nonexistent@esempio.it)',
      'body': {
        'email': 'nonexistent@esempio.it',
        'password': 'test',
      }
    },
    {
      'name': '3. Wrong Password (ispettore@esempio.it / password_errata)',
      'body': {'email': 'ispettore@esempio.it', 'password': 'password_errata'},
    },
    {
      'name': '4. Missing Password',
      'body': {'email': 'ispettore@esempio.it'},
    },
    {
      'name': '5. Missing Email',
      'body': {'password': 'la_password'},
    },
    {'name': '6. Empty Payload', 'body': {}},
  ];

  final client = HttpClient();

  for (final testCase in testCases) {
    print('--------------------------------------------------');
    print('Executing Test Case: ${testCase['name']}');
    print('Payload: ${jsonEncode(testCase['body'])}');
    print('--------------------------------------------------');

    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final bodyString = jsonEncode(testCase['body']);
      request.write(bodyString);

      final response = await request.close();

      print('Status Code: ${response.statusCode}');
      print('Headers:');
      response.headers.forEach((name, values) {
        print('  $name: ${values.join(', ')}');
      });

      final responseBody = await response.transform(utf8.decoder).join();
      print('\nResponse Body:');
      try {
        final decoded = jsonDecode(responseBody);
        final encoder = const JsonEncoder.withIndent('  ');
        print(encoder.convert(decoded));
      } catch (e) {
        print(responseBody);
      }
    } catch (e) {
      print('Error executing request: $e');
    }
    print('\n');
  }

  client.close();
  print('==================================================');
  print('ALL TESTS COMPLETED');
  print('==================================================');
}
