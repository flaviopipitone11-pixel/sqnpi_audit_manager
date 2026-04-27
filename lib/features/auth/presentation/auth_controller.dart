import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthState.unauthenticated()) {
    // Verifica se l'utente è già loggato all'avvio
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      final isAdmin =
          user.email == 'flaviopipitone@certbios.it' ||
          (user.userMetadata?['role'] == 'admin');
      state = AuthState.authenticated(user.email ?? 'Utente', isAdmin: isAdmin);
    }
  }

  final FlutterSecureStorage _storage;
  final _supabase = Supabase.instance.client;

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
      throw Exception('Inserisci email e password.');
    }

    try {
      // Login reale con Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: u,
        password: p,
      );

      final user = response.user;
      if (user == null) throw Exception('Errore durante l\'accesso.');

      // Controllo Admin
      final isActuallyAdmin =
          user.email == 'flaviopipitone@certbios.it' ||
          (user.userMetadata?['role'] == 'admin');

      if (isAdmin && !isActuallyAdmin) {
        await _supabase.auth.signOut();
        throw Exception('Non hai i permessi di Amministratore.');
      }

      // Salvataggio preferenze locale
      await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');
      await _storage.write(key: _kOffline, value: offlineMode ? '1' : '0');

      if (rememberMe) {
        await _storage.write(key: _kUsername, value: u);
        await _storage.write(key: _kPassword, value: p);
      } else {
        await _storage.delete(key: _kUsername);
        await _storage.delete(key: _kPassword);
      }

      state = AuthState.authenticated(
        user.email ?? u,
        isAdmin: isActuallyAdmin,
        isFirstLogin: p == 'password',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Errore di connessione al server.');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'inspector', // Default role
        },
      );

      if (response.user == null) {
        throw Exception('Errore durante la registrazione.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Errore durante la creazione dell\'account.');
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    state = const AuthState.unauthenticated();
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
    final storage = const FlutterSecureStorage(
      mOptions: MacOsOptions(accessibility: KeychainAccessibility.unlocked),
    );
    return AuthController(storage);
  },
);
