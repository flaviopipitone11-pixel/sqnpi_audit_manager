import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://nxbpsbemmkzdtxlchado.supabase.co',
    'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );
  
  try {
     final response = await supabase.from('inspectors').select();
     print('Total inspectors: ${response.length}');
     for (final i in response) {
         if (i.toString().toLowerCase().contains('nicolosi')) {
             print('Match found: $i');
         }
         if (i.toString().toLowerCase().contains('b520')) {
             print('Match for B520 found: $i');
         }
     }
  } catch (e) {
     print('Error: $e');
  }
}
