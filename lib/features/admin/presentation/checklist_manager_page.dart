import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final checklistVersionsProvider = StreamProvider<List<ChecklistVersion>>((ref) {
  return ref.watch(appDatabaseProvider).watchChecklistVersions();
});

final selectedVersionIdProvider = StateProvider<String?>((ref) => null);

final checklistItemsProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, versionId) {
      return ref.watch(appDatabaseProvider).watchChecklistItems(versionId);
    });

class ChecklistManagerPage extends ConsumerStatefulWidget {
  const ChecklistManagerPage({super.key});

  @override
  ConsumerState<ChecklistManagerPage> createState() =>
      _ChecklistManagerPageState();
}

class _ChecklistManagerPageState extends ConsumerState<ChecklistManagerPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final versionsAsync = ref.watch(checklistVersionsProvider);
    final selectedVersionId = ref.watch(selectedVersionIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestione Master Checklist',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            onPressed: () => _showNewVersionDialog(context),
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Nuova Versione',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selettore Versione
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: versionsAsync.when(
              data: (versions) {
                if (versions.isEmpty) {
                  return const Text('Nessuna versione trovata');
                }

                // Imposta la prima come selezionata se nullo
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (selectedVersionId == null && versions.isNotEmpty) {
                    ref.read(selectedVersionIdProvider.notifier).state =
                        versions.first.id;
                  }
                });

                return DropdownButtonFormField<String>(
                  initialValue:
                      selectedVersionId ??
                      (versions.isNotEmpty ? versions.first.id : null),
                  decoration: const InputDecoration(
                    labelText: 'Versione Checklist Attiva',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: versions
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            '${v.name} ${v.isActive ? "(ATTIVA)" : ""}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    ref.read(selectedVersionIdProvider.notifier).state = val;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Errore: $e'),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca per codice o testo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Lista Requisiti
          Expanded(
            child: selectedVersionId == null
                ? const Center(child: Text('Seleziona una versione'))
                : ref
                      .watch(checklistItemsProvider(selectedVersionId))
                      .when(
                        data: (items) {
                          final filtered = items.where((item) {
                            return item.code.contains(_searchQuery) ||
                                item.obbligo.toLowerCase().contains(
                                  _searchQuery,
                                );
                          }).toList();

                          return ListView.builder(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _RequirementCard(item: item);
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Errore: $e')),
                      ),
          ),
        ],
      ),
    );
  }

  void _showNewVersionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crea Nuova Versione'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'es: SQNPI 2025 v1.0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await ref
                  .read(appDatabaseProvider)
                  .createChecklistVersion(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
}

class _RequirementCard extends ConsumerWidget {
  final ChecklistItem item;
  const _RequirementCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(
          'Requisito ${item.code}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          item.obbligo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
        ),
        leading: CircleAvatar(
          backgroundColor: _getIndicatorColor(
            item.indicatorType,
          ).withValues(alpha: 0.1),
          child: Text(
            item.indicatorType.isNotEmpty ? item.indicatorType[0] : '?',
            style: TextStyle(
              color: _getIndicatorColor(item.indicatorType),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Note Norma', item.noteNorma),
                const SizedBox(height: 12),
                _infoRow('Gravità UEC', item.gravitaUecText),
                const SizedBox(height: 12),
                _infoRow('Gravità Operatore', item.gravitaOperatoreText),
                const Divider(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context, ref),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Modifica Testi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Non definito' : value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Color _getIndicatorColor(String type) {
    if (type.contains('KO')) return Colors.red;
    if (type.contains('Obbligatorio')) return Colors.orange;
    return Colors.blue;
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final obbligoController = TextEditingController(text: item.obbligo);
    final noteController = TextEditingController(text: item.noteNorma);
    final uecGravitaController = TextEditingController(
      text: item.gravitaUecText,
    );
    final opGravitaController = TextEditingController(
      text: item.gravitaOperatoreText,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica Requisito ${item.code}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: obbligoController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Testo Requisito'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note Norma'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uecGravitaController,
                decoration: const InputDecoration(labelText: 'Gravità UEC'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opGravitaController,
                decoration: const InputDecoration(
                  labelText: 'Gravità Operatore',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(appDatabaseProvider)
                  .updateChecklistItem(
                    code: item.code,
                    versionId: item.versionId,
                    obbligo: obbligoController.text,
                    noteNorma: noteController.text,
                    gravitaUecText: uecGravitaController.text,
                    gravitaOperatoreText: opGravitaController.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salva Modifiche'),
          ),
        ],
      ),
    );
  }
}
