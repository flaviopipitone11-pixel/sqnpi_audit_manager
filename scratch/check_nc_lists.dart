import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  for (int id = 65140; id <= 65160; id++) {
    try {
      final res = await dio.get(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data['data'];
      if (data != null && data['previous_nc_items'] != null) {
        final nc = data['previous_nc_items'];
        // ignore: avoid_print
        print('📌 ID $id (${data['company_name']}): ${nc.runtimeType} -> $nc');
      }
    } catch (_) {}
  }
}
