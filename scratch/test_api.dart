import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Configura qui il codice ispettore
  const inspectorCode = 'INSERISCI_CODICE_QUI'; 
  
  // Configura qui il token JWT (se necessario)
  const token = 'INSERISCI_TOKEN_QUI'; 
  
  final url = Uri.parse('https://biosfera2.certbios.it/api-jwt/list-audits/?cod_isp=$inspectorCode');
  
  print('Iniziando la richiesta verso: $url');
  
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token', // Decommenta se serve il token
      },
    );

    print('Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        print('Risposta JSON formattata:');
        print(const JsonEncoder.withIndent('  ').convert(decoded));
      } catch (e) {
        print('Risposta Body (non JSON):');
        print(response.body);
      }
    } else {
      print('Errore nella richiesta. Body:');
      print(response.body);
    }
  } catch (e) {
    print('Errore durante la richiesta: $e');
  }
}
