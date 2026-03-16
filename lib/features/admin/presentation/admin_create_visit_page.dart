import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../application/activity_logger.dart';
import '../../../core/services/geocoding_service.dart';

import '../../audits/domain/visit_with_company.dart';

class AdminCreateVisitPage extends ConsumerStatefulWidget {
  final VisitWithCompany? initialVisit;
  
  const AdminCreateVisitPage({super.key, this.initialVisit});

  @override
  ConsumerState<AdminCreateVisitPage> createState() => _AdminCreateVisitPageState();
}

class _AdminCreateVisitPageState extends ConsumerState<AdminCreateVisitPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _idController = TextEditingController();
  final _companyController = TextEditingController();
  final _cuaaController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provController = TextEditingController();
  final _cropController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _durationController = TextEditingController();
  
  DateTime _scheduledDate = DateTime.now();
  String? _selectedInspector;
  bool _isSaving = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialVisit != null) {
      final v = widget.initialVisit!.visit;
      final c = widget.initialVisit!.company;
      _idController.text = v.id;
      _companyController.text = v.companyName;
      _cuaaController.text = c.cuaa;
      _addressController.text = c.indirizzo;
      _cityController.text = c.comune;
      _provController.text = c.provincia;
      _cropController.text = v.crop;
      _latController.text = c.latitude?.toString() ?? '';
      _lngController.text = c.longitude?.toString() ?? '';
      _durationController.text = v.plannedDurationHours.toString();
      _scheduledDate = v.scheduledAt;
      _selectedInspector = v.inspectorName.isEmpty ? null : v.inspectorName;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _companyController.dispose();
    _cuaaController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provController.dispose();
    _cropController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final isEdit = widget.initialVisit != null;
      final visitId = isEdit 
          ? widget.initialVisit!.visit.id 
          : (_idController.text.isEmpty ? 'V-MAN-${DateTime.now().millisecondsSinceEpoch}' : _idController.text);

      // Use a transaction for consistency
      await db.transaction(() async {
        // 1. Insert Visit
        await db.into(db.visits).insertOnConflictUpdate(
          VisitsCompanion.insert(
            id: visitId,
            scheduledAt: _scheduledDate,
            companyName: _companyController.text,
            crop: _cropController.text.isEmpty ? 'Varie' : _cropController.text,
            status: 0,
            updatedAt: DateTime.now(),
            inspectorName: Value(_selectedInspector ?? ''),
            visitType: const Value('ACA'),
            plannedDurationHours: Value(int.tryParse(_durationController.text) ?? 0),
          ),
        );

        // 2. Insert/Update Company Details (Visit Specific)
        await db.into(db.visitCompanies).insertOnConflictUpdate(
          VisitCompaniesCompanion.insert(
            visitId: visitId,
            updatedAt: DateTime.now(),
            ragioneSociale: Value(_companyController.text),
            cuaa: Value(_cuaaController.text),
            indirizzo: Value(_addressController.text),
            comune: Value(_cityController.text),
            provincia: Value(_provController.text),
            latitude: Value(double.tryParse(_latController.text.replaceAll(',', '.'))),
            longitude: Value(double.tryParse(_lngController.text.replaceAll(',', '.'))),
          ),
        );

        // 3. Upsert Master Anagrafica Azienda (Centralized)
        await db.into(db.masterCompanies).insertOnConflictUpdate(
          MasterCompaniesCompanion.insert(
            cuaa: _cuaaController.text,
            ragioneSociale: Value(_companyController.text),
            indirizzo: Value(_addressController.text),
            comune: Value(_cityController.text),
            provincia: Value(_provController.text),
            latitude: Value(double.tryParse(_latController.text.replaceAll(',', '.'))),
            longitude: Value(double.tryParse(_lngController.text.replaceAll(',', '.'))),
            updatedAt: DateTime.now(),
          ),
        );
      });

      final logger = ref.read(activityLoggerProvider);
      await logger.log(
        action: isEdit ? 'UPDATE_VISIT_MANUAL' : 'CREATE_VISIT_MANUAL',
        description: '${isEdit ? 'Aggiornata' : 'Creata'} manualmente visita $visitId per ${_companyController.text}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visita ${isEdit ? 'aggiornata' : 'creata'} con successo!')),
        );
        if (isEdit) {
          Navigator.pop(context);
          return;
        }
        // Clear form
        _idController.clear();
        _companyController.clear();
        _cuaaController.clear();
        _addressController.clear();
        _cityController.clear();
        _provController.clear();
        _cropController.clear();
        _latController.clear();
        _lngController.clear();
        setState(() {
          _selectedInspector = null;
          _durationController.clear();
          _scheduledDate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final province = _provController.text.trim();

    if (address.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno Indirizzo e Comune per localizzare.')),
      );
      return;
    }

    setState(() => _isGeocoding = true);

    try {
      final geocodingService = ref.read(geocodingServiceProvider);
      final coords = await geocodingService.getCoordinates(
        address: address,
        city: city,
        province: province,
      );

      if (coords != null) {
        _latController.text = coords.lat.toStringAsFixed(6);
        _lngController.text = coords.lon.toStringAsFixed(6);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Posizione individuata con successo!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Indirizzo non trovato su mappa.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la geocodifica: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final inspectorsAsync = ref.watch(StreamProvider((ref) => db.select(db.inspectors).watch()));

    final isEdit = widget.initialVisit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A237E)),
        ),
        title: Text(isEdit ? 'Modifica Ispezione' : 'Nuova Ispezione', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(isEdit ? Icons.edit_calendar_rounded : Icons.add_task_rounded, color: const Color(0xFF1A237E), size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Revisione Ispezione' : 'Pianificazione Manuale',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -1),
                        ),
                        Text(
                          isEdit ? 'Aggiorna i dettagli della visita e dell\'azienda.' : 'Inserisci i dettagli per registrare una nuova ispezione nel database.',
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSectionCard(
                      title: 'Dati Ispezione',
                      icon: Icons.calendar_today_rounded,
                      children: [
                        _buildModernTextField(
                          controller: _idController,
                          label: 'Codice Visita (opzionale)',
                          hint: 'Generato automaticamente se vuoto',
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        inspectorsAsync.when(
                          data: (list) => _buildInspectorDropdown(list),
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => const Text('Errore caricamento ispettori'),
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _durationController,
                          label: 'Durata Programmata (ore)',
                          hint: 'es. 4',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: _buildSectionCard(
                      title: 'Dati Azienda e Coltura',
                      icon: Icons.business_rounded,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: _companyController,
                                label: 'Ragione Sociale',
                                validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: IconButton.filledTonal(
                                onPressed: () async {
                                  final db = ref.read(appDatabaseProvider);
                                  final companies = await db.select(db.masterCompanies).get();
                                  if (!context.mounted) return;
                                  
                                  final chosen = await showDialog<MasterCompany>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Seleziona Azienda'),
                                      content: SizedBox(
                                        width: 400,
                                        height: 400,
                                        child: ListView.builder(
                                          itemCount: companies.length,
                                          itemBuilder: (context, index) {
                                            final c = companies[index];
                                            return ListTile(
                                              title: Text(c.ragioneSociale),
                                              subtitle: Text(c.cuaa),
                                              onTap: () => Navigator.pop(dialogContext, c),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );

                                  if (chosen != null) {
                                    setState(() {
                                      _companyController.text = chosen.ragioneSociale;
                                      _cuaaController.text = chosen.cuaa;
                                      _addressController.text = chosen.indirizzo;
                                      _cityController.text = chosen.comune;
                                      _provController.text = chosen.provincia;
                                      _latController.text = chosen.latitude?.toString() ?? '';
                                      _lngController.text = chosen.longitude?.toString() ?? '';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.search),
                                tooltip: 'Cerca in anagrafica',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(controller: _addressController, label: 'Indirizzo (Via, civico)'),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildModernTextField(controller: _cuaaController, label: 'CUAA')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildModernTextField(controller: _cropController, label: 'Coltura Prevalente')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(flex: 3, child: _buildModernTextField(controller: _cityController, label: 'Comune')),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: _buildModernTextField(controller: _provController, label: 'Prov')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildModernTextField(controller: _latController, label: 'Latitudine', hint: 'es. 45.4642')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildModernTextField(controller: _lngController, label: 'Longitudine', hint: 'es. 9.1900')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isGeocoding ? null : _geocodeAddress,
                            icon: _isGeocoding 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.location_on_rounded, size: 18),
                            label: Text(_isGeocoding ? 'RICERCA IN CORSO...' : 'LOCALIZZA INDIRIZZO'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveVisit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.3),
                    ),
                    child: _isSaving 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEdit ? Icons.check_circle_rounded : Icons.save_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(isEdit ? 'CONFERMA MODIFICHE' : 'REGISTRA ISPEZIONE', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A237E).withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A237E), size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1)),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A237E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF1A237E), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Programmazione', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                Text(DateFormat('dd MMMM yyyy', 'it_IT').format(_scheduledDate), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorDropdown(List<Inspector> inspectors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('ISPETTORE ASSEGNATO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedInspector,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A237E), fontSize: 16),
              decoration: const InputDecoration(border: InputBorder.none),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nessun ispettore', style: TextStyle(fontWeight: FontWeight.w400, color: Colors.blueGrey))),
                ...inspectors.map((i) => DropdownMenuItem(
                  value: i.fullName,
                  child: Text(i.fullName),
                )),
              ],
              onChanged: (val) => setState(() => _selectedInspector = val),
            ),
          ),
        ),
      ],
    );
  }
}
