import 'dart:convert';
import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  final ids = [65141, 65142, 65143, 65148];

  for (final id in ids) {
    final res = await dio.get(
      'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = res.data['data'];
    final rawPrevNc =
        data['previous_nc_items'] ??
        data['visit_previous_nc_managements'] ??
        data['visit_previous_ncs'];

    List<dynamic>? prevNcItems;
    if (rawPrevNc != null) {
      if (rawPrevNc is List) {
        prevNcItems = rawPrevNc;
      } else if (rawPrevNc is Map) {
        final items = <dynamic>[];
        final mapData = rawPrevNc as Map<String, dynamic>;
        mapData.forEach((key, value) {
          if (RegExp(r'^\d+$').hasMatch(key) && value is Map) {
            items.add(value);
          }
        });
        if (items.isNotEmpty) {
          prevNcItems = items;
        } else {
          prevNcItems = [mapData];
        }
      }
    }

    print('==================================================');
    print('📌 AUDIT ID: $id | Azienda: ${data['company_name']}');
    print('   NC Estratte (Count: ${prevNcItems?.length ?? 0}):');
    print(const JsonEncoder.withIndent('  ').convert(prevNcItems));
  }
}
