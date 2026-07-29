import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  for (int id = 65140; id <= 65170; id++) {
    try {
      final res = await dio.get(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data['data'];
      final rawPrevNc =
          data?['previous_nc_items'] ??
          data?['visit_previous_nc_managements'] ??
          data?['visit_previous_ncs'];

      if (rawPrevNc != null && rawPrevNc is Map) {
        final mapData = rawPrevNc;
        final numKeys = mapData.keys
            .where((k) => RegExp(r'^\d+$').hasMatch(k.toString()))
            .toList();
        // ignore: avoid_print
        print(
          'ID $id | Company: ${data['company_name']} | rawKeysCount: ${mapData.keys.length} | numKeysCount: ${numKeys.length}',
        );
        if (numKeys.length > 1) {
          // ignore: avoid_print
          print('   🔥 FOUND MULTIPLE NCs FOR ID $id: ${numKeys.length} NCs!');
        }
      }
    } catch (_) {}
  }
}
