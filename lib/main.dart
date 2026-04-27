import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/local_notifications_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nxbpsbemmkzdtxlchado.supabase.co',
    anonKey: 'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
  );

  try {
    // Inizializza la formattazione date per l'italiano
    await initializeDateFormatting('it_IT', null);

    // Initialize notifications
    final notificationsService = LocalNotificationsService();
    await notificationsService.init();

    runApp(
      ProviderScope(
        overrides: [
          localNotificationsProvider.overrideWithValue(notificationsService),
        ],
        child: const SqnpiAuditManagerApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('----- [MAIN ERROR] Errore critico all\'avvio: $e -----');
    debugPrint(stack.toString());
  }
}
