import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_painter/image_painter.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/utils/image_utils.dart';

// ---------------------------------------------------------------------------
// Helper: tipo allegato da estensione
// ---------------------------------------------------------------------------

const _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'tiff',
  'tif',
};

bool _isImage(String filePath) {
  final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
  return _imageExtensions.contains(ext);
}

IconData _fileIcon(String filePath) {
  final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    case 'txt':
      return Icons.article_outlined;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.folder_zip_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color _fileColor(String filePath) {
  final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
  switch (ext) {
    case 'pdf':
      return Colors.red.shade600;
    case 'doc':
    case 'docx':
      return const Color(0xFF1565C0);
    case 'xls':
    case 'xlsx':
      return Colors.green.shade700;
    default:
      return Colors.grey.shade600;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final attachmentsByVisitProvider =
    StreamProvider.family<List<VisitAttachment>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchAttachmentsByVisitId(visitId);
    });

final uecsForVisitProvider = StreamProvider.family<List<VisitUec>, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUecsByVisitId(visitId);
});

// Provider per i codici checklist (semplificato per il drop down)
final checklistCodesProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchFasi().asyncMap((fasi) async {
    final allItems = <String>[];
    for (final fase in fasi) {
      final items = await db.watchChecklistItemsByFase(fase).first;
      allItems.addAll(items.map((i) => i.code));
    }
    return allItems;
  });
});

enum AttachmentFilter { all, images, files }

// ---------------------------------------------------------------------------
// AttachmentsPage
// ---------------------------------------------------------------------------

class AttachmentsPage extends ConsumerStatefulWidget {
  const AttachmentsPage({
    super.key,
    required this.visitId,
    this.isReadOnly = false,
  });

  final String visitId;
  final bool isReadOnly;

  @override
  ConsumerState<AttachmentsPage> createState() => _AttachmentsPageState();
}

class _AttachmentsPageState extends ConsumerState<AttachmentsPage> {
  final _searchController = TextEditingController();
  AttachmentFilter _currentFilter = AttachmentFilter.all;
  bool _isDragging = false;
  final Set<String> _selectedIds = {}; // ID degli allegati selezionati

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---- Pick immagini (supporta multi-selezione) ----------------------------

  Future<void> _pickImages([ImageSource source = ImageSource.gallery]) async {
    List<String> paths = [];

    if (_isDesktop) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      paths = result?.files.map((f) => f.path!).toList() ?? [];
    } else {
      final picker = ImagePicker();
      if (source == ImageSource.camera) {
        final file = await picker.pickImage(source: source, imageQuality: 85);
        if (file != null) paths = [file.path];
      } else {
        final files = await picker.pickMultiImage(imageQuality: 85);
        paths = files.map((f) => f.path).toList();
      }
    }

    if (paths.isEmpty) return;
    await _handlePaths(paths);
  }

  // ---- Pick file generico (supporta multi-selezione) -----------------------

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    final files = result?.files ?? [];
    if (files.isEmpty) return;

    final paths = files.map((f) => f.path).whereType<String>().toList();
    await _handlePaths(paths);
  }

  // ---- Gestione percorsi selezionati/draggati ------------------------------

  Future<void> _handlePaths(List<String> paths) async {
    if (!mounted) return;

    final info = await _askAttachmentInfo(
      context,
      paths.length == 1
          ? p.basename(paths.first)
          : '${paths.length} allegati selezionati',
    );

    if (info == null) return;
    if (!mounted) return;

    Position? position;
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.always ||
          status == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Errore cattura GPS: $e');
    }

    int successCount = 0;
    int errorCount = 0;

    for (final path in paths) {
      try {
        final sourceFile = File(path);
        if (!await sourceFile.exists()) {
          debugPrint('Source file does not exist: $path');
          errorCount++;
          continue;
        }

        String pathToSave = path;
        if (_isImage(path)) {
          try {
            pathToSave = await ImageUtils.compressImage(path);
          } catch (e) {
            debugPrint('Compression failed, using original: $e');
          }
        }

        final destPath = await _copyToAppStorage(pathToSave);

        if (!mounted) return;

        await _saveToDb(
          context,
          ref,
          destPath,
          info.caption,
          info.uecId,
          info.checklistCode,
          lat: position?.latitude,
          lon: position?.longitude,
        );
        successCount++;
      } catch (e) {
        debugPrint('Error handling path $path: $e');
        errorCount++;
      }
    }

    if (mounted && errorCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completato: $successCount salvati, $errorCount errori.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---- Dialog info allegato ------------------------------------------------

  Future<({String caption, String? uecId, String? checklistCode})?>
  _askAttachmentInfo(BuildContext context, String title) async {
    final controller = TextEditingController();
    String? selectedUecId;
    String? selectedChecklistCode;

    final result =
        await showDialog<
          ({String caption, String? uecId, String? checklistCode})
        >(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Consumer(
                  builder: (ctx, ref, child) {
                    final uecsAsync = ref.watch(
                      uecsForVisitProvider(widget.visitId),
                    );
                    final codesAsync = ref.watch(checklistCodesProvider);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Text(
                                    'Dettagli Allegato',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Didascalia / Titolo',
                            filled: true,
                            fillColor: Colors.blueGrey.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        uecsAsync.when(
                          data: (uecs) => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'UEC Collegata',
                              filled: true,
                              fillColor: Colors.blueGrey.withValues(
                                alpha: 0.05,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            initialValue: selectedUecId,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Nessuna UEC'),
                              ),
                              ...uecs.map(
                                (u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text(
                                    u.nAggregato.isNotEmpty
                                        ? '${u.nAggregato} (${u.coltura})'
                                        : u.id,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => selectedUecId = v,
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => const Text('Errore UEC'),
                        ),
                        const SizedBox(height: 20),
                        codesAsync.when(
                          data: (codes) => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Punto Checklist',
                              filled: true,
                              fillColor: Colors.blueGrey.withValues(
                                alpha: 0.05,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            initialValue: selectedChecklistCode,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Nessun Punto'),
                              ),
                              ...codes.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => selectedChecklistCode = v,
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => const Text('Errore Checklist'),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Annulla',
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx, (
                                    caption: controller.text.trim(),
                                    uecId: selectedUecId,
                                    checklistCode: selectedChecklistCode,
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Conferma',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
    controller.dispose();
    return result;
  }

  // ---- Copia in storage locale ---------------------------------------------

  Future<String> _copyToAppStorage(String srcPath) async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(srcPath)}';
    final destPath = p.join(dir.path, filename);
    await File(srcPath).copy(destPath);
    return destPath;
  }

  // ---- Salva nel DB --------------------------------------------------------

  Future<void> _saveToDb(
    BuildContext context,
    WidgetRef ref,
    String filePath,
    String caption,
    String? uecId,
    String? checklistCode, {
    double? lat,
    double? lon,
  }) async {
    try {
      await ref
          .read(appDatabaseProvider)
          .insertAttachment(
            visitId: widget.visitId,
            filePath: filePath,
            caption: caption,
            uecId: uecId,
            checklistCode: checklistCode,
            latitude: lat,
            longitude: lon,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  // ---- Elimina -------------------------------------------------------------

  Future<void> _confirmDelete(VisitAttachment attachment) async {
    final ok = await _showPremiumConfirm(
      context,
      title: 'Elimina allegato',
      message:
          'Sei sicuro di voler eliminare questo allegato? L\'operazione non è reversibile.',
      confirmLabel: 'Elimina',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      final f = File(attachment.filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await ref.read(appDatabaseProvider).deleteAttachment(attachment.id);
  }

  // ---- Apri file con app di sistema ----------------------------------------

  Future<void> _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire il file con un\'app di sistema.'),
        ),
      );
    }
  }

  // ---- Gallery interattiva -------------------------------------------------

  void _showGallery(List<VisitAttachment> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => _GalleryView(
        images: images,
        initialIndex: initialIndex,
        onDelete: (att) async {
          Navigator.of(ctx).pop();
          await _confirmDelete(att);
        },
        onOpen: (att) => _openFile(att.filePath),
        onAnnotate: (att) {
          Navigator.of(ctx).pop();
          _openAnnotator(context, att);
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    final ok = await _showPremiumConfirm(
      context,
      title: 'Elimina $count allegati',
      message: 'Sei sicuro di voler eliminare tutti gli allegati selezionati?',
      confirmLabel: 'Elimina tutto',
      isDestructive: true,
    );

    if (ok != true) return;

    final db = ref.read(appDatabaseProvider);
    final allAttachments = await db
        .watchAttachmentsByVisitId(widget.visitId)
        .first;

    for (final id in _selectedIds) {
      final att = allAttachments.firstWhere((a) => a.id == id);
      try {
        final f = File(att.filePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      await db.deleteAttachment(id);
    }

    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkLink() async {
    final info = await _askAttachmentInfo(context, 'Collega in blocco');
    if (info == null) return;

    final db = ref.read(appDatabaseProvider);
    for (final id in _selectedIds) {
      await db.updateAttachmentLinks(
        id: id,
        uecId: info.uecId,
        checklistCode: info.checklistCode,
      );
    }

    setState(() => _selectedIds.clear());
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(
      attachmentsByVisitProvider(widget.visitId),
    );

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: widget.isReadOnly
          ? null
          : (details) async {
              setState(() => _isDragging = false);
              final paths = details.files.map((f) => f.path).toList();
              await _handlePaths(paths);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        color: _isDragging ? Colors.blue.withValues(alpha: 0.1) : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? Colors.blue : Colors.grey.shade200,
              width: _isDragging ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: attachmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (all) {
              final isMobile = MediaQuery.sizeOf(context).width < 700;
              // Filtraggio e Ricerca
              final search = _searchController.text.toLowerCase();
              final filtered = all.where((a) {
                final matchesSearch =
                    p.basename(a.filePath).toLowerCase().contains(search) ||
                    a.caption.toLowerCase().contains(search) ||
                    (a.checklistCode?.toLowerCase().contains(search) ?? false);

                if (!matchesSearch) return false;

                switch (_currentFilter) {
                  case AttachmentFilter.images:
                    return _isImage(a.filePath);
                  case AttachmentFilter.files:
                    return !_isImage(a.filePath);
                  case AttachmentFilter.all:
                    return true;
                }
              }).toList();

              final grouped = _groupAttachmentsByDate(filtered);

              return CustomScrollView(
                slivers: [
                  // ------ Header ------
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      isMobile,
                      all.length,
                      all.where((a) => _isImage(a.filePath)).length,
                      all.where((a) => !_isImage(a.filePath)).length,
                    ),
                  ),

                  // ------ Barra Selezione (Se attiva) ------
                  if (_isSelectionMode)
                    SliverToBoxAdapter(
                      child: _SelectionBar(
                        count: _selectedIds.length,
                        onClear: () => setState(() => _selectedIds.clear()),
                        onDelete: _bulkDelete,
                        onLink: _bulkLink,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(child: Divider(height: 1)),

                  // ------ Barra Ricerca & Filtri ------
                  SliverToBoxAdapter(child: _buildSearchAndFilters()),

                  SliverToBoxAdapter(
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),

                  // ------ Corpo ------
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyAttachments(
                        isDesktop: _isDesktop,
                        onPickImages: _pickImages,
                        onPickCamera: () => _pickImages(ImageSource.camera),
                        onPickGallery: () => _pickImages(ImageSource.gallery),
                        onPickFiles: _pickFiles,
                        isSearching:
                            search.isNotEmpty ||
                            _currentFilter != AttachmentFilter.all,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = grouped[index];
                          if (entry is String) {
                            return _DateHeader(label: entry);
                          }

                          final attachments = entry as List<VisitAttachment>;
                          final images = attachments
                              .where((a) => _isImage(a.filePath))
                              .toList();
                          final files = attachments
                              .where((a) => !_isImage(a.filePath))
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (images.isNotEmpty) ...[
                                _SectionHeader(
                                  icon: Icons.image_outlined,
                                  title: 'Immagini',
                                  count: images.length,
                                ),
                                const SizedBox(height: 12),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 180,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 0.85,
                                      ),
                                  itemCount: images.length,
                                  itemBuilder: (ctx, i) {
                                    final att = images[i];
                                    return _ThumbnailCard(
                                      attachment: att,
                                      isSelected: _selectedIds.contains(att.id),
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          _toggleSelection(att.id);
                                        } else {
                                          _showGallery(images, i);
                                        }
                                      },
                                      onLongPress: () =>
                                          _toggleSelection(att.id),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (files.isNotEmpty) ...[
                                _SectionHeader(
                                  icon: Icons.folder_outlined,
                                  title: 'File',
                                  count: files.length,
                                ),
                                const SizedBox(height: 12),
                                ...files.map(
                                  (att) => _FileCard(
                                    attachment: att,
                                    isSelected: _selectedIds.contains(att.id),
                                    onOpen: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(att.id);
                                      } else {
                                        _openFile(att.filePath);
                                      }
                                    },
                                    onDelete: () => _confirmDelete(att),
                                    onLongPress: () => _toggleSelection(att.id),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          );
                        }, childCount: grouped.length),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, int total, int nImages, int nFiles) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        32,
        isMobile ? 16 : 28,
        24,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestione Allegati',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$total FILE TOTALI',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$nImages immagini • $nFiles documenti',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!widget.isReadOnly) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _AddButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () => _pickImages(ImageSource.camera),
                      ),
                      const SizedBox(width: 8),
                      _AddButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galleria',
                        onTap: () => _pickImages(ImageSource.gallery),
                      ),
                      const SizedBox(width: 8),
                      _AddButton(
                        icon: Icons.upload_file_rounded,
                        label: 'File',
                        onTap: _pickFiles,
                      ),
                    ],
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestione Allegati',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$total FILE TOTALI',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.blueAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$nImages immagini • $nFiles documenti',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!widget.isReadOnly)
                  Row(
                    children: [
                      if (_isDesktop) ...[
                        _AddButton(
                          icon: Icons.add_photo_alternate_outlined,
                          label: 'Foto',
                          onTap: _pickImages,
                        ),
                      ] else ...[
                        _AddButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          onTap: () => _pickImages(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        _AddButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Galleria',
                          onTap: () => _pickImages(ImageSource.gallery),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _AddButton(
                        icon: Icons.upload_file_rounded,
                        label: 'File',
                        onTap: _pickFiles,
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cerca per nome, didascalia o requisito...',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.blueGrey,
                        size: 22,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: Colors.blueGrey.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.05),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.05),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tutti i file',
                  isSelected: _currentFilter == AttachmentFilter.all,
                  onScale: () =>
                      setState(() => _currentFilter = AttachmentFilter.all),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Solo Immagini',
                  isSelected: _currentFilter == AttachmentFilter.images,
                  onScale: () =>
                      setState(() => _currentFilter = AttachmentFilter.images),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Solo Documenti',
                  isSelected: _currentFilter == AttachmentFilter.files,
                  onScale: () =>
                      setState(() => _currentFilter = AttachmentFilter.files),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _groupAttachmentsByDate(List<VisitAttachment> list) {
    if (list.isEmpty) return [];

    // Sort by date DESC
    final sorted = List<VisitAttachment>.from(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final result = <dynamic>[];
    String? currentLabel;
    List<VisitAttachment> currentGroup = [];

    for (final item in sorted) {
      final label = _formatDateLabel(item.createdAt);
      if (currentLabel == null) {
        currentLabel = label;
        result.add(label);
      } else if (currentLabel != label) {
        result.add(currentGroup);
        currentLabel = label;
        result.add(label);
        currentGroup = [];
      }
      currentGroup.add(item);
    }

    if (currentGroup.isNotEmpty) {
      result.add(currentGroup);
    }

    return result;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Oggi';
    if (d == yesterday) return 'Ieri';

    return DateFormat('d MMMM yyyy', 'it').format(date);
  }

  void _openAnnotator(BuildContext context, VisitAttachment attachment) async {
    final editedImagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _AnnotationEditor(imagePath: attachment.filePath),
      ),
    );

    if (editedImagePath != null && editedImagePath.isNotEmpty) {
      final newFile = File(editedImagePath);
      final fileName =
          'annotated_${DateTime.now().millisecondsSinceEpoch}${p.extension(attachment.filePath)}';
      final appDir = await getApplicationSupportDirectory();
      final destination = p.join(appDir.path, 'attachments', fileName);

      await newFile.copy(destination);

      try {
        final db = ref.read(appDatabaseProvider);
        await db.insertAttachment(
          visitId: widget.visitId,
          filePath: destination,
          caption:
              'Annotazione di ${attachment.caption.isNotEmpty ? attachment.caption : p.basename(attachment.filePath)}',
          uecId: attachment.uecId,
          checklistCode: attachment.checklistCode,
        );
      } catch (e) {
        debugPrint('DB Save Error: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nuova immagine annotata salvata!')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: Barra di selezione massiva
// ---------------------------------------------------------------------------

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onClear,
    required this.onDelete,
    required this.onLink,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onClear,
          ),
          const SizedBox(width: 8),
          Text(
            '$count selezionati',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onLink,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Collega'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Elimina'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: Intestazione data
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: FilterChip personalizzato
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onScale,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onScale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onScale,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.blueGrey.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: Gallery View (Interactive PageView)
// ---------------------------------------------------------------------------

class _GalleryView extends StatefulWidget {
  const _GalleryView({
    required this.images,
    required this.initialIndex,
    required this.onDelete,
    required this.onOpen,
    required this.onAnnotate,
  });
  final List<VisitAttachment> images;
  final int initialIndex;
  final Function(VisitAttachment) onDelete;
  final Function(VisitAttachment) onOpen;
  final Function(VisitAttachment) onAnnotate;

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) {
              final att = widget.images[i];
              return Center(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.file(File(att.filePath), fit: BoxFit.contain),
                ),
              );
            },
          ),
          // Header Info
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.basename(widget.images[_currentIndex].filePath),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_currentIndex + 1} di ${widget.images.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (widget.images[_currentIndex].caption.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.images[_currentIndex].caption,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.edit,
                      label: 'Annota',
                      onPressed: () =>
                          widget.onAnnotate(widget.images[_currentIndex]),
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.open_in_new,
                      label: 'Apri',
                      onPressed: () =>
                          widget.onOpen(widget.images[_currentIndex]),
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Elimina',
                      color: Colors.red,
                      onPressed: () =>
                          widget.onDelete(widget.images[_currentIndex]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 28),
          padding: EdgeInsets.zero,
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Altri Sottowidget (modificati per mostrare i collegamenti)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });
  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B4332),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: Colors.blueGrey.withValues(alpha: 0.05),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailCard extends StatelessWidget {
  const _ThumbnailCard({
    required this.attachment,
    required this.onTap,
    this.isSelected = false,
    this.onLongPress,
  });

  final VisitAttachment attachment;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(attachment.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => Container(
                        color: Colors.blueGrey.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    if (!isSelected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if (attachment.uecId != null ||
                        attachment.checklistCode != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.link_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.caption.isNotEmpty
                        ? attachment.caption
                        : p.basename(attachment.filePath),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  if (attachment.checklistCode != null)
                    Text(
                      'PUNTO ${attachment.checklistCode}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.attachment,
    required this.onOpen,
    required this.onDelete,
    this.isSelected = false,
    this.onLongPress,
  });

  final VisitAttachment attachment;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final name = p.basename(attachment.filePath);
    final icon = _fileIcon(attachment.filePath);
    final color = _fileColor(attachment.filePath);

    return GestureDetector(
      onTap: onOpen,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.blueGrey.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (attachment.caption.isNotEmpty)
                    Text(
                      attachment.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        p
                            .extension(attachment.filePath)
                            .replaceFirst('.', '')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (attachment.checklistCode != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.link_rounded,
                          size: 12,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PUNTO ${attachment.checklistCode}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CircleIconButton(
              icon: Icons.open_in_new_rounded,
              color: Colors.blueAccent,
              onPressed: onOpen,
              tooltip: 'Apri',
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              icon: Icons.delete_outline_rounded,
              color: Colors.redAccent,
              onPressed: onDelete,
              tooltip: 'Elimina',
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style:
          ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4332),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1)),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              Colors.blue.withValues(alpha: 0.05),
            ),
          ),
    );
  }
}

class _EmptyAttachments extends StatelessWidget {
  const _EmptyAttachments({
    required this.isDesktop,
    required this.onPickImages,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onPickFiles,
    required this.isSearching,
  });
  final bool isDesktop;
  final VoidCallback onPickImages;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onPickFiles;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.attach_file,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Nessun risultato trovato.'
                : 'Nessun allegato presente.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (!isSearching) ...[
            Text(
              isDesktop
                  ? 'Trascina i file qui oppure aggiungili usando i pulsanti in alto.'
                  : 'Usa i pulsanti in alto per aggiungere foto o file.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: Editor per annotazioni
// ---------------------------------------------------------------------------

class _AnnotationEditor extends StatefulWidget {
  const _AnnotationEditor({required this.imagePath});
  final String imagePath;

  @override
  State<_AnnotationEditor> createState() => _AnnotationEditorState();
}

class _AnnotationEditorState extends State<_AnnotationEditor> {
  late ImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annota Immagine'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _save,
            tooltip: 'Salva e chiudi',
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ImagePainter.file(
          File(widget.imagePath),
          controller: _controller,
          scalable: true,
        ),
      ),
    );
  }

  Future<void> _save() async {
    try {
      final imageBytes = await _controller.exportImage();
      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final path = p.join(
          tempDir.path,
          'tmp_annotated_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        final file = File(path);
        await file.writeAsBytes(imageBytes);
        if (mounted) Navigator.of(context).pop(path);
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Annotator Save Error: $e');
      if (mounted) Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Sottowidget: Sezione Documentazione Speciale (M904 Rev 08)
// ---------------------------------------------------------------------------

class _SpecialDocumentationSection extends ConsumerStatefulWidget {
  const _SpecialDocumentationSection({
    required this.visitId,
    required this.isReadOnly,
    required this.attachments,
  });

  final String visitId;
  final bool isReadOnly;
  final List<VisitAttachment> attachments;

  @override
  ConsumerState<_SpecialDocumentationSection> createState() =>
      _SpecialDocumentationSectionState();
}

class _SpecialDocumentationSectionState
    extends ConsumerState<_SpecialDocumentationSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.05),
                  Colors.blue.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentazione Ufficiale',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Text(
                        'Standard SQNPI • M904 Rev. 08',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCategoryGroup(
                  title: 'DOCUMENTI DI RIFERIMENTO UTILIZZATI',
                  category: 'reference',
                  items: [
                    (
                      type: 'DISCIPLINARE',
                      label: 'Disciplinare/i Regionale di Difesa Integrata',
                    ),
                    (
                      type: 'LINEE_GUIDA',
                      label: 'Linee Guida Nazionali di Difesa Integrata',
                    ),
                    (
                      type: 'CHECKLIST_CONTROL_REV',
                      label: 'Checklist di Controllo (Allegato interno Bios)',
                    ),
                    (
                      type: 'RIFERIMENTO_ALTRO',
                      label: 'Altro documento di riferimento',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildCategoryGroup(
                  title: 'DOCUMENTI VISIONATI',
                  category: 'viewed',
                  items: [
                    (
                      type: 'REGISTRO_SQNPI',
                      label:
                          'REGISTRO AZIENDALE SQNPI (Campagna, Operazioni, Magazzino)',
                    ),
                    (
                      type: 'AUTOCONTROLLO',
                      label: 'Evidenza autocontrollo interno',
                    ),
                    (
                      type: 'AUDIT_BIOS_PREC',
                      label: 'Rapporto dell\'audit Bios precedente',
                    ),
                    (
                      type: 'ESITO_CERT_ALTRO_ODC',
                      label: 'Esito certificazione / NC altro OdC',
                    ),
                    (
                      type: 'VISIONATI_ALTRO',
                      label: 'Altro documento visionato',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup({
    required String title,
    required String category,
    required List<({String type, String label})> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.blueGrey.shade400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => _buildSpecialItem(category, item.type, item.label),
        ),
      ],
    );
  }

  Widget _buildSpecialItem(String category, String type, String label) {
    final isDigitalChecklist = type == 'CHECKLIST_CONTROL_REV';
    final isSelected =
        isDigitalChecklist ||
        widget.attachments.any(
          (a) => a.category == category && a.attachmentType == type,
        );
    final att = !isDigitalChecklist && isSelected
        ? widget.attachments.firstWhere(
            (a) => a.category == category && a.attachmentType == type,
          )
        : null;
    final hasFile = att != null && att.filePath.isNotEmpty;

    final actualLabel = isDigitalChecklist ? '$label (Digitale in-App)' : label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.blueGrey.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: (widget.isReadOnly || isDigitalChecklist)
              ? null
              : () async {
                  if (hasFile) {
                    _openFile(att.filePath);
                  } else if (isSelected) {
                    await _handleAddSpecial(category, type, label, att!);
                  } else {
                    await _handleAddSpecial(category, type, label);
                  }
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: (widget.isReadOnly || isDigitalChecklist)
                      ? null
                      : () async {
                          if (isSelected) {
                            await _handleDeleteSpecial(att!);
                          } else {
                            await _handleToggleSelection(category, type, label);
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDigitalChecklist ? Colors.green : Colors.blue)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isSelected
                            ? (isDigitalChecklist ? Colors.green : Colors.blue)
                            : Colors.blueGrey.shade200,
                        width: isSelected ? 0 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    (isDigitalChecklist
                                            ? Colors.green
                                            : Colors.blue)
                                        .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actualLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDigitalChecklist
                              ? Colors.green.shade800
                              : (isSelected
                                    ? Colors.blue.shade900
                                    : Colors.blueGrey.shade800),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (isDigitalChecklist)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AUTOMATICO',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected && !isDigitalChecklist) ...[
                        if (type == 'DISCIPLINARE')
                          _buildExtraField(att!, 'Dettagli Regione/Anno'),
                        if (type.contains('ALTRO'))
                          _buildExtraField(att!, 'Specifiche Documento'),
                      ],
                    ],
                  ),
                ),
                if (isSelected && !isDigitalChecklist)
                  Row(
                    children: [
                      if (hasFile)
                        _CircleIconButton(
                          icon: _isImage(att.filePath)
                              ? Icons.visibility_rounded
                              : Icons.file_present_rounded,
                          color: Colors.blueAccent,
                          onPressed: () => _openFile(att.filePath),
                          tooltip: 'Visualizza',
                        )
                      else
                        _CircleIconButton(
                          icon: Icons.add_a_photo_rounded,
                          color: Colors.blueGrey.shade400,
                          onPressed: () =>
                              _handleAddSpecial(category, type, label, att!),
                          tooltip: 'Allega file',
                        ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        onPressed: () => _handleDeleteSpecial(att!),
                        tooltip: 'Rimuovi',
                      ),
                    ],
                  ),
                if (isDigitalChecklist)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraField(VisitAttachment att, String label) {
    final isMandatory = att.attachmentType.contains('ALTRO');
    final isEmpty = att.extraValue.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 10,
                color: (isMandatory && isEmpty)
                    ? Colors.red
                    : Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: (isMandatory && isEmpty)
                      ? Colors.red
                      : Colors.blueGrey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: att.extraValue,
            readOnly: widget.isReadOnly,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: (isMandatory && isEmpty)
                  ? Colors.red.shade900
                  : Colors.black87,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: (isMandatory && isEmpty)
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.blueGrey.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: isMandatory
                  ? 'SPECIFICA QUI...'
                  : 'Aggiungi dettagli...',
              hintStyle: TextStyle(
                color: (isMandatory && isEmpty)
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.blueGrey.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            onChanged: (val) {
              ref
                  .read(appDatabaseProvider)
                  .updateAttachmentExtra(id: att.id, extraValue: val);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSpecial(VisitAttachment att) async {
    final ok = await _showPremiumConfirm(
      context,
      title: 'Rimuovi Selezione',
      message:
          'Vuoi rimuovere la selezione per questo punto? Verrà rimosso anche l\'eventuale allegato associato.',
      confirmLabel: 'Rimuovi',
      isDestructive: true,
    );
    if (ok != true) return;

    try {
      if (att.filePath.isNotEmpty) {
        final f = File(att.filePath);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    await ref.read(appDatabaseProvider).deleteAttachment(att.id);
  }

  Future<void> _handleToggleSelection(
    String category,
    String type,
    String label,
  ) async {
    String extraValue = '';

    if (type.contains('ALTRO')) {
      final name = await _showNameDialog();
      if (!mounted) return;
      if (name == null || name.trim().isEmpty) return;
      extraValue = name.trim();
    }

    await ref
        .read(appDatabaseProvider)
        .insertAttachment(
          visitId: widget.visitId,
          filePath: '', // Percorso vuoto = solo selezionato
          caption: label,
          category: category,
          attachmentType: type,
          extraValue: extraValue,
        );
  }

  Future<void> _handleAddSpecial(
    String category,
    String type,
    String label, [
    VisitAttachment? existing,
  ]) async {
    String extraValue = existing?.extraValue ?? '';

    if (existing == null && type.contains('ALTRO')) {
      final name = await _showNameDialog();
      if (!mounted) return;
      if (name == null || name.trim().isEmpty) return;
      extraValue = name.trim();
    }

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotocamera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Seleziona File / Galleria'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    List<String> paths = [];
    if (source == 'camera') {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null) paths = [file.path];
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null) paths = result.paths.whereType<String>().toList();
    }

    if (paths.isEmpty) return;

    // Gestione salvataggio speciale
    final path = paths.first;
    String pathToSave = path;
    if (_isImage(path)) {
      pathToSave = await ImageUtils.compressImage(path);
    }

    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'attachments'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final filename =
        'SPEC_${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
    final destPath = p.join(dir.path, filename);
    await File(pathToSave).copy(destPath);

    if (existing != null) {
      // Aggiorniamo l'allegato esistente aggiungendo il file
      await ref
          .read(appDatabaseProvider)
          .updateAttachmentFile(id: existing.id, filePath: destPath);
    } else {
      await ref
          .read(appDatabaseProvider)
          .insertAttachment(
            visitId: widget.visitId,
            filePath: destPath,
            caption: label,
            category: category,
            attachmentType: type,
            extraValue: extraValue,
          );
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Specifica Documento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Campo obbligatorio',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Inserisci una descrizione o il nome del documento per poter procedere con il caricamento.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome documento',
                    hintText: 'es. Certificato X, Disciplinare Y...',
                    filled: true,
                    fillColor: Colors.blueGrey.shade50.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Annulla',
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            Navigator.pop(ctx, controller.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Conferma',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

Future<bool?> _showPremiumConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Conferma',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : Colors.blue).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructive
                      ? Icons.delete_outline_rounded
                      : Icons.info_outline_rounded,
                  color: isDestructive ? Colors.red : Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Annulla',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? Colors.red
                            : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
