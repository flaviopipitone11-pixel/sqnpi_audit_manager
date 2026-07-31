import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../domain/auth_state.dart';

import '../../../core/storage/app_storage.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState.unauthenticated()) {
    _init();
  }

  void _init() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await AppStorage.read('biosfera_jwt_token');
      final userDataStr = await AppStorage.read('biosfera_user_data');
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

  Future<void> _safeWrite({required String key, required String? value}) async {
    await AppStorage.write(key, value);
  }

  Future<void> _safeDelete({required String key}) async {
    await AppStorage.delete(key);
  }

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

    // Account Admin di test rapido
    if ((u == 'admin' || u == 'admin@certbios.it') && p == 'test') {
      await _safeWrite(key: _kRemember, value: rememberMe ? '1' : '0');
      if (rememberMe) {
        await _safeWrite(key: _kUsername, value: u);
        await _safeWrite(key: _kPassword, value: p);
      } else {
        await _safeDelete(key: _kUsername);
        await _safeDelete(key: _kPassword);
      }
      await _safeWrite(key: 'biosfera_auth_username', value: 'ced@certbios.it');
      await _safeWrite(key: 'biosfera_auth_password', value: p);

      try {
        final dio = Dio();
        final res = await dio.post(
          'https://biosfera2.certbios.it/api-jwt/auth/login',
          data: {'email': 'ced@certbios.it', 'password': p},
          options: Options(
            contentType: 'application/json',
            validateStatus: (status) => true,
          ),
        );
        if (res.statusCode == 200) {
          final data = res.data is String ? jsonDecode(res.data) : res.data;
          final token = data['access_token'];
          if (token != null) {
            await _safeWrite(
              key: 'biosfera_jwt_token',
              value: token.toString(),
            );
          }
        }
      } catch (_) {}

      final authState = AuthState.authenticated(
        'admin',
        userId: 'admin-local-001',
        fullName: 'Amministratore BIOS',
        inspectorCode: 'ADMIN',
        isAdmin: true,
      );
      state = authState;
      return;
    }

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
        final userIsAdminRole =
            email == 'flaviopipitone@certbios.it' ||
            email == 'f.pipitone@certbios.it' ||
            email == 'admin@certbios.it' ||
            email == 'ced@certbios.it' ||
            u == 'flaviopipitone' ||
            u == 'f.pipitone' ||
            u == 'admin' ||
            u == 'ced' ||
            (metadata?['role'] == 'admin');

        if (isAdmin && !userIsAdminRole) {
          throw Exception('Non hai i permessi di Amministratore.');
        }

        // Si entra come Admin solo se è stato selezionato il tab Admin nella schermata di login
        final finalIsAdmin = isAdmin && userIsAdminRole;

        // Salvataggio preferenze locale
        await _safeWrite(key: _kRemember, value: rememberMe ? '1' : '0');
        if (rememberMe) {
          await _safeWrite(key: _kUsername, value: u);
          await _safeWrite(key: _kPassword, value: p);
        } else {
          await _safeDelete(key: _kUsername);
          await _safeDelete(key: _kPassword);
        }
        await _safeWrite(key: 'biosfera_auth_username', value: u);
        await _safeWrite(key: 'biosfera_auth_password', value: p);
        await _safeWrite(key: 'biosfera_jwt_token', value: token?.toString());

        final authState = AuthState.authenticated(
          u,
          userId: userMap['id']?.toString(),
          fullName: metadata?['full_name'],
          inspectorCode: metadata?['inspector_code'],
          isAdmin: finalIsAdmin,
        );

        // Salviamo i dati utente per il ripristino della sessione
        final userDataJson = jsonEncode({
          'username': authState.username,
          'userId': authState.userId,
          'fullName': authState.fullName,
          'inspectorCode': authState.inspectorCode,
          'isAdmin': authState.isAdmin,
        });
        await _safeWrite(key: 'biosfera_user_data', value: userDataJson);

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
    final remember = await AppStorage.read(_kRemember);

    if (remember != '1') {
      await _safeDelete(key: _kUsername);
      await _safeDelete(key: _kPassword);
      await _safeDelete(key: 'biosfera_auth_username');
      await _safeDelete(key: 'biosfera_auth_password');
    }
    await _safeDelete(key: 'biosfera_jwt_token');
    await _safeDelete(key: 'biosfera_user_data');
    state = const AuthState.unauthenticated();
  }

  Future<Map<String, String?>> readSaved() async {
    final remember = await AppStorage.read(_kRemember);

    var username = await AppStorage.read(_kUsername);
    if (username == null || username.isEmpty) {
      username = await AppStorage.read('biosfera_auth_username');
    }

    var password = await AppStorage.read(_kPassword);
    if (password == null || password.isEmpty) {
      password = await AppStorage.read('biosfera_auth_password');
    }

    final isRemembered = remember == '1';

    return {
      'remember': isRemembered ? '1' : '0',
      'username': isRemembered ? username : '',
      'password': isRemembered ? password : '',
    };
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
