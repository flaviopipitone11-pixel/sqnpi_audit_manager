import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/local_notifications_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}
