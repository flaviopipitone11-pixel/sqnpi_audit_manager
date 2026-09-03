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

  print(
    'Calcolando le visite totali su Biosfera (effettuando la scansione dei codici ispettore)...',
  );

  // Let's generate candidate codes: B001 to B999, CV01-CV99, CD01-CD99, A01-A99
  final allCodes = <String>[];
  for (int i = 1; i <= 999; i++) {
    allCodes.add('B$i');
    if (i < 100) {
      allCodes.add('B${i.toString().padLeft(3, '0')}');
      allCodes.add('CV$i');
      allCodes.add('CD$i');
      allCodes.add('A${i.toString().padLeft(2, '0')}');
    }
  }

  int totalVisitsFound = 0;
  final foundCodes = <String, int>{};

  // Process in batches of 50 concurrent requests
  final batchSize = 50;
  for (int i = 0; i < allCodes.length; i += batchSize) {
    final batch = allCodes.sublist(
      i,
      i + batchSize > allCodes.length ? allCodes.length : i + batchSize,
    );

    await Future.wait(
      batch.map((code) async {
        try {
          final req = await client.getUrl(
            Uri.parse(
              'https://biosfera2.certbios.it/api-jwt/list-audits?cod_isp=$code',
            ),
          );
          req.headers.add('Authorization', 'Bearer $token');
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();
          final json = jsonDecode(body);
          final list = json['data'] as List<dynamic>? ?? [];
          if (list.isNotEmpty) {
            foundCodes[code] = list.length;
            totalVisitsFound += list.length;
          }
        } catch (_) {}
      }),
    );
  }

  print('\n=== SCAN COMPLETE ===');
  print('Total inspector codes with visits: ${foundCodes.length}');
  print('Total visits assigned across all these codes: $totalVisitsFound');

  // Sort and print the top 10 codes with most visits
  var sortedCodes = foundCodes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  print('\nTop 10 codes by visit count:');
  for (var i = 0; i < 10 && i < sortedCodes.length; i++) {
    print(' - ${sortedCodes[i].key}: ${sortedCodes[i].value} visits');
  }

  client.close();
}
