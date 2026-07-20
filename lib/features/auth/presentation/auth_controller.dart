import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:dio/dio.dart';
import 'dart:convert';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthState.unauthenticated()) {
    _init();
  }

  final FlutterSecureStorage _storage;
  final _supabase = Supabase.instance.client;

  void _init() {
    // Sincronizza lo stato iniziale
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _updateState(session);
    }

    // Ascolta i cambiamenti della sessione (refresh token, logout, login)
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _updateState(session);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  void _updateState(Session session) {
    final user = session.user;
    final isActuallyAdmin =
        user.email == 'flaviopipitone@certbios.it' ||
        user.email == 'f.pipitone@certbios.it' ||
        user.email == 'admin@certbios.it' ||
        (user.userMetadata?['role'] == 'admin');

    state = AuthState.authenticated(
      user.email ?? 'Utente',
      userId: user.id,
      fullName: user.userMetadata?['full_name'],
      inspectorCode: user.userMetadata?['inspector_code'],
      isAdmin: isActuallyAdmin,
    );
  }

  static const _kRemember = 'remember_me';
  static const _kUsername = 'saved_username';
  static const _kPassword = 'saved_password';

  Future<void> login({
    required String username,
    required String password,
    required bool rememberMe,
    required bool isAdmin,
    bool useBiosfera = false,
  }) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      throw Exception('Inserisci email e password.');
    }

    if (useBiosfera) {
      try {
        final dio = Dio();
        final response = await dio.post(
          'https://biosfera2.certbios.it/api-jwt/auth/login',
          data: {'email': u, 'password': p},
          options: Options(
            contentType: 'application/json',
            validateStatus: (status) => true,
          ),
        );

        if (response.statusCode == 200) {
          final rawData = response.data;
          final data = rawData is String ? jsonDecode(rawData) : rawData;
          final token = data['access_token'];
          final userMap = data['user'] as Map<String, dynamic>;
          final metadata = userMap['user_metadata'] as Map<String, dynamic>?;

          // Salvataggio preferenze locale
          await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');
          if (rememberMe) {
            await _storage.write(key: _kUsername, value: u);
            await _storage.write(key: _kPassword, value: p);
          } else {
            await _storage.delete(key: _kUsername);
            await _storage.delete(key: _kPassword);
          }
          await _storage.write(key: 'biosfera_jwt_token', value: token);

          state = AuthState.authenticated(
            userMap['email'] ?? u,
            userId: userMap['id']?.toString(),
            fullName: metadata?['full_name'],
            inspectorCode: metadata?['inspector_code'],
            isAdmin: false,
          );
        } else {
          final rawData = response.data;
          var data = rawData;
          if (rawData is String) {
            try {
              data = jsonDecode(rawData);
            } catch (_) {
              if (response.statusCode == 500) {
                throw Exception(
                  'Errore 500: Il server Biosfera è in crash (Internal Server Error).',
                );
              }
              // se non è json, manteniamo la stringa originale e vediamo
            }
          }
          final errorMsg = (data is Map)
              ? data['error'] ?? 'Errore di autenticazione Biosfera'
              : 'Errore del server Biosfera: ${response.statusCode}';
          String translatedError = errorMsg.toString();
          final errLower = translatedError.toLowerCase();

          if (errLower.contains('invalid credentials') ||
              errLower.contains('invalid')) {
            translatedError = 'Credenziali non valide.';
          } else if (errLower.contains('required')) {
            translatedError = 'Email e password sono obbligatorie.';
          }

          throw Exception(translatedError);
        }
      } on DioException catch (e) {
        String message = 'Errore di rete con Biosfera.';
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message =
                'La connessione con Biosfera è andata in timeout. Riprova.';
            break;
          case DioExceptionType.badResponse:
            message =
                'Il server Biosfera ha restituito una risposta non valida.';
            break;
          case DioExceptionType.cancel:
            message = 'Richiesta a Biosfera annullata.';
            break;
          case DioExceptionType.connectionError:
            message =
                'Impossibile connettersi a Biosfera. Verifica la tua connessione internet.';
            break;
          default:
            message =
                'Errore di connessione a Biosfera: ${e.message ?? 'Errore sconosciuto'}';
        }
        throw Exception(message);
      } on Exception {
        rethrow;
      } catch (e) {
        throw Exception('Errore imprevisto durante l\'accesso a Biosfera: $e');
      }
    } else {
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
            user.email == 'f.pipitone@certbios.it' ||
            user.email == 'admin@certbios.it' ||
            (user.userMetadata?['role'] == 'admin');

        if (isAdmin && !isActuallyAdmin) {
          await _supabase.auth.signOut();
          throw Exception('Non hai i permessi di Amministratore.');
        }

        // Salvataggio preferenze locale
        await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');

        if (rememberMe) {
          await _storage.write(key: _kUsername, value: u);
          await _storage.write(key: _kPassword, value: p);
        } else {
          await _storage.delete(key: _kUsername);
          await _storage.delete(key: _kPassword);
        }

        state = AuthState.authenticated(
          user.email ?? u,
          userId: user.id,
          fullName: user.userMetadata?['full_name'],
          inspectorCode: user.userMetadata?['inspector_code'],
          isAdmin: isActuallyAdmin,
          isFirstLogin: p == 'password',
        );
      } on AuthException catch (e) {
        String msg = e.message;
        if (msg.toLowerCase().contains('invalid login credentials')) {
          msg = 'Email o password non valide.';
        }
        throw Exception(msg);
      } catch (e) {
        throw Exception('Errore di connessione al server.');
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String inspectorCode,
    required String phone,
    required String region,
  }) async {
    final fullName = '$firstName $lastName'.trim();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'first_name': firstName,
          'last_name': lastName,
          'inspector_code': inspectorCode,
          'phone': phone,
          'region': region,
          'role': 'inspector', // Default role
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Errore durante la registrazione.');
      }

      // Aggiungi all'anagrafica pubblica su Supabase per visibilità admin
      try {
        await _supabase.from('inspectors').upsert({
          'id': user.id,
          'full_name': fullName,
          'first_name': firstName,
          'last_name': lastName,
          'inspector_code': inspectorCode,
          'email': email,
          'phone': phone,
          'region': region,
          'is_active': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Errore configurazione profilo (tentativo fallback): $e');
        if (e.toString().contains('column') &&
            e.toString().contains('does not exist')) {
          // Fallback se le colonne nuove non esistono ancora sul server
          await _supabase.from('inspectors').upsert({
            'id': user.id,
            'full_name': fullName,
            'email': email,
            'phone': phone,
            'region': region,
            'is_active': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          rethrow;
        }
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      // Log per debugging
      debugPrint('Errore registrazione Supabase: $e');

      // Se il messaggio contiene "column ... does not exist", è un problema di schema su Supabase
      if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
        throw Exception(
          'Errore di schema su Supabase: assicurati di aver aggiunto le colonne first_name, last_name e inspector_code alla tabella inspectors.\n\nDettaglio: $e',
        );
      }

      throw Exception('Errore durante la creazione dell\'account: $e');
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

      return {'remember': remember, 'username': username, 'password': password};
    } catch (e) {
      return {'remember': null, 'username': null, 'password': null};
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
