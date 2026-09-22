import '../../../core/domain/audit_standard.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? username;
  final String? fullName;
  final String? inspectorCode;
  final bool isAdmin;
  final bool isFirstLogin;
  final List<AuditStandard> enabledStandards;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.username,
    this.fullName,
    this.inspectorCode,
    this.isAdmin = false,
    this.isFirstLogin = false,
    this.enabledStandards = const [AuditStandard.sqnpi],
  });

  const AuthState.unauthenticated()
    : this(
        isAuthenticated: false,
        isAdmin: false,
        isFirstLogin: false,
        enabledStandards: const [],
      );

  const AuthState.authenticated(
    String username, {
    String? userId,
    String? fullName,
    String? inspectorCode,
    bool isAdmin = false,
    bool isFirstLogin = false,
    List<AuditStandard> enabledStandards = const [
      AuditStandard.sqnpi,
      AuditStandard.bio,
    ],
  }) : this(
         isAuthenticated: true,
         userId: userId,
         username: username,
         fullName: fullName,
         inspectorCode: inspectorCode,
         isAdmin: isAdmin,
         isFirstLogin: isFirstLogin,
         enabledStandards: enabledStandards,
       );

  bool get canAccessSqnpi => enabledStandards.contains(AuditStandard.sqnpi);
  bool get canAccessBio => enabledStandards.contains(AuditStandard.bio);
  bool get isMultiStandard => enabledStandards.length > 1;
  AuditStandard? get singleStandard =>
      enabledStandards.length == 1 ? enabledStandards.first : null;
}
