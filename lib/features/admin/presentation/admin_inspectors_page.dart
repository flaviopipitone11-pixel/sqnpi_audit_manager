import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;
import '../application/activity_logger.dart';
import '../application/inspector_action_service.dart';
import '../data/workload_providers.dart';

class AdminInspectorsPage extends ConsumerStatefulWidget {
  const AdminInspectorsPage({super.key});

  @override
  ConsumerState<AdminInspectorsPage> createState() => _AdminInspectorsPageState();
}

class _AdminInspectorsPageState extends ConsumerState<AdminInspectorsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();

  void _showAddInspectorDialog({Inspector? inspector}) {
    if (inspector != null) {
      _nameController.text = inspector.fullName;
      _emailController.text = inspector.email;
      _phoneController.text = inspector.phone;
      _regionController.text = inspector.region;
    } else {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _regionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_rounded, color: Color(0xFF1A237E), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              inspector == null ? 'Nuovo Ispettore' : 'Modifica Ispettore',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), fontSize: 22),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernTextField(
                controller: _nameController,
                label: 'Nome Completo',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _phoneController,
                label: 'Telefono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _regionController,
                label: 'Regione Operativa',
                icon: Icons.map_outlined,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annulla', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) return;
                    
                    final db = ref.read(appDatabaseProvider);
                    final id = inspector?.id ?? 'ISP-${DateTime.now().millisecondsSinceEpoch}';
                    
                    await db.into(db.inspectors).insertOnConflictUpdate(
                      InspectorsCompanion.insert(
                        id: id,
                        fullName: Value(_nameController.text),
                        email: Value(_emailController.text),
                        phone: Value(_phoneController.text),
                        region: Value(_regionController.text),
                        isActive: inspector == null ? const Value(false) : Value(inspector.isActive),
                        createdAt: DateTime.now(),
                      )
                    );

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: inspector == null ? 'ADD_INSPECTOR' : 'UPDATE_INSPECTOR',
                      description: '${inspector == null ? 'Aggiunto' : 'Aggiornato'} ispettore: ${_nameController.text} (${_regionController.text})',
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (inspector == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 5),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Ispettore aggiunto. Genera le credenziali dal menu per attivare l\'account.'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E).withValues(alpha: 0.5), size: 20),
        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workloadAsync = ref.watch(inspectorsWorkloadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Anagrafica Collaboratori', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showAddInspectorDialog(),
              icon: const Icon(Icons.person_add_rounded, color: Color(0xFF1A237E)),
            ),
          ),
        ],
      ),
      body: workloadAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_outline_rounded, size: 80, color: const Color(0xFF1A237E).withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nessun ispettore censito',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Inizia aggiungendo il primo collaboratore\nper pianificare le tue ispezioni.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => _showAddInspectorDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Aggiungi Collaboratore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final workload = list[index];
              final item = workload.inspector;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          item.fullName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B)))),
                        _AccountBadge(isActive: item.isActive),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.map_outlined, size: 14, color: Colors.blueGrey.shade300),
                              const SizedBox(width: 6),
                              Text(item.region.toUpperCase(), style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(width: 12),
                              Icon(Icons.email_outlined, size: 14, color: Colors.blueGrey.shade300),
                              const SizedBox(width: 6),
                              Text(item.email, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.blueGrey.shade300),
                              const SizedBox(width: 6),
                              Text(item.phone, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _WorkloadIndicator(label: 'P', count: workload.plannedCount, color: Colors.blue, tooltip: 'Pianificate'),
                              const SizedBox(width: 8),
                              _WorkloadIndicator(label: 'C', count: workload.inProgressCount, color: Colors.orange, tooltip: 'In Corso'),
                              const SizedBox(width: 8),
                              _WorkloadIndicator(label: 'F', count: workload.completedCount, color: Colors.green, tooltip: 'Concluse'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (val) async {
                            final service = ref.read(inspectorActionServiceProvider);
                            if (val == 'account') {
                              await service.createAccount(item.id, item.fullName);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      content: Text('Account attivo per ${item.fullName}'),
                                    ),
                                  );
                                }
                            } else if (val == 'notify') {
                              await service.sendCredentials(item.id, item.fullName, item.email, item.phone);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF1A237E),
                                      behavior: SnackBarBehavior.floating,
                                      content: Text('Credenziali inviate via Email e SMS a ${item.fullName}'),
                                    ),
                                  );
                                }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'account',
                              child: Row(children: [Icon(Icons.vpn_key_outlined, size: 20), SizedBox(width: 12), Text('Crea Account')]),
                            ),
                            const PopupMenuItem(
                              value: 'notify',
                              child: Row(children: [Icon(Icons.send_outlined, size: 20), SizedBox(width: 12), Text('Invia Credenziali')]),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A237E)),
                          onPressed: () => _showAddInspectorDialog(inspector: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                title: const Column(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                                    SizedBox(height: 16),
                                    Text('Elimina Collaboratore', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                                  ],
                                ),
                                content: Text(
                                  'Sei sicuro di voler rimuovere ${item.fullName} dall\'anagrafica? Questa azione non può essere annullata.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14, height: 1.5),
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('ANNULLA', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w900)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('ELIMINA PER SEMPRE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final db = ref.read(appDatabaseProvider);
                              await (db.delete(db.inspectors)..where((t) => t.id.equals(item.id))).go();
                              
                              final logger = ref.read(activityLoggerProvider);
                              await logger.log(
                                action: 'DELETE_INSPECTOR',
                                description: 'Eliminato ispettore: ${item.fullName}',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkloadIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String tooltip;

  const _WorkloadIndicator({
    required this.label,
    required this.count,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$tooltip: $count',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final bool isActive;
  const _AccountBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.2)),
      ),
      child: Text(
        isActive ? 'ATTIVO' : 'DA ATTIVARE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
