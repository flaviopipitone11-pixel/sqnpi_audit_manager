import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/local_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
