// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  // Find the database file
  // Usually in Application Support on macOS
  final home = Platform.environment['HOME'];
  final dbPath = p.join(
    home!,
    'Library',
    'Application Support',
    'com.flavio.sqnpiAuditManager',
    'sqnpi_audit_manager',
    'app.sqlite',
  );

  print('Checking DB at: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('DB file not found!');
    return;
  }

  final db = await databaseFactory.openDatabase(dbPath);

  print('\n--- VISITS ---');
  final visits = await db.query('visits');
  for (final v in visits) {
    print(
      'ID: ${v['id']} | Email: ${v['inspector_email']} | Company: ${v['company_name']} | Date: ${v['scheduled_at']}',
    );
  }

  print('\n--- VISIT COMPANIES ---');
  final companies = await db.query('visit_companies');
  for (final c in companies) {
    print('VisitID: ${c['visit_id']} | CUAA: ${c['cuaa']}');
  }

  await db.close();
}
