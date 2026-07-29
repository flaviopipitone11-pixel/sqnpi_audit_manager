import 'dart:convert';
import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  for (final id in [65147, 65141]) {
    final res = await dio.get(
      'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    print('==================================================');
    print('📌 RAW JSON FOR ID $id:');
    print(const JsonEncoder.withIndent('  ').convert(res.data));
  }
}
