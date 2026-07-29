import 'dart:convert';
import 'package:dio/dio.dart';

Future<void> main() async {
  print('=== TEST DOWNLOAD INCARICHI E NC PRECEDENTI ===\n');

  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];
  print('✅ Login effettuato su Biosfera!\n');

  final ids = [
    65140,
    65141,
    65142,
    65143,
    65144,
    65146,
    65147,
    65148,
    65149,
    65151,
    65152,
    65153,
    65154,
    65155,
  ];

  for (final id in ids) {
    try {
      final res = await dio.get(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data['data'];
      if (data != null) {
        final comp = data['visit_companies'];
        final prevNc =
            data['previous_nc_items'] ??
            data['visit_previous_nc_managements'] ??
            [];
        print('--------------------------------------------------');
        print('📌 INCARICO ID: $id');
        if (comp != null) {
          print(
            '   Azienda: ${comp['ragione_sociale']} (CUAA: ${comp['cuaa']})',
          );
          print('   Data Cert.: ${comp['prev_org_certified_date']}');
        }
        final listNc = prevNc as List;
        print('   NC Anni Precedenti count: ${listNc.length}');
        if (listNc.isNotEmpty) {
          for (var nc in listNc) {
            print('      🔥 NC: $nc');
          }
        }
      }
    } catch (e) {
      print('   Errore download ID $id: $e');
    }
  }

  print('\n=== COMPLETATO ===');
}
