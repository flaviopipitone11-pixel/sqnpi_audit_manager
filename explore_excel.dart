// ignore_for_file: avoid_print
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  var file = 'assets/checklists/cl_sqnpi_2025.xlsx';
  var bytes = File(file).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  print('Available sheets: ${excel.sheets.keys.toList()}');

  for (var table in excel.tables.keys) {
    print('Reading Sheet: $table');
    var sheet = excel.tables[table]!;

    int count = 0;
    int skippedCount = 0;
    for (var row in sheet.rows) {
      if (count > 2) {
        final code = row[0]?.value?.toString().trim() ?? '';
        final title = row[1]?.value?.toString().trim() ?? '';
        final obbligo = row[4]?.value?.toString().trim() ?? '';

        if (code.isNotEmpty &&
            double.tryParse(code) != 0.0 &&
            obbligo.isEmpty) {
          print(
            'Row $count: Found code "$code", but empty obbligo. Title is: "$title".',
          );
          skippedCount++;
        }
      }
      count++;
    }
    print('Total skipped elements with code but no obbligo: $skippedCount');
    print('Total rows in $table: $count');
  }
}
