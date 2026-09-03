import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://nxbpsbemmkzdtxlchado.supabase.co',
    'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x', // using whatever is in main.dart
  );
  
  try {
     final response = await supabase.from('inspectors').select().eq('email', 'm.nicolosi@certbios.it');
     print('Inspector match:');
     print(response);
     
     final response2 = await supabase.from('inspectors').select().ilike('inspector_name', '%Nicolosi%');
     print('Inspector name match:');
     print(response2);
     
  } catch (e) {
     print('Error: $e');
  }
}
