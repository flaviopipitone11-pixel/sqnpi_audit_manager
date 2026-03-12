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

    final uecsAsync = ref.read(uecsForVisitProvider(widget.visitId));
    final codesAsync = ref.read(checklistCodesProvider);

    final result =
        await showDialog<
          ({String caption, String? uecId, String? checklistCode})
        >(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(title, style: const TextStyle(fontSize: 18)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 120,
                        decoration: InputDecoration(
                          labelText: 'Didascalia (opzionale)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Collega a (opzionale):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dropdown UEC
                      uecsAsync.when(
                        data: (uecs) => DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'UEC',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue: selectedUecId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Nessuna UEC'),
                            ),
                            ...uecs.map(
                              (u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  u.descrizione.isNotEmpty
                                      ? u.descrizione
                                      : u.id,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedUecId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Errore caricamento UEC'),
                      ),
                      const SizedBox(height: 12),
                      // Dropdown Checklist
                      codesAsync.when(
                        data: (codes) => DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Requisito Checklist',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue: selectedChecklistCode,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Nessun Requisito'),
                            ),
                            ...codes.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedChecklistCode = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stack) => const Text('Errore checklist'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop((
                        caption: controller.text.trim(),
                        uecId: selectedUecId,
                        checklistCode: selectedChecklistCode,
                      ));
                    },
                    child: const Text('Salva'),
                  ),
                ],
              );
            },
          ),
        );
    controller.dispose();
    return result;
  }

  // ---- Copia in storage locale ---------------------------------------------

  Future<String> _copyToAppStorage(String srcPath) async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(
      p.join(appDir.path, 'attachments'),
    );
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina allegato'),
        content: const Text(
          'Sei sicuro di voler eliminare questo allegato? L\'operazione non è reversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina $count allegati'),
        content: const Text(
          'Sei sicuro di voler eliminare tutti gli allegati selezionati?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Elimina tutto'),
          ),
        ],
      ),
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
      onDragDone: widget.isReadOnly ? null : (details) async {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        await _handlePaths(paths);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        color: _isDragging ? Colors.blue.withOpacity(0.1) : null,
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
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: attachmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (all) {
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------ Header ------
                  _buildHeader(
                    all.length,
                    all.where((a) => _isImage(a.filePath)).length,
                    all.where((a) => !_isImage(a.filePath)).length,
                  ),

                  // ------ Barra Selezione (Se attiva) ------
                  if (_isSelectionMode)
                    _SelectionBar(
                      count: _selectedIds.length,
                      onClear: () => setState(() => _selectedIds.clear()),
                      onDelete: _bulkDelete,
                      onLink: _bulkLink,
                    ),

                  // ------ Barra Ricerca & Filtri ------
                  _buildSearchAndFilters(),

                  Divider(height: 1, color: Colors.grey.shade100),

                  // ------ Corpo ------
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyAttachments(
                            isDesktop: _isDesktop,
                            onPickImages: _pickImages,
                            onPickCamera: () => _pickImages(ImageSource.camera),
                            onPickGallery: () =>
                                _pickImages(ImageSource.gallery),
                            onPickFiles: _pickFiles,
                            isSearching:
                                search.isNotEmpty ||
                                _currentFilter != AttachmentFilter.all,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              final entry = grouped[index];
                              if (entry is String) {
                                return _DateHeader(label: entry);
                              }

                              final attachments =
                                  entry as List<VisitAttachment>;
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                          isSelected: _selectedIds.contains(
                                            att.id,
                                          ),
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
                                        isSelected: _selectedIds.contains(
                                          att.id,
                                        ),
                                        onOpen: () {
                                          if (_isSelectionMode) {
                                            _toggleSelection(att.id);
                                          } else {
                                            _openFile(att.filePath);
                                          }
                                        },
                                        onDelete: () => _confirmDelete(att),
                                        onLongPress: () =>
                                            _toggleSelection(att.id),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ],
                              );
                            },
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

  Widget _buildHeader(int total, int nImages, int nFiles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allegati',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total totali ($nImages immagini, $nFiles file)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              if (!widget.isReadOnly) ...[
                if (_isDesktop) ...[
                  _AddButton(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Immagini',
                    onTap: _pickImages,
                  ),
                ] else ...[
                  _AddButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => _pickImages(ImageSource.camera),
                  ),
                  _AddButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galleria',
                    onTap: () => _pickImages(ImageSource.gallery),
                  ),
                ],
                _AddButton(
                  icon: Icons.attach_file,
                  label: 'File',
                  onTap: _pickFiles,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cerca per nome, didascalia o requisito...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _FilterChip(
            label: 'Tutti',
            isSelected: _currentFilter == AttachmentFilter.all,
            onScale: () =>
                setState(() => _currentFilter = AttachmentFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Immagini',
            isSelected: _currentFilter == AttachmentFilter.images,
            onScale: () =>
                setState(() => _currentFilter = AttachmentFilter.images),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Documenti',
            isSelected: _currentFilter == AttachmentFilter.files,
            onScale: () =>
                setState(() => _currentFilter = AttachmentFilter.files),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClear,
          ),
          const SizedBox(width: 8),
          Text(
            '$count selezionati',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onLink,
            icon: const Icon(Icons.link, color: Colors.white, size: 20),
            label: const Text('Collega', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            label: const Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onScale(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1B4332) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
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
      backgroundColor: Colors.black.withOpacity(0.9),
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
                            color: Colors.white.withOpacity(0.7),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(attachment.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, st) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      color: Colors.blue.withOpacity(0.3),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  // Iconcina zoom (se non selezionato)
                  if (!isSelected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    ),
                  // Se collegato a qualcosa
                  if (attachment.uecId != null ||
                      attachment.checklistCode != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.link,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            attachment.caption.isNotEmpty
                ? attachment.caption
                : p.basename(attachment.filePath),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (attachment.checklistCode != null)
            Text(
              'Requisito ${attachment.checklistCode}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onOpen,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue, size: 32)
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachment.caption.isNotEmpty)
              Text(
                attachment.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            Row(
              children: [
                Text(
                  p
                      .extension(attachment.filePath)
                      .replaceFirst('.', '')
                      .toUpperCase(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (attachment.checklistCode != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.link, size: 10, color: Colors.blue),
                  const SizedBox(width: 2),
                  Text(
                    'Cod: ${attachment.checklistCode}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.open_in_new,
                color: Theme.of(context).primaryColor,
              ),
              tooltip: 'Apri',
              onPressed: onOpen,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Elimina',
              onPressed: onDelete,
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
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        foregroundColor: const Color(0xFF1B4332),
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
