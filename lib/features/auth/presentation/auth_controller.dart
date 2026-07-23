import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._storage) : super(const AuthState.unauthenticated()) {
    _init();
  }

  final FlutterSecureStorage _storage;

  void _init() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: 'biosfera_jwt_token');
      final userDataStr = await _storage.read(key: 'biosfera_user_data');
      if (token != null &&
          token.isNotEmpty &&
          userDataStr != null &&
          userDataStr.isNotEmpty) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        state = AuthState.authenticated(
          userData['username'] ?? '',
          userId: userData['userId'],
          fullName: userData['fullName'],
          inspectorCode: userData['inspectorCode'],
          isAdmin: userData['isAdmin'] ?? false,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      debugPrint('Errore nel ripristino della sessione Biosfera: $e');
      state = const AuthState.unauthenticated();
    }
  }

  static const _kRemember = 'remember_me';
  static const _kUsername = 'saved_username';
  static const _kPassword = 'saved_password';

  Future<void> login({
    required String username,
    required String password,
    required bool rememberMe,
    required bool isAdmin,
  }) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      throw Exception('Inserisci username e password.');
    }

    final emailPayload = u.contains('@') ? u : '$u@certbios.it';

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://biosfera2.certbios.it/api-jwt/auth/login',
        data: {'email': emailPayload, 'password': p},
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

        final email = userMap['email']?.toString() ?? emailPayload;
        final isActuallyAdmin =
            email == 'flaviopipitone@certbios.it' ||
            email == 'f.pipitone@certbios.it' ||
            email == 'admin@certbios.it' ||
            u == 'flaviopipitone' ||
            u == 'f.pipitone' ||
            u == 'admin' ||
            (metadata?['role'] == 'admin');

        if (isAdmin && !isActuallyAdmin) {
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
        await _storage.write(key: 'biosfera_jwt_token', value: token);

        final authState = AuthState.authenticated(
          u,
          userId: userMap['id']?.toString(),
          fullName: metadata?['full_name'],
          inspectorCode: metadata?['inspector_code'],
          isAdmin: isActuallyAdmin,
        );

        // Salviamo i dati utente per il ripristino della sessione
        final userDataJson = jsonEncode({
          'username': authState.username,
          'userId': authState.userId,
          'fullName': authState.fullName,
          'inspectorCode': authState.inspectorCode,
          'isAdmin': authState.isAdmin,
        });
        await _storage.write(key: 'biosfera_user_data', value: userDataJson);

        state = authState;
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
          translatedError = 'Username e password sono obbligatori.';
        }

        throw Exception(translatedError);
      }
    } on DioException catch (e) {
      String message = 'Errore di rete con Biosfera.';
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'La connessione con Biosfera è andata in timeout. Riprova.';
          break;
        case DioExceptionType.badResponse:
          message = 'Il server Biosfera ha restituito una risposta non valida.';
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
  }

  Future<void> logout() async {
    await _storage.delete(key: 'biosfera_jwt_token');
    await _storage.delete(key: 'biosfera_user_data');
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
