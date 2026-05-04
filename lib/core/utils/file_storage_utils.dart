import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileStorageUtils {
  /// Prende un percorso memorizzato nel DB e lo rende valido per l'esecuzione corrente.
  /// Su iOS/Android, i percorsi assoluti cambiano ad ogni installazione/aggiornamento (il prefisso UUID della sandbox).
  /// Questa funzione tenta di ricostruire il percorso corretto se il file non esiste.
  static Future<String> getNormalizedPath(String storedPath) async {
    if (storedPath.isEmpty) return storedPath;

    // Se il percorso non è assoluto (non inizia con / su Unix o non ha : su Windows), 
    // lo consideriamo relativo a Documents
    if (!p.isAbsolute(storedPath)) {
      final appDir = await getApplicationDocumentsDirectory();
      return p.join(appDir.path, storedPath);
    }

    final file = File(storedPath);
    if (await file.exists()) {
      return storedPath;
    }

    // Se il file non esiste, potrebbe essere a causa del cambio di UUID della sandbox (iOS/Android)
    // Troviamo il segmento 'Documents' o 'Library/Application Support'
    final segments = p.split(storedPath);
    
    // Tenta con Documents
    final docIndex = segments.lastIndexOf('Documents');
    if (docIndex != -1) {
      final appDir = await getApplicationDocumentsDirectory();
      final relativePath = p.joinAll(segments.sublist(docIndex + 1));
      final newPath = p.join(appDir.path, relativePath);
      if (await File(newPath).exists()) {
        return newPath;
      }
    }

    // Tenta con Application Support (spesso usato per gli allegati)
    final supportIndex = segments.lastIndexOf('Application Support');
    if (supportIndex != -1) {
      final supportDir = await getApplicationSupportDirectory();
      final relativePath = p.joinAll(segments.sublist(supportIndex + 1));
      final newPath = p.join(supportDir.path, relativePath);
      if (await File(newPath).exists()) {
        return newPath;
      }
    }

    // Se non troviamo nulla, restituiamo il percorso originale e lasceremo che l'UI gestisca l'errore
    return storedPath;
  }
}
