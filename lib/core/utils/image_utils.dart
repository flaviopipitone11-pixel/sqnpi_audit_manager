import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  /// Comprime un'immagine salvandola in una cartella temporanea ottimizzata.
  /// Ritorna il percorso del file compresso.
  static Future<String> compressImage(String path) async {
    final file = File(path);
    final sizeInMb = file.lengthSync() / (1024 * 1024);

    // Se l'immagine è già piccola (< 0.5 MB), non comprimiamo ulteriormente
    if (sizeInMb < 0.5) return path;

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}',
    );

    try {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        quality: 80,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result != null) {
        final compressedFile = File(targetPath);
        await compressedFile.writeAsBytes(result);
        return targetPath;
      }
    } catch (e) {
      debugPrint('Compression Error: $e');
    }

    return path;
  }
}
