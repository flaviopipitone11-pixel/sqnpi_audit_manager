import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;
import '../application/activity_logger.dart';
import '../../../core/services/geocoding_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../data/admin_repository.dart';

final companyVisitsProvider = StreamProvider.family<List<Visit>, String>((
  ref,
  cuaa,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisitsByCuaa(cuaa);
});

class AdminCompaniesPage extends ConsumerStatefulWidget {
  const AdminCompaniesPage({super.key});

  @override
  ConsumerState<AdminCompaniesPage> createState() => _AdminCompaniesPageState();
}

class _AdminCompaniesPageState extends ConsumerState<AdminCompaniesPage> {
  final _searchController = TextEditingController();
  final _cuaaController = TextEditingController();
  final _ragioneSocialeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provController = TextEditingController();
  final _capController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isGeocoding = false;
  bool _isImportingExcel = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSync();
    });
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    await ref.read(adminRepositoryProvider).syncCompaniesWithCloud();
    if (mounted) setState(() => _isSyncing = false);
  }

  void _showAddCompanyDialog({MasterCompany? company}) {
    if (company != null) {
      _cuaaController.text = company.cuaa;
      _ragioneSocialeController.text = company.ragioneSociale;
      _emailController.text = company.email;
      _phoneController.text = company.telefono;
      _addressController.text = company.indirizzo;
      _cityController.text = company.comune;
      _provController.text = company.provincia;
      _capController.text = company.cap;
      _latController.text = company.latitude?.toString() ?? '';
      _lngController.text = company.longitude?.toString() ?? '';
    } else {
      _cuaaController.clear();
      _ragioneSocialeController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _cityController.clear();
      _provController.clear();
      _capController.clear();
      _latController.clear();
      _lngController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Text(
          company == null ? 'Nuova Azienda' : 'Modifica Azienda',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A237E),
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModernTextField(
                  controller: _cuaaController,
                  label: 'CUAA / Codice Fiscale',
                  icon: Icons.badge_outlined,
                  enabled: company == null,
                ),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: _ragioneSocialeController,
                  label: 'Ragione Sociale',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _phoneController,
                        label: 'Telefono',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: _addressController,
                  label: 'Indirizzo',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildModernTextField(
                        controller: _cityController,
                        label: 'Comune',
                        icon: Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _provController,
                        label: 'Prov',
                        icon: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _capController,
                        label: 'CAP',
                        icon: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _latController,
                        label: 'Latitudine',
                        icon: Icons.explore_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _lngController,
                        label: 'Longitudine',
                        icon: Icons.explore_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGeocoding
                          ? null
                          : () async {
                              final address = _addressController.text.trim();
                              final city = _cityController.text.trim();
                              final province = _provController.text.trim();

                              if (address.isEmpty || city.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Inserisci Indirizzo e Comune per localizzare.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setStateDialog(() => _isGeocoding = true);
                              try {
                                final geocodingService = ref.read(
                                  geocodingServiceProvider,
                                );
                                final coords = await geocodingService
                                    .getCoordinates(
                                      address: address,
                                      city: city,
                                      province: province,
                                    );

                                if (coords != null) {
                                  _latController.text = coords.lat
                                      .toStringAsFixed(6);
                                  _lngController.text = coords.lon
                                      .toStringAsFixed(6);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Posizione individuata!'),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Indirizzo non trovato.'),
                                      ),
                                    );
                                  }
                                }
                              } finally {
                                setStateDialog(() => _isGeocoding = false);
                              }
                            },
                      icon: _isGeocoding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_on_rounded, size: 18),
                      label: Text(
                        _isGeocoding ? 'RICERCA...' : 'LOCALIZZA INDIRIZZO',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_cuaaController.text.isEmpty ||
                  _ragioneSocialeController.text.isEmpty) {
                return;
              }
              final db = ref.read(appDatabaseProvider);
              final lat = double.tryParse(
                _latController.text.replaceAll(',', '.'),
              );
              final lng = double.tryParse(
                _lngController.text.replaceAll(',', '.'),
              );

              await db
                  .into(db.masterCompanies)
                  .insertOnConflictUpdate(
                    MasterCompaniesCompanion.insert(
                      cuaa: _cuaaController.text,
                      ragioneSociale: Value(_ragioneSocialeController.text),
                      email: Value(_emailController.text),
                      telefono: Value(_phoneController.text),
                      indirizzo: Value(_addressController.text),
                      comune: Value(_cityController.text),
                      provincia: Value(_provController.text),
                      cap: Value(_capController.text),
                      latitude: Value(lat),
                      longitude: Value(lng),
                      updatedAt: DateTime.now(),
                    ),
                  );

              // Push al Cloud
              final adminRepo = ref.read(adminRepositoryProvider);
              final updatedCompany = await (db.select(
                db.masterCompanies,
              )..where((t) => t.cuaa.equals(_cuaaController.text))).getSingle();
              await adminRepo.pushCompanyToCloud(updatedCompany);

              // Propagate to existing visits for this company
              await (db.update(
                db.visitCompanies,
              )..where((t) => t.cuaa.equals(_cuaaController.text))).write(
                VisitCompaniesCompanion(
                  latitude: Value(lat),
                  longitude: Value(lng),
                ),
              );
              final logger = ref.read(activityLoggerProvider);
              await logger.log(
                action: company == null ? 'ADD_COMPANY' : 'UPDATE_COMPANY',
                description:
                    '${company == null ? 'Aggiunta' : 'Aggiornata'} azienda: ${_ragioneSocialeController.text}',
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCompaniesFromExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isImportingExcel = true);

    try {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final db = ref.read(appDatabaseProvider);

      int count = 0;
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        // Assuming headers on row 0, data starts from row 1
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final cuaa = row[0]?.value?.toString().trim() ?? '';
          final ragioneSociale = row[1]?.value?.toString().trim() ?? '';
          if (cuaa.isEmpty || ragioneSociale.isEmpty) continue;

          final email = row.length > 2
              ? row[2]?.value?.toString().trim() ?? ''
              : '';
          final phone = row.length > 3
              ? row[3]?.value?.toString().trim() ?? ''
              : '';
          final address = row.length > 4
              ? row[4]?.value?.toString().trim() ?? ''
              : '';
          final city = row.length > 5
              ? row[5]?.value?.toString().trim() ?? ''
              : '';
          final prov = row.length > 6
              ? row[6]?.value?.toString().trim() ?? ''
              : '';
          final cap = row.length > 7
              ? row[7]?.value?.toString().trim() ?? ''
              : '';
          final lat = row.length > 8
              ? double.tryParse(
                  row[8]?.value?.toString().replaceAll(',', '.') ?? '',
                )
              : null;
          final lng = row.length > 9
              ? double.tryParse(
                  row[9]?.value?.toString().replaceAll(',', '.') ?? '',
                )
              : null;

          await db
              .into(db.masterCompanies)
              .insertOnConflictUpdate(
                MasterCompaniesCompanion.insert(
                  cuaa: cuaa,
                  ragioneSociale: Value(ragioneSociale),
                  email: Value(email),
                  telefono: Value(phone),
                  indirizzo: Value(address),
                  comune: Value(city),
                  provincia: Value(prov),
                  cap: Value(cap),
                  latitude: Value(lat),
                  longitude: Value(lng),
                  updatedAt: DateTime.now(),
                ),
              );
          count++;

          // Push al Cloud per ogni riga (o potresti fare un push massivo se AdminRepository lo supportasse)
          final updated = await (db.select(
            db.masterCompanies,
          )..where((t) => t.cuaa.equals(cuaa))).getSingle();
          await ref.read(adminRepositoryProvider).pushCompanyToCloud(updated);
        }
      }

      final logger = ref.read(activityLoggerProvider);
      await logger.log(
        action: 'IMPORT_COMPANIES_EXCEL',
        description: 'Importate $count aziende tramite Excel',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importazione completata: $count aziende elaborate.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'importazione: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingExcel = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final byteData = await rootBundle.load(
        'assets/templates/modello_import_aziende.xlsx',
      );
      final bytes = byteData.buffer.asUint8List();

      final result = await FilePicker.saveFile(
        dialogTitle: 'Salva Modello Importazione',
        fileName: 'modello_import_aziende.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modello scaricato con successo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il download: $e')),
        );
      }
    }
  }

  void _showImportHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Guida Importazione Excel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Il file Excel deve contenere le seguenti colonne nell\'ordine esatto (starting from row 2):',
              ),
              const SizedBox(height: 16),
              _buildLegendRow('A', 'CUAA (Obbligatorio)'),
              _buildLegendRow('B', 'Ragione Sociale (Obbligatorio)'),
              _buildLegendRow('C', 'Email'),
              _buildLegendRow('D', 'Telefono'),
              _buildLegendRow('E', 'Indirizzo'),
              _buildLegendRow('F', 'Comune'),
              _buildLegendRow('G', 'Provincia'),
              _buildLegendRow('H', 'CAP'),
              _buildLegendRow('I', 'Latitudine'),
              _buildLegendRow('J', 'Longitudine'),
              const SizedBox(height: 24),
              const Text(
                '💡 Scarica il modello pronto all\'uso:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('SCARICA MODELLO EXCEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String col, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              col,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _showHistoryDialog(MasterCompany company) {
    showDialog(
      context: context,
      builder: (context) => _CompanyHistoryDialog(company: company),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Anagrafica Aziende',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A237E),
          ),
        ),
        actions: [
          _isSyncing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _handleSync,
                  tooltip: 'Sincronizza con Cloud',
                  icon: const Icon(
                    Icons.sync_rounded,
                    color: Color(0xFF1A237E),
                  ),
                ),
          if (_isImportingExcel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _importCompaniesFromExcel,
              icon: const Icon(Icons.file_upload_rounded),
              tooltip: 'Importa da Excel',
            ),
          IconButton(
            onPressed: _showImportHelpDialog,
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.blueGrey,
            ),
            tooltip: 'Legenda Excel',
          ),
          IconButton(
            onPressed: () => _showAddCompanyDialog(),
            icon: const Icon(Icons.add_business_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cerca per ragione sociale o CUAA...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MasterCompany>>(
              stream: db.select(db.masterCompanies).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var list = snapshot.data!;
                if (_searchController.text.isNotEmpty) {
                  final q = _searchController.text.toLowerCase();
                  list = list
                      .where(
                        (e) =>
                            e.ragioneSociale.toLowerCase().contains(q) ||
                            e.cuaa.toLowerCase().contains(q),
                      )
                      .toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('Nessuna azienda trovata.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF1A237E,
                          ).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.ragioneSociale,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.latitude == null ||
                                item.longitude == null) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'Coordinate mancanti (non visibile sulla mappa)',
                                child: Icon(
                                  Icons.location_off_rounded,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${item.cuaa} • ${item.comune} (${item.provincia})',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF1A237E),
                              ),
                              tooltip: 'Storia Visite',
                              onPressed: () => _showHistoryDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showAddCompanyDialog(company: item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                // Ensure context is still valid before showing dialog
                                if (!context.mounted) return;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Elimina Azienda'),
                                    content: Text(
                                      'Sei sicuro di voler eliminare ${item.ragioneSociale}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Annulla'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text(
                                          'Elimina',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await (db.delete(
                                        db.masterCompanies,
                                      )..where((t) => t.cuaa.equals(item.cuaa)))
                                      .go();
                                  // Log deletion activity
                                  final logger = ref.read(
                                    activityLoggerProvider,
                                  );
                                  await logger.log(
                                    action: 'DELETE_COMPANY',
                                    description:
                                        'Eliminata azienda: ${item.ragioneSociale}',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHistoryDialog extends ConsumerWidget {
  final MasterCompany company;
  const _CompanyHistoryDialog({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final visitsAsync = ref.watch(companyVisitsProvider(company.cuaa));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: const Color(0xFFF8FAFC),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFF1A237E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Storia Visite',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              company.ragioneSociale,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 550,
        height: 450,
        child: visitsAsync.when(
          data: (visits) {
            if (visits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna visita trovata.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final v = visits[index];
                final dateStr = DateFormat(
                  'EEEE d MMMM yyyy',
                  'it_IT',
                ).format(v.scheduledAt);
                final statusLabel = visitStatusLabel(v.status);
                final statusColor = _getStatusColor(v.status);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1A237E,
                                ).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                v.visitType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A237E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            _buildStatusChip(statusLabel, statusColor),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.blueGrey.shade300,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v.inspectorName.isNotEmpty
                                  ? v.inspectorName
                                  : 'Ispettore non assegnato',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            StreamBuilder<int>(
                              stream: db.watchNcCountByVisitId(v.id),
                              builder: (context, snapshot) {
                                final ncs = snapshot.data ?? 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ncs > 0
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        ncs > 0
                                            ? Icons.warning_amber_rounded
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        size: 14,
                                        color: ncs > 0
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$ncs NC',
                                        style: TextStyle(
                                          color: ncs > 0
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A237E)),
          ),
          error: (e, stack) => Center(child: Text('Errore: $e')),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'CHIUDI',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: // daIniziare
        return const Color(0xFF64748B);
      case 1: // inCorso
        return Colors.amber.shade700;
      case 2: // chiusaDaSincronizzare
        return const Color(0xFF10B981);
      case 3: // sincronizzata
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }
}
