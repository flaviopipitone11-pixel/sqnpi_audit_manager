import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;
import '../application/activity_logger.dart';

import '../data/admin_repository.dart';
import '../data/workload_providers.dart';

import 'package:intl/intl.dart';

import '../../audits/presentation/visit_workspace_page.dart';

final inspectorVisitsProvider = StreamProvider.family<List<Visit>, String>((
  ref,
  email,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisitsByEmail(email);
});

class AdminInspectorsPage extends ConsumerStatefulWidget {
  const AdminInspectorsPage({super.key});

  @override
  ConsumerState<AdminInspectorsPage> createState() =>
      _AdminInspectorsPageState();
}

class _AdminInspectorsPageState extends ConsumerState<AdminInspectorsPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _inspectorCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSync();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _inspectorCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final repo = ref.read(adminRepositoryProvider);
    await repo.syncInspectorsWithCloud();
    if (mounted) setState(() => _isSyncing = false);
  }

  void _showHistoryDialog(Inspector item) {
    showDialog(
      context: context,
      builder: (context) => _InspectorHistoryDialog(inspector: item),
    );
  }

  void _showAddInspectorDialog({Inspector? inspector}) {
    if (inspector != null) {
      _firstNameController.text = inspector.firstName;
      _lastNameController.text = inspector.lastName;
      _inspectorCodeController.text = inspector.inspectorCode;

      // Fallback for old records
      if (_firstNameController.text.isEmpty && inspector.fullName.isNotEmpty) {
        final parts = inspector.fullName.split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }

      _emailController.text = inspector.email;
      _phoneController.text = inspector.phone;
      _regionController.text = inspector.region;
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      _inspectorCodeController.clear();
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
              child: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFF1A237E),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              inspector == null ? 'Nuovo Ispettore' : 'Modifica Ispettore',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                fontSize: 22,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _firstNameController,
                      label: 'Nome',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _lastNameController,
                      label: 'Cognome',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _inspectorCodeController,
                label: 'Codice Ispettore',
                icon: Icons.badge_outlined,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_firstNameController.text.isEmpty ||
                        _lastNameController.text.isEmpty) {
                      return;
                    }

                    final db = ref.read(appDatabaseProvider);
                    final id =
                        inspector?.id ??
                        'ISP-${DateTime.now().millisecondsSinceEpoch}';

                    final fullName =
                        '${_firstNameController.text} ${_lastNameController.text}'
                            .trim();

                    final companion = InspectorsCompanion.insert(
                      id: id,
                      firstName: Value(_firstNameController.text),
                      lastName: Value(_lastNameController.text),
                      fullName: Value(fullName),
                      inspectorCode: Value(_inspectorCodeController.text),
                      email: Value(_emailController.text),
                      phone: Value(_phoneController.text),
                      region: Value(_regionController.text),
                      isActive: inspector == null
                          ? const Value(false)
                          : Value(inspector.isActive),
                      createdAt: inspector?.createdAt ?? DateTime.now(),
                    );

                    await db
                        .into(db.inspectors)
                        .insertOnConflictUpdate(companion);

                    // Push al Cloud per sincronizzazione
                    final adminRepo = ref.read(adminRepositoryProvider);
                    final updatedInspector = await (db.select(
                      db.inspectors,
                    )..where((t) => t.id.equals(id))).getSingle();
                    await adminRepo.pushInspectorToCloud(updatedInspector);

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: inspector == null
                          ? 'ADD_INSPECTOR'
                          : 'UPDATE_INSPECTOR',
                      description:
                          '${inspector == null ? 'Aggiunto' : 'Aggiornato'} ispettore: $fullName (${_regionController.text})',
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (inspector == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 5),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Ispettore aggiunto. Genera le credenziali dal menu per attivare l\'account.',
                            ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Salva',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF1A237E).withValues(alpha: 0.5),
          size: 20,
        ),
        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF1A237E),
          fontWeight: FontWeight.bold,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
        title: const Text(
          'Anagrafica Collaboratori',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A237E),
            letterSpacing: -0.5,
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showAddInspectorDialog(),
              icon: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFF1A237E),
              ),
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
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 80,
                      color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nessun ispettore censito',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A237E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Inizia aggiungendo il primo collaboratore\nper pianificare le tue ispezioni.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => _showAddInspectorDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Aggiungi Collaboratore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.blueGrey.shade50),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showHistoryDialog(item),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1A237E),
                                      const Color(0xFF3949AB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    item.fullName.characters.first
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              color: Color(0xFF1E293B),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        if (MediaQuery.of(context).size.width >=
                                            600)
                                          _AccountBadge(
                                            isActive: item.isActive,
                                          ),
                                      ],
                                    ),
                                    if (MediaQuery.of(context).size.width < 600)
                                      const SizedBox(height: 4),
                                    if (MediaQuery.of(context).size.width < 600)
                                      _AccountBadge(isActive: item.isActive),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 14,
                                          color: Colors.blueGrey.shade400,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.region.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF3B82F6),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _ContactInfo(
                                icon: Icons.email_outlined,
                                text: item.email,
                              ),
                              _ContactInfo(
                                icon: Icons.phone_outlined,
                                text: item.phone,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _WorkloadIndicator(
                                    label: 'P',
                                    count: workload.plannedCount,
                                    color: Colors.blue,
                                    tooltip: 'Pianificate',
                                  ),
                                  const SizedBox(width: 8),
                                  _WorkloadIndicator(
                                    label: 'C',
                                    count: workload.inProgressCount,
                                    color: Colors.orange,
                                    tooltip: 'In Corso',
                                  ),
                                  const SizedBox(width: 8),
                                  _WorkloadIndicator(
                                    label: 'F',
                                    count: workload.completedCount,
                                    color: Colors.green,
                                    tooltip: 'Concluse',
                                  ),
                                ],
                              ),
                              Row(
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
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFF1A237E),
                                    ),
                                    onPressed: () => _showAddInspectorDialog(
                                      inspector: item,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          title: const Column(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 48,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Elimina Collaboratore',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF1A237E),
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'Sei sicuro di voler rimuovere ${item.fullName} dall\'anagrafica?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade600,
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.center,
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                'ANNULLA',
                                                style: TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'ELIMINA',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final db = ref.read(
                                          appDatabaseProvider,
                                        );
                                        await (db.delete(db.inspectors)..where(
                                              (t) => t.id.equals(item.id),
                                            ))
                                            .go();

                                        // Aggiunto per eliminare l'ispettore dal database Supabase
                                        await ref
                                            .read(adminRepositoryProvider)
                                            .deleteInspectorFromCloud(item.id);

                                        final logger = ref.read(
                                          activityLoggerProvider,
                                        );
                                        await logger.log(
                                          action: 'DELETE_INSPECTOR',
                                          description:
                                              'Eliminato ispettore: ${item.fullName}',
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey.shade400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
        border: Border.all(
          color: (isActive ? Colors.green : Colors.orange).withValues(
            alpha: 0.2,
          ),
        ),
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

class _InspectorHistoryDialog extends ConsumerWidget {
  final Inspector inspector;
  const _InspectorHistoryDialog({required this.inspector});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(inspectorVisitsProvider(inspector.email));

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
              inspector.fullName,
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

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitWorkspacePage(
                            visitId: v.id,
                            forceReadOnly: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueGrey.shade50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1A237E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.companyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Errore: $err')),
        ),
      ),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'CHIUDI',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
