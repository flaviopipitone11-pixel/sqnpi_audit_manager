import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthState.unauthenticated());

  final FlutterSecureStorage _storage;

  static const _kRemember = 'remember_me';
  static const _kUsername = 'saved_username';
  static const _kPassword = 'saved_password';
  static const _kOffline = 'offline_mode';

  Future<void> login({
    required String username,
    required String password,
    required bool rememberMe,
    required bool offlineMode,
    required bool isAdmin,
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      throw Exception('Inserisci username e password.');
    }

    // MOCK: qui in futuro chiameremo l'API del tuo ODC e otterremo un token.

    // Salvataggio preferenze/credenziali con "Soft Persistence"
    // Se il Keychain di macOS dà errore (es. -34018), logghiamo ma proseguiamo il login.
    try {
      await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');
      await _storage.write(key: _kOffline, value: offlineMode ? '1' : '0');

      if (rememberMe) {
        await _storage.write(key: _kUsername, value: u);
        await _storage.write(key: _kPassword, value: p);
      } else {
        await _storage.delete(key: _kUsername);
        await _storage.delete(key: _kPassword);
      }
    } catch (e) {
      debugPrint('----- [STORAGE ERROR] -----');
      debugPrint('Errore durante il salvataggio credenziali: $e');
      debugPrint('Il login proseguirà comunque senza persistenza.');
      debugPrint('---------------------------');
    }

    // Aggiorniamo lo stato SOLO ALLA FINE per evitare "race conditions" con GoRouter
    state = AuthState.authenticated(u, isAdmin: isAdmin);
  }

  Future<void> logout() async {
    state = const AuthState.unauthenticated();
    // Nota: NON cancelliamo le credenziali al logout,
    // perché l'utente potrebbe voler rientrare velocemente.
    // Le cancella togliendo "Ricordami".
  }

  Future<Map<String, String?>> readSaved() async {
    try {
      final remember = await _storage.read(key: _kRemember);
      final username = await _storage.read(key: _kUsername);
      final password = await _storage.read(key: _kPassword);
      final offline = await _storage.read(key: _kOffline);

      return {
        'remember': remember,
        'username': username,
        'password': password,
        'offline': offline,
      };
    } catch (e) {
      debugPrint('----- [READ STORAGE ERROR] -----');
      debugPrint('Errore durante la lettura credenziali salvate: $e');
      debugPrint('--------------------------------');
      return {
        'remember': null,
        'username': null,
        'password': null,
        'offline': null,
      };
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    // Nota: su macOS usiamo opzioni standard ma senza richiedere Keychain speciale
    // se non necessario. L'errore -34018 è comune in dev senza signing.
    final storage = FlutterSecureStorage(
      mOptions: const MacOsOptions(
        accessibility: KeychainAccessibility.unlocked,
      ),
    );
    return AuthController(storage);
  },
);
