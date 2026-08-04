import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/utils/package_info_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';

void main() async {
  final logFile = File('STATO_AVVIO.txt');

  void log(String message) {
    try {
      logFile.writeAsStringSync('$message\n', mode: FileMode.append);
    } catch (_) {}
  }

  try {
    if (logFile.existsSync()) logFile.deleteSync();
    log('--- AVVIO APPLICAZIONE ---');

    log('1. WidgetsFlutterBinding.ensureInitialized()...');
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isMacOS) {
      log('   Bypassing macOS FilePicker entitlements checks...');
      try {
        await FilePicker.skipEntitlementsChecks();
      } catch (e) {
        log('⚠️ Errore bypass entitlements: $e');
      }
    }

    log('2. Inizializzazione Supabase...');
    await Supabase.initialize(
      url: 'https://nxbpsbemmkzdtxlchado.supabase.co',
      anonKey: 'sb_publishable_OWbb71TghUOzHKhxF_fC6Q_IZotUR7x',
    );
    log('   Supabase OK.');

    log('3. Inizializzazione date (it_IT)...');
    await initializeDateFormatting('it_IT', null);
    log('   Date OK.');

    log('4. Inizializzazione PackageInfo...');
    final packageInfo = await PackageInfo.fromPlatform();
    log('   PackageInfo OK: ${packageInfo.version}');

    log('5. Esecuzione runApp...');
    runApp(
      ProviderScope(
        overrides: [packageInfoProvider.overrideWithValue(packageInfo)],
        child: const SqnpiAuditManagerApp(),
      ),
    );
    log('6. App in esecuzione.');
  } catch (e, stack) {
    log('!!! ERRORE CRITICO: $e');
    log('STACKTRACE:\n$stack');

    try {
      final file = File('ERRORE_AVVIO.txt');
      file.writeAsStringSync('ERRORE: $e\n\nSTACKTRACE:\n$stack');
    } catch (_) {}
  }
}
