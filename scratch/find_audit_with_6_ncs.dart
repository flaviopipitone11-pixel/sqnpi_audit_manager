import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  for (int id = 65130; id <= 65160; id++) {
    try {
      final res = await dio.get(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data['data'];
      if (data != null) {
        final rawNc =
            data['previous_nc_items'] ??
            data['visit_previous_nc_managements'] ??
            data['visit_previous_ncs'];
        if (rawNc != null) {
          if (rawNc is Map) {
            final mapData = rawNc;
            final numericKeys = mapData.keys
                .where((k) => RegExp(r'^\d+$').hasMatch(k.toString()))
                .toList();
            // ignore: avoid_print
            print(
              '📌 ID $id (${data['company_name']}): Map with keys = ${mapData.keys.toList()} | numericKeys = $numericKeys (count = ${numericKeys.length})',
            );
          } else if (rawNc is List) {
            // ignore: avoid_print
            print(
              '📌 ID $id (${data['company_name']}): List with count = ${rawNc.length}',
            );
          }
        }
      }
    } catch (_) {}
  }
}
