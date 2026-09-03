import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();

  // 1. Biosfera Login
  final loginReq = await client.postUrl(
    Uri.parse('https://biosfera2.certbios.it/api-jwt/auth/login'),
  );
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'ced@certbios.it', 'password': 'test'}));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  final loginJson = jsonDecode(loginBody);
  final token = loginJson['access_token'];

  print('=== 1. SEARCHING ON BIOSFERA API ===');
  // Probe list-audits with different query filters
  final filters = [
    'cod_isp=B520',
    'cod_isp=b520',
    'cod_azienda=19AI01872',
    'cuaa=BNGSVR55H18A176U',
    'ragione_sociale=Bongiovanni',
    'search=Bongiovanni',
    'search=19AI01872',
    'q=Bongiovanni',
  ];

  for (final f in filters) {
    final req = await client.getUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits?$f'),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    try {
      final json = jsonDecode(body);
      final count = (json['data'] as List?)?.length ?? 0;
      print('GET /list-audits?$f -> total: ${json['total']}, count: $count');
      if (count > 0) {
        for (var v in json['data']) {
          print('   Found visit: $v');
        }
      }
    } catch (e) {
      print('Error parsing $f: $e');
    }
  }

  // Probe searching across known codes or checking if there is a company search endpoint
  for (final ep in [
    'companies?search=BNGSVR55H18A176U',
    'companies?search=Bongiovanni',
    'azienda?cod=19AI01872',
    'azienda?cuaa=BNGSVR55H18A176U',
    'audit?cod_azienda=19AI01872',
    'audit?cuaa=BNGSVR55H18A176U',
    'audits?cod_azienda=19AI01872',
    'audits?cuaa=BNGSVR55H18A176U',
  ]) {
    final req = await client.getUrl(
      Uri.parse('https://biosfera2.certbios.it/api-jwt/$ep'),
    );
    req.headers.add('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print(
      'GET /$ep -> status: ${res.statusCode}, body: ${body.substring(0, body.length > 200 ? 200 : body.length)}',
    );
  }

  // 2. Check Supabase
  print('\n=== 2. SEARCHING ON SUPABASE ===');
  final supaReq = await client.getUrl(
    Uri.parse(
      'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1/visits?or=(company_name.ilike.*Bongiovanni*,id.ilike.*19AI01872*)&select=*,visit_companies(*)',
    ),
  );
  supaReq.headers.add(
    'apikey',
    'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );
  supaReq.headers.add(
    'Authorization',
    'Bearer sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );
  final supaRes = await supaReq.close();
  final supaBody = await supaRes.transform(utf8.decoder).join();
  final supaJson = jsonDecode(supaBody);
  print('Supabase visits found: ${(supaJson as List).length}');
  for (var v in supaJson) {
    print(
      'Supabase visit: ID ${v['id']}, Company: ${v['company_name']}, Inspector: ${v['inspector_name']} (${v['inspector_email']})',
    );
    print('Associated company: ${v['visit_companies']}');
  }

  final supaCompReq = await client.getUrl(
    Uri.parse(
      'https://nxbpsbemmkzdtxlchado.supabase.co/rest/v1/visit_companies?or=(ragione_sociale.ilike.*Bongiovanni*,cuaa.ilike.*BNGSVR55H18A176U*,cod.ilike.*19AI01872*)&select=*',
    ),
  );
  supaCompReq.headers.add(
    'apikey',
    'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );
  supaCompReq.headers.add(
    'Authorization',
    'Bearer sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );
  final supaCompRes = await supaCompReq.close();
  final supaCompBody = await supaCompRes.transform(utf8.decoder).join();
  final supaCompJson = jsonDecode(supaCompBody);
  print('Supabase visit_companies found: ${(supaCompJson as List).length}');
  for (var c in supaCompJson) {
    print('visit_company record: $c');
  }

  client.close();
}
