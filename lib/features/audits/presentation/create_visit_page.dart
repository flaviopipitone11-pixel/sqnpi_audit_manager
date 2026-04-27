import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/services/geocoding_service.dart';

class CreateVisitPage extends ConsumerStatefulWidget {
  const CreateVisitPage({super.key});

  @override
  ConsumerState<CreateVisitPage> createState() => _CreateVisitPageState();
}

class _CreateVisitPageState extends ConsumerState<CreateVisitPage> {
  final _formKey = GlobalKey<FormState>();

  // Dati Azienda
  final _companyController = TextEditingController();
  final _pivaController = TextEditingController();
  final _cuaaController = TextEditingController();

  // Sede Legale
  final _legalAddressController = TextEditingController();
  final _legalCityController = TextEditingController();
  final _legalProvController = TextEditingController();
  final _legalCapController = TextEditingController();

  // Sede Operativa
  final _opAddressController = TextEditingController();
  final _opCityController = TextEditingController();
  final _opProvController = TextEditingController();
  final _opCapController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // SQNPI Details
  final _sqnpiNumberController = TextEditingController();
  final _sqnpiProtocolController = TextEditingController();
  DateTime? _sqnpiDate;

  DateTimeRange _scheduledRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  bool _isSaving = false;
  bool _isGeocoding = false;

  @override
  void dispose() {
    _companyController.dispose();
    _pivaController.dispose();
    _cuaaController.dispose();
    _legalAddressController.dispose();
    _legalCityController.dispose();
    _legalProvController.dispose();
    _legalCapController.dispose();
    _opAddressController.dispose();
    _opCityController.dispose();
    _opProvController.dispose();
    _opCapController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _sqnpiNumberController.dispose();
    _sqnpiProtocolController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _scheduledRange,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledRange = picked);
    }
  }

  Future<void> _selectSqnpiDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sqnpiDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _sqnpiDate = picked);
    }
  }

  Future<void> _geocodeOperationalAddress() async {
    final address = _opAddressController.text.trim();
    final city = _opCityController.text.trim();
    final prov = _opProvController.text.trim();

    if (address.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci Indirizzo e Comune della sede operativa.'),
        ),
      );
      return;
    }

    setState(() => _isGeocoding = true);

    try {
      final geocodingService = ref.read(geocodingServiceProvider);
      final coords = await geocodingService.getCoordinates(
        address: address,
        city: city,
        province: prov,
      );

      if (coords != null) {
        setState(() {
          _latController.text = coords.lat.toStringAsFixed(6);
          _lngController.text = coords.lon.toStringAsFixed(6);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coordinate sede operativa calcolate!'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossibile trovare le coordinate per questo indirizzo.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore geocodifica: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final auth = ref.read(authControllerProvider);

      final visitId = 'V-USR-${DateTime.now().millisecondsSinceEpoch}';
      final email = auth.username ?? '';

      await db.transaction(() async {
        // 1. Inserimento Visita
        await db.upsertVisit(
          id: visitId,
          scheduledAt: _scheduledRange.start,
          scheduledUntil: _scheduledRange.end,
          companyName: _companyController.text,
          crop: 'Varie', // Valore di default interno
          status: VisitStatus.daIniziare,
          inspectorEmail: email.toLowerCase(),
          inspectorName: email,
        );

        // 2. Dettagli Azienda (Legale + Operativa)
        await db.upsertCompany(
          visitId: visitId,
          ragioneSociale: _companyController.text,
          partitaIva: _pivaController.text,
          cuaa: _cuaaController.text,
          indirizzo: _legalAddressController.text,
          comune: _legalCityController.text,
          provincia: _legalProvController.text,
          cap: _legalCapController.text,
          sedeOperativaIndirizzo: _opAddressController.text,
          sedeOperativaComune: _opCityController.text,
          sedeOperativaProvincia: _opProvController.text,
          sedeOperativaCap: _opCapController.text,
          latitude: double.tryParse(_latController.text.replaceAll(',', '.')),
          longitude: double.tryParse(_lngController.text.replaceAll(',', '.')),
          submissionNumber: _sqnpiNumberController.text,
          sqnpiProtocol: _sqnpiProtocolController.text,
          sqnpiSubmissionDate: _sqnpiDate,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita pianificata con successo!')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final isMultiDay =
        _scheduledRange.start.day != _scheduledRange.end.day ||
        _scheduledRange.start.month != _scheduledRange.end.month;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Pianifica Ispezione',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEZIONE: ANAGRAFICA
              _buildSectionHeader(
                'Anagrafica Aziendale',
                Icons.business_rounded,
              ),
              _buildCard(
                children: [
                  _buildField(
                    _companyController,
                    'Ragione Sociale',
                    Icons.storefront_rounded,
                    true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          _pivaController,
                          'Partita IVA',
                          Icons.pin_rounded,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          _cuaaController,
                          'CUAA',
                          Icons.badge_rounded,
                          true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SEZIONE: SEDE LEGALE
              _buildSectionHeader('Sede Legale', Icons.gavel_rounded),
              _buildCard(
                children: [
                  _buildField(
                    _legalAddressController,
                    'Indirizzo Sede Legale',
                    Icons.home_work_rounded,
                    true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          _legalCityController,
                          'Comune',
                          null,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildField(
                          _legalCapController,
                          'CAP',
                          null,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildField(
                          _legalProvController,
                          'Prov',
                          null,
                          true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SEZIONE: SEDE OPERATIVA
              _buildSectionHeader('Sede Operativa', Icons.location_on_rounded),
              _buildCard(
                children: [
                  _buildField(
                    _opAddressController,
                    'Indirizzo Sede Operativa',
                    Icons.map_rounded,
                    true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          _opCityController,
                          'Comune',
                          null,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildField(
                          _opCapController,
                          'CAP',
                          null,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildField(
                          _opProvController,
                          'Prov',
                          null,
                          true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadOnlyField(
                                _latController,
                                'Latitudine',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReadOnlyField(
                                _lngController,
                                'Longitudine',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _isGeocoding
                                ? null
                                : _geocodeOperationalAddress,
                            icon: _isGeocoding
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed_rounded, size: 18),
                            label: Text(
                              _isGeocoding
                                  ? 'CALCOLO IN CORSO...'
                                  : 'CALCOLA COORDINATE AUTOMATICAMENTE',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // SEZIONE: SQNPI
              _buildSectionHeader(
                'Dati Domanda SQNPI',
                Icons.description_rounded,
              ),
              _buildCard(
                children: [
                  _buildField(
                    _sqnpiNumberController,
                    'Numero Domanda SQNPI',
                    Icons.tag_rounded,
                    false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          _sqnpiProtocolController,
                          'Protocollo',
                          Icons.article_rounded,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selectSqnpiDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Data Domanda',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        _sqnpiDate == null
                                            ? 'Seleziona'
                                            : DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(_sqnpiDate!),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SEZIONE: PIANIFICAZIONE
              _buildSectionHeader(
                'Pianificazione Temporale',
                Icons.calendar_month_rounded,
              ),
              _buildCard(
                children: [
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMultiDay
                                      ? 'Periodo Ispezione'
                                      : 'Data Ispezione',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isMultiDay
                                      ? '${DateFormat('dd MMM').format(_scheduledRange.start)} - ${DateFormat('dd MMM yyyy').format(_scheduledRange.end)}'
                                      : DateFormat(
                                          'dd MMMM yyyy',
                                          'it_IT',
                                        ).format(_scheduledRange.start),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: Color(0xFF059669),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveVisit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF1E293B).withValues(alpha: 0.4),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 12),
                            Text(
                              'CONFERMA E REGISTRA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
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

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData? icon,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: required
          ? (v) => v!.isEmpty ? 'Campo obbligatorio' : null
          : null,
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          controller.text.isEmpty ? '---' : controller.text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
