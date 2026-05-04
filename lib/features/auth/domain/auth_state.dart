class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? username;
  final String? fullName;
  final bool isAdmin;
  final bool isFirstLogin;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.username,
    this.fullName,
    this.isAdmin = false,
    this.isFirstLogin = false,
  });

  const AuthState.unauthenticated()
    : this(isAuthenticated: false, isAdmin: false, isFirstLogin: false);

  const AuthState.authenticated(
    String username, {
    String? userId,
    String? fullName,
    bool isAdmin = false,
    bool isFirstLogin = false,
  }) : this(
         isAuthenticated: true,
         userId: userId,
         username: username,
         fullName: fullName,
         isAdmin: isAdmin,
         isFirstLogin: isFirstLogin,
       );
}
