import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../../core/utils/package_info_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty) {
      setState(() => _error = 'Inserisci la nuova password.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'La password deve contenere almeno 6 caratteri.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _error = 'Le password non coincidono.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).changePassword(newPass);
      setState(() {
        _success = 'Password aggiornata con successo!';
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final primaryColor = const Color(0xFF2D6A4F);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text('Impostazioni Profilo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.username ?? 'Utente',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          auth.isAdmin
                              ? 'Amministratore'
                              : 'Ispettore Biosfera',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sicurezza Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cambia Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nuova Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  if (_success != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _success!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _loading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Aggiorna Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Versione ${packageInfo.version}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
