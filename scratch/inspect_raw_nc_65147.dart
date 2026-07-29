import 'dart:convert';
import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio();

  final loginRes = await dio.post(
    'https://biosfera2.certbios.it/api-jwt/auth/login',
    data: {'email': 'ced@certbios.it', 'password': 'test'},
  );

  final token = loginRes.data['access_token'];

  final res = await dio.get(
    'https://biosfera2.certbios.it/api-jwt/download-assignment?id=65147',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  print('=== RAW JSON RETURNED BY BIOSFERA FOR ID 65147 ===\n');
  print(const JsonEncoder.withIndent('  ').convert(res.data));
}
