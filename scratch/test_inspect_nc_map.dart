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
    print('==================================================');
    print('📌 AUDIT ID: $id');
    print('Azienda: ${data['company_name']}');
    print(
      'Raw previous_nc_items type: ${data['previous_nc_items'].runtimeType}',
    );
    print('Raw previous_nc_items content:');
    print(
      const JsonEncoder.withIndent('  ').convert(data['previous_nc_items']),
    );
  }
}
