import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'm.nicolosi@certbios.it', 'password': 'NicoMic2504*'}));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];

  print(
    'Searching across Biosfera inspector codes for Bongiovanni Saverio (19AI01872)...',
  );

  // Let's generate candidate codes: B001 to B999, CV01-CV99, CD01-CD99, A01-A99
  final allCodes = <String>[];
  for (int i = 1; i <= 999; i++) {
    allCodes.add('B$i');
    if (i < 100) {
      allCodes.add('B${i.toString().padLeft(3, '0')}');
      allCodes.add('CV$i');
      allCodes.add('CD$i');
    }
  }

  int totalVisitsFound = 0;
  final foundCodes = <String, int>{};
  Map<String, dynamic>? matchingVisit;
  String? matchingCode;

  // Process in batches of 20 concurrent requests
  final batchSize = 20;
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
            for (final v in list) {
              final str = jsonEncode(v).toUpperCase();
              if (str.contains('BONGIOVANNI') ||
                  str.contains('BNGSVR') ||
                  str.contains('19AI01872')) {
                matchingVisit = v;
                matchingCode = code;
                print('\n🎯 FOUND BONGIOVANNI SAVERIO UNDER CODE: $code !');
                print('Visit: $v\n');
              }
            }
          }
        } catch (_) {}
      }),
    );
  }

  print('\n=== SCAN COMPLETE ===');
  print('Total inspector codes with visits: ${foundCodes.length}');
  foundCodes.forEach((c, n) => print(' - $c: $n visits'));

  if (matchingVisit != null) {
    print('\n========================================');
    print('🎯 MATCH FOUND!');
    print('Inspector Code: $matchingCode');
    print('Visit Details: $matchingVisit');
  } else {
    print(
      '\n❌ Bongiovanni Saverio (19AI01872) not found in any inspector audit list on Biosfera.',
    );
  }

  client.close();
}
