import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../admin/application/activity_logger.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/geocoding_service.dart';

class InspectorCreateVisitPage extends ConsumerStatefulWidget {
  const InspectorCreateVisitPage({super.key});

  @override
  ConsumerState<InspectorCreateVisitPage> createState() => _InspectorCreateVisitPageState();
}

class _InspectorCreateVisitPageState extends ConsumerState<InspectorCreateVisitPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyController = TextEditingController();
  final _cuaaController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provController = TextEditingController();
  final _cropController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  DateTime _scheduledDate = DateTime.now();
  bool _isSaving = false;
  bool _isGeocoding = false;

  @override
  void dispose() {
    _companyController.dispose();
    _cuaaController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provController.dispose();
    _cropController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
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
      final auth = ref.read(authControllerProvider);
      final inspectorName = auth.username ?? 'Ispettore';
      
      final visitId = 'V-ISP-${DateTime.now().millisecondsSinceEpoch}';

      await db.transaction(() async {
        // 1. Insert Visit
        await db.into(db.visits).insert(
          VisitsCompanion.insert(
            id: visitId,
            scheduledAt: _scheduledDate,
            companyName: _companyController.text,
            crop: _cropController.text.isEmpty ? 'Varie' : _cropController.text,
            status: 0,
            updatedAt: DateTime.now(),
            inspectorName: Value(inspectorName),
            visitType: const Value('ACA'),
          ),
        );

        // 2. Insert Company Details
        await db.into(db.visitCompanies).insert(
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

        // 3. Create a default UEC (Unità Elementare di Controllo)
        // Without this, the inspector would see an empty workspace.
        await db.into(db.visitUecs).insert(
          VisitUecsCompanion.insert(
            id: 'UEC-$visitId-DEF',
            visitId: visitId,
            coltura: Value(_cropController.text.isEmpty ? 'Varie' : _cropController.text),
            descrizione: const Value('Unità di Controllo Predefinita'),
            updatedAt: DateTime.now(),
          ),
        );
      });

      final logger = ref.read(activityLoggerProvider);
      await logger.log(
        action: 'CREATE_VISIT_INSPECTOR',
        description: 'Ispettore $inspectorName ha creato la visita $visitId per ${_companyController.text}',
        actor: inspectorName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita creata! Reindirizzamento in corso...'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        // Navigate directly to the visit workspace
        context.go('/visit/$visitId');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
        ),
        title: const Text('Crea Nuova Visita', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF059669), size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pianifica Ispezione',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
                  ),
                  const Text(
                    'Inserisci i dati dell\'azienda per iniziare un nuovo controllo SQNPI.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormCard(
                      children: [
                        _buildField(
                          controller: _companyController,
                          label: 'RAGIONE SOCIALE',
                          hint: 'es. Azienda Agricola Bianchi',
                          validator: (v) => v!.isEmpty ? 'Necessario' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _cuaaController,
                          label: 'CUAA',
                          hint: 'es. BNCHHR80A01H501Z',
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _cropController,
                          label: 'COLTURA PREVALENTE',
                          hint: 'es. Vite / Olivo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFormCard(
                      children: [
                        _buildField(
                          controller: _addressController,
                          label: 'INDIRIZZO',
                          hint: 'Via delle Vigne, 15',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                controller: _cityController,
                                label: 'COMUNE',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: _provController,
                                label: 'PROVINCIA',
                                hint: 'es. SI',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _latController,
                                label: 'LATITUDINE',
                                hint: 'es. 43.769',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: _lngController,
                                label: 'LONGITUDINE',
                                hint: 'es. 11.255',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isGeocoding ? null : _geocodeAddress,
                            icon: _isGeocoding 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)))
                                : const Icon(Icons.location_on_rounded, size: 18),
                            label: Text(_isGeocoding ? 'RICERCA IN CORSO...' : 'LOCALIZZA INDIRIZZO'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(24),
                      child: _buildFormCard(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF059669)),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DATA ISPEZIONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
                                  Text(
                                    DateFormat('EEEE dd MMMM yyyy', 'it_IT').format(_scheduledDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVisit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('CREA E INIZIA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
