import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;
import '../application/activity_logger.dart';

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
    } else {
      _cuaaController.clear();
      _ragioneSocialeController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _cityController.clear();
      _provController.clear();
      _capController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Text(
          company == null ? 'Nuova Azienda' : 'Modifica Azienda',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModernTextField(controller: _cuaaController, label: 'CUAA / Codice Fiscale', icon: Icons.badge_outlined, enabled: company == null),
                const SizedBox(height: 12),
                _buildModernTextField(controller: _ragioneSocialeController, label: 'Ragione Sociale', icon: Icons.business_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildModernTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModernTextField(controller: _phoneController, label: 'Telefono', icon: Icons.phone_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModernTextField(controller: _addressController, label: 'Indirizzo', icon: Icons.location_on_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildModernTextField(controller: _cityController, label: 'Comune', icon: Icons.map_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModernTextField(controller: _provController, label: 'Prov', icon: null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModernTextField(controller: _capController, label: 'CAP', icon: null)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              if (_cuaaController.text.isEmpty || _ragioneSocialeController.text.isEmpty) return;
              final db = ref.read(appDatabaseProvider);
              await db.into(db.masterCompanies).insertOnConflictUpdate(
                MasterCompaniesCompanion.insert(
                  cuaa: _cuaaController.text,
                  ragioneSociale: Value(_ragioneSocialeController.text),
                  email: Value(_emailController.text),
                  telefono: Value(_phoneController.text),
                  indirizzo: Value(_addressController.text),
                  comune: Value(_cityController.text),
                  provincia: Value(_provController.text),
                  cap: Value(_capController.text),
                  updatedAt: DateTime.now(),
                ),
              );
              final logger = ref.read(activityLoggerProvider);
              await logger.log(
                action: company == null ? 'ADD_COMPANY' : 'UPDATE_COMPANY',
                description: '${company == null ? 'Aggiunta' : 'Aggiornata'} azienda: ${_ragioneSocialeController.text}',
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({required TextEditingController controller, required String label, IconData? icon, bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        title: const Text('Anagrafica Aziende', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
        actions: [
          IconButton(onPressed: () => _showAddCompanyDialog(), icon: const Icon(Icons.add_business_rounded)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MasterCompany>>(
              stream: db.select(db.masterCompanies).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var list = snapshot.data!;
                if (_searchController.text.isNotEmpty) {
                  final q = _searchController.text.toLowerCase();
                  list = list.where((e) => e.ragioneSociale.toLowerCase().contains(q) || e.cuaa.toLowerCase().contains(q)).toList();
                }

                if (list.isEmpty) return const Center(child: Text('Nessuna azienda trovata.'));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1), child: const Icon(Icons.business, color: Color(0xFF1A237E))),
                        title: Text(item.ragioneSociale, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.cuaa} • ${item.comune} (${item.provincia})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showAddCompanyDialog(company: item)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                // Ensure context is still valid before showing dialog
                                if (!context.mounted) return;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Elimina Azienda'),
                                    content: Text('Sei sicuro di voler eliminare ${item.ragioneSociale}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annulla')),
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await (db.delete(db.masterCompanies)..where((t) => t.cuaa.equals(item.cuaa))).go();
                                  // Log deletion activity
                                  final logger = ref.read(activityLoggerProvider);
                                  await logger.log(
                                    action: 'DELETE_COMPANY',
                                    description: 'Eliminata azienda: ${item.ragioneSociale}',
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
