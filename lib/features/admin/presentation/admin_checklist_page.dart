import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../application/activity_logger.dart';

class AdminChecklistPage extends ConsumerStatefulWidget {
  const AdminChecklistPage({super.key});

  @override
  ConsumerState<AdminChecklistPage> createState() => _AdminChecklistPageState();
}

class _AdminChecklistPageState extends ConsumerState<AdminChecklistPage> {
  final _searchController = TextEditingController();
  String? _selectedFase;

  void _showEditItemDialog(ChecklistItem item) {
    final obbligoController = TextEditingController(text: item.obbligo);
    final noteNormaController = TextEditingController(text: item.noteNorma);
    final indicatorController = TextEditingController(text: item.indicatorType);
    final derogheController = TextEditingController(text: item.deroghe);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Requisito ${item.code}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(controller: obbligoController, label: 'Descrizione Obbligo', maxLines: 5),
                const SizedBox(height: 16),
                _buildField(controller: noteNormaController, label: 'Note Norma', maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField(controller: indicatorController, label: 'Tipo Indicatore (CI/CD)')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(controller: derogheController, label: 'Deroghe')),
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
              final db = ref.read(appDatabaseProvider);
              await db.into(db.checklistItems).insertOnConflictUpdate(
                ChecklistItemsCompanion(
                  code: Value(item.code),
                  obbligo: Value(obbligoController.text.trim()),
                  noteNorma: Value(noteNormaController.text.trim()),
                  indicatorType: Value(indicatorController.text.trim()),
                  deroghe: Value(derogheController.text.trim()),
                  fase: Value(item.fase),
                  sortOrder: Value(item.sortOrder),
                  tipologiaControllo: Value(item.tipologiaControllo),
                  frequenzaSingolo: Value(item.frequenzaSingolo),
                  frequenzaAssociato: Value(item.frequenzaAssociato),
                  gravitaUecText: Value(item.gravitaUecText),
                  esclusioneUecText: Value(item.esclusioneUecText),
                  gravitaOperatoreText: Value(item.gravitaOperatoreText),
                  esclusioneOperatoreText: Value(item.esclusioneOperatoreText),
                  esclusioneLottoText: Value(item.esclusioneLottoText),
                  hasEsclusioneLotto: Value(item.hasEsclusioneLotto),
                  colGText: Value(item.colGText),
                  disposizioniRegionali: Value(item.disposizioniRegionali),
                ),
              );
              
              final logger = ref.read(activityLoggerProvider);
              await logger.log(
                action: 'UPDATE_CHECKLIST_ITEM',
                description: 'Modificato requisito ${item.code}',
              );

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text('Salva Modifiche'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final fasiAsync = ref.watch(StreamProvider((ref) => db.watchFasi()));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Gestione Checklist Master', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Checklist'),
                  content: const Text('Questo ripristinerà tutti i testi originali dall\'Excel ufficiale. Le modifiche manuali andranno perse. Continuare?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Reset', style: TextStyle(color: Colors.red))
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await db.resetChecklistAndReimport();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checklist ripristinata con successo.')));
              }
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
            label: const Text('Ripristina Originale', style: TextStyle(color: Colors.orange)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cerca per codice o testo...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: fasiAsync.when(
                    data: (fasi) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedFase,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        hint: const Text('Tutte le fasi'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tutte le fasi')),
                          ...fasi.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setState(() => _selectedFase = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, stack) => const Text('Errore fasi'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChecklistItem>>(
              stream: db.select(db.checklistItems).watch(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var list = snapshot.data!;
                if (_selectedFase != null) {
                  list = list.where((e) => e.fase == _selectedFase).toList();
                }
                if (_searchController.text.isNotEmpty) {
                  final q = _searchController.text.toLowerCase();
                  list = list.where((e) => e.code.toLowerCase().contains(q) || e.obbligo.toLowerCase().contains(q)).toList();
                }

                list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                if (list.isEmpty) return const Center(child: Text('Nessun requisito trovato.'));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isHeader = item.code.split('.').last == '0' || !item.code.contains('.');
                    
                    return Card(
                      elevation: 0,
                      color: isHeader ? Colors.blue.shade50.withValues(alpha: 0.3) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isHeader ? Colors.blue.shade100 : Colors.transparent),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isHeader ? Colors.blue.shade100 : Colors.grey.shade100,
                          child: Text(item.code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHeader ? Colors.blue.shade900 : Colors.grey.shade700)),
                        ),
                        title: Text(item.obbligo, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(item.fase, style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1A237E)),
                          onPressed: () => _showEditItemDialog(item),
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
