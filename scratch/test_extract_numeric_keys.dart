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
      final rawPrevNc =
          data?['previous_nc_items'] ??
          data?['visit_previous_nc_managements'] ??
          data?['visit_previous_ncs'];

      List<dynamic> items = [];
      if (rawPrevNc != null) {
        if (rawPrevNc is List) {
          items = rawPrevNc;
        } else if (rawPrevNc is Map) {
          final mapData = rawPrevNc;
          mapData.forEach((key, value) {
            final keyStr = key.toString();
            if (RegExp(r'^\d+$').hasMatch(keyStr) && value is Map) {
              items.add(value);
            }
          });
          if (items.isEmpty) {
            items.add(mapData);
          }
        }
      }

      if (items.isNotEmpty) {
        // ignore: avoid_print
        print('==================================================');
        // ignore: avoid_print
        print('📌 AUDIT ID: $id | Azienda: ${data['company_name']}');
        // ignore: avoid_print
        print('   Estratte ${items.length} NC!');
        for (int i = 0; i < items.length; i++) {
          final nc = items[i];
          // ignore: avoid_print
          print(
            '   [$i] Data: ${nc['data'] ?? nc['data_protocollo_NOCONFU']} | Protocollo: ${nc['protocollo_conferma_nc'] ?? nc['data_protocollo_NOCONFU']} | Argomento: ${nc['argomento']?.toString().substring(0, nc['argomento'].toString().length > 60 ? 60 : nc['argomento'].toString().length)}...',
          );
        }
      }
    } catch (_) {}
  }
}
